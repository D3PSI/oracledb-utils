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
    DB_SQLPLUS_START_SESSION="sqlplus $arg_tenant/$arg_tenant"
    DB_SQLPLUS_GENERATE_PROCEDURE="@generate_csv_export_procedure.sql"
    DB_SQLPLUS_DUMP_CMD="@create_csv_per_table.sql"
    if [ "$arg_db_host" != "localhost" ]; then
        echo "Database is not hosted on local machine, this functionality has not yet been implemented"
        exit 1
    else
        echo "Running on local machine"
        mkdir -p "$OUT_DIR"
        chown oracle:oinstall "$OUT_DIR"
        eval "$DB_SQLPLUS_START_SESSION $DB_SQLPLUS_GENERATE_PROCEDURE"
        eval "$DB_SQLPLUS_START_SESSION $DB_SQLPLUS_DUMP_CMD"
        mv *.csv "$OUT_DIR"
        rm -rf create_csv_per_table.sql
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
