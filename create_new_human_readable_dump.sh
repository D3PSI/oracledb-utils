#! /bin/bash
#-------------------------------------------------------------------------------
#- DATABASE
#-------------------------------------------------------------------------------
#- File         : create_new_human_readable_dump.sh
#- Description  : Creates a complete database dump
#-------------------------------------------------------------------------------
#- Version      : 1.0
#-------------------------------------------------------------------------------

set -eo pipefail

if [[ -f $HOME/.bash_profile ]]; then
      . $HOME/.bash_profile
fi


function usage() {
    cat << _EOF_
Usage: $0 -s SID -d HOST -t TENANT -o OUT_DIR [OPTIONS]

    OPTIONS:

        -s, --service-id    :           The Oracle-SID to run the script against (Mandatory)
        -d, --db-host       :           The database host to run the script against (Defaults to localhost if not specified)
        -t, --tenant        :           The tenant to run this script against (Mandatory)
        -o, --out           :           The out directory where the dump will be stored (Mandatory)
        -e, --exclude       :           A comma-separated list of tables to exclude (Optional)

    Examples:

        $0 -s stgholp -t rockbank -o /tmp -e AUDIT_LOG,UPDATE_TIME
        $0 --service-id stgholp --tenant rockbank --out /tmp --exclude AUDIT_LOG,UPDATE_TIME
        $0 -s stgholp -t rockbank -o /tmp -d ordstg02.revendex.com -e AUDIT_LOG,UPDATE_TIME

_EOF_
}


function main() {
    echo "Dumping complete database to local disk..."
    DATE=$(date +'%Y%m%d')
    OUT_DIR="$arg_out/$DATE/$arg_tenant"
    export ORACLE_SID=$arg_service_id
    arg_tenant_UPPER=$(echo "$arg_tenant" | tr [a-z] [A-Z])
    DB_SQLPLUS_START_SESSION="sqlplus $arg_tenant/$arg_tenant"
    DB_SQLPLUS_START_SESSION_AS_SYSDBA="sqlplus / AS SYSDBA"
    DB_SQLPLUS_DATA_DUMP_UTIL="@external/data_dump/data_dump.sql"
    DB_SQLPLUS_CREATE_DIR="create or replace directory temp_dir_$DATE as '\''$OUT_DIR'\'';"
    DB_SQLPLUS_DROP_DIR="drop directory temp_dir_$DATE;"
    if [ "$arg_db_host" != "localhost" ]; then
        echo "Database is not hosted on local machine, this functionality has not yet been implemented"
        exit 1
    else
        echo "Running on local machine"
        mkdir -p "$OUT_DIR"
        chown oracle:oinstall "$OUT_DIR"
        eval "$DB_SQLPLUS_START_SESSION_AS_SYSDBA $DB_SQLPLUS_DATA_DUMP_UTIL"
        eval "echo '"$DB_SQLPLUS_CREATE_DIR"' | $DB_SQLPLUS_START_SESSION_AS_SYSDBA"
        eval "$DB_SQLPLUS_START_SESSION <<begin
  for tables in
  (
    select
      table_name || '.csv' file_name,
      'select * from "' || owner || '"."' || table_name || '"' v_sql
      from all_tables
      where owner = '$arg_tenant_UPPER'
      order by table_name
  ) loop
    data_dump
    (
      query_in        => tables.v_sql,
      file_in         => tables.file_name,
      directory_in    => 'TEMP_DIR_$DATE',
      delimiter_in    => ',',
      header_row_in   => true
    );
  end loop;
end;
/"
        eval "echo '"$DB_SQLPLUS_DROP_DIR"' | $DB_SQLPLUS_START_SESSION_AS_SYSDBA"
    fi
}

for arg in "$@"; do
    shift
    case "$arg" in
        "--service-id") set -- "$@" "-s";;
        "--db-host") set -- "$@" "-d";;
        "--tenant") set -- "$@" "-t";;
        "--out") set -- "$@" "-o";;
        "--exclude") set -- "$@" "-e";;
        *) set -- "$@" "$arg"
    esac
done

OPTIND=1
while getopts "hs:d:t:o:e:" opt
do
    case "$opt" in
        "h") usage; exit 0;;
        "s") arg_service_id=${OPTARG};;
        "d") arg_db_host=${OPTARG};;
        "t") arg_tenant=${OPTARG};;
        "o") arg_out=${OPTARG};;
        "e") arg_exclude=${OPTARG};;
        "?") usage >&2; exit 1
    esac
done

shift $(($OPTIND - 1))

if [[ -z "${arg_service_id}" ]]; then
    echo "No service-id specified, exiting..."
    exit 1
fi

if [[ -z "${arg_db_host}" ]]; then
    echo "No db-host specified, defaulting to 'localhost'..."
    arg_db_host="localhost"
fi

if [[ -z "${arg_tenant}" ]]; then
    echo "No tenant specified, exiting..."
    exit 1
fi

if [[ -z "${arg_out}" ]]; then
    echo "No output directory specified, exiting..."
    exit 1
fi


main
