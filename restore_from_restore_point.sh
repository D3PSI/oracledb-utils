#!/bin/bash
#-------------------------------------------------------------------------------
#- DATABASE
#-------------------------------------------------------------------------------
#- File         : restore_from_restore_point.sh
#- Description  : Restores a database from a restore point
#-------------------------------------------------------------------------------
#- Version      : 1.0
#-------------------------------------------------------------------------------

set -eo pipefail

if [[ -f $HOME/.bash_profile ]]; then
    . $HOME/.bash_profile
fi


function usage() {
    cat << _EOF_
Usage: $0 -s SID -d HOST -t TENANT -n NAME [OPTIONS]

    OPTIONS:

        -s, --service-id    :           The Oracle-SID to run the script against (Mandatory)
        -d, --db-host       :           The database host to run the script against (Defaults to localhost if not specified)
        -n, --name          :           The name of the restore point (Mandatory)

    Examples:

        $0 -s stgholp -n RESTORE_POINT_1
        $0 --service-id stgholp --name RESTORE_POINT_1
        $0 -s stgholp -n RESTORE_POINT_1 -d ordstg02.revendex.com

_EOF_
}


function main() {
    echo "Restoring complete database from restore point..."
    export ORACLE_SID=$arg_service_id
    DB_SQLPLUS_START_SESSION="sqlplus / AS SYSDBA"
    DB_SQLPLUS_RESTORE_CMD_1="SHUTDOWN IMMEDIATE;"
    DB_SQLPLUS_RESTORE_CMD_2="STARTUP MOUNT;"
    DB_SQLPLUS_RESTORE_CMD_3="FLASHBACK DATABASE TO RESTORE POINT $arg_name;"
    DB_SQLPLUS_RESTORE_CMD_4="ALTER DATABASE OPEN RESETLOGS;"
    DB_SQLPLUS_RESTORE_CMD_5="DROP RESTORE POINT $arg_name;"
    if [ "$arg_db_host" != "localhost" ]; then
        echo "Database is not hosted on local machine, this functionality has not yet been implemented"
        exit 1
    else
        echo "Running on local machine"
        eval "echo '"$DB_SQLPLUS_RESTORE_CMD_1"' | $DB_SQLPLUS_START_SESSION"
        eval "echo '"$DB_SQLPLUS_RESTORE_CMD_2"' | $DB_SQLPLUS_START_SESSION"
        eval "echo '"$DB_SQLPLUS_RESTORE_CMD_3"' | $DB_SQLPLUS_START_SESSION"
        eval "echo '"$DB_SQLPLUS_RESTORE_CMD_4"' | $DB_SQLPLUS_START_SESSION"
        eval "echo '"$DB_SQLPLUS_RESTORE_CMD_5"' | $DB_SQLPLUS_START_SESSION"
    fi
}


for arg in "$@"; do
    shift
    case "$arg" in
        "--service-id") set -- "$@" "-s";;
        "--db-host") set -- "$@" "-d";;
        "--name") set -- "$@" "-n";;
        *) set -- "$@" "$arg"
    esac
done

OPTIND=1
while getopts "hs:d:n:" opt
do
    case "$opt" in
        "h") usage; exit 0;;
        "s") arg_service_id=${OPTARG};;
        "d") arg_db_host=${OPTARG};;
        "n") arg_name=${OPTARG};;
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

if [[ -z "${arg_name}" ]]; then
    echo "No restore point name specified, exiting..."
    exit 1
fi


main
