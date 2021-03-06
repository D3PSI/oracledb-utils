#! /bin/bash
#-------------------------------------------------------------------------------
#- DATABASE
#-------------------------------------------------------------------------------
#- File         : create_new_database_dump.sh
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

    Examples:

        $0 -s stgholp -t rockbank -o /tmp
        $0 --service-id stgholp --tenant rockbank --out /tmp
        $0 -s stgholp -t rockbank -o /tmp -d ordstg02.revendex.com

_EOF_
}


function main() {
    echo "Dumping complete database to local disk..."
    DATE=$(date +'%Y%m%d')
    OUT_DIR="$arg_out/$DATE"
    DB_DIR="${arg_tenant}_DUMP_${DATE}"
    export ORACLE_SID=$arg_service_id
    DB_SQLPLUS_START_SESSION="sqlplus / AS SYSDBA"
    DB_SQLPLUS_PREPARE_CMD_1="CREATE OR REPLACE DIRECTORY $DB_DIR as '\''$OUT_DIR'\'';"
    DB_SQLPLUS_PREPARE_CMD_2="GRANT READ, WRITE ON DIRECTORY $DB_DIR TO EXP_FULL_DATABASE;"
    DB_DUMP_CMD="expdp $arg_tenant/$arg_tenant directory=$DB_DIR dumpfile=$arg_tenant.dmp logfile=$arg_tenant.log"
    DB_SQLPLUS_CLEANUP_CMD="DROP DIRECTORY $DB_DIR;"
    if [ "$arg_db_host" != "localhost" ]; then
        echo "Database is not hosted on local machine, this functionality has not yet been implemented"
        exit 1
    else
        echo "Running on local machine"
        mkdir -p "$OUT_DIR"
        chown oracle:oinstall "$OUT_DIR"
        eval "echo '"$DB_SQLPLUS_PREPARE_CMD_1"' | $DB_SQLPLUS_START_SESSION"
        eval "echo '"$DB_SQLPLUS_PREPARE_CMD_2"' | $DB_SQLPLUS_START_SESSION"
        eval "$DB_DUMP_CMD"
        eval "echo '"$DB_SQLPLUS_CLEANUP_CMD"' | $DB_SQLPLUS_START_SESSION"
    fi
}

for arg in "$@"; do
    shift
    case "$arg" in
        "--service-id") set -- "$@" "-s";;
        "--db-host") set -- "$@" "-d";;
        "--tenant") set -- "$@" "-t";;
        "--out") set -- "$@" "-o";;
        *) set -- "$@" "$arg"
    esac
done

OPTIND=1
while getopts "hs:d:t:o:" opt
do
    case "$opt" in
        "h") usage; exit 0;;
        "s") arg_service_id=${OPTARG};;
        "d") arg_db_host=${OPTARG};;
        "t") arg_tenant=${OPTARG};;
        "o") arg_out=${OPTARG};;
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
