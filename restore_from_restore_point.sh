#!/bin/bash
#-------------------------------------------------------------------------------
#- DATABASE
#-------------------------------------------------------------------------------
#- File         : restore.sh
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
        -t, --tenant        :           The tenant to run this script against (Mandatory)
        -n, --name          :           The name of the restore point (Mandatory)

    Examples:

_EOF_
}


function main() {
    echo "Restoring complete database from local disk..."
    DB_SQLPLUS_START_SESSION="sqlplus $arg_tenant/$arg_tenant"
    DB_PREPARE_CMD="$DB_EXPORT_ORACLE_SID; $DB_SQLPLUS_PREPARE_CMD | $DB_SQLPLUS_START_SESSION"
    DB_RESTORE_CMD="$DB_EXPORT_ORACLE_SID; $DB_SQLPLUS_PREPARE_CMD | $DB_SQLPLUS_START_SESSION"
    if [ "$arg_db_host" != "localhost" ]; then
        echo "Database is not hosted on local machine, this functionality has not yet been implemented"
        exit 1
    else
        echo "Running on local machine"
        bash -c "$DB_PREPARE_CMD"
        if [[ $? -ne 0 ]]; then
            echo "An unknown error occurred."
            exit 1
        fi
        bash -c "$DB_RESTORE_CMD"
        if [[ $? -ne 0 ]]; then
            echo "An unknown error occurred."
            exit 1
        fi
    fi
}


for arg in "$@"; do
    shift
    case "$arg" in
        "--service-id") set -- "$@" "-s";;
        "--db-host") set -- "$@" "-d";;
        "--tenant") set -- "$@" "-t";;
        "--name") set -- "$@" "-n";;
        *) set -- "$arg"
    esac
done


OPTIND=1
while getopts "hs:d:u:p:t:" opt
do
    case "$opt" in
        "h") usage; exit 0;;
        "s") arg_service_id=${OPTARG};;
        "d") arg_db_host=${OPTARG};;
        "t") arg_tenant=${OPTARG};;
        "n") arg_name=${OPTARG};;
        "?") usage >&2; exit 1
    esac
done

shift $(expr $OPTIND - 1)

if [[ -z "$arg_service_id" ]]; then
    echo "No service-id specified, exiting..."
    exit 1
fi

if [[ -z "$arg_db_host" ]]; then
    echo "No db-host specified, defaulting to 'localhost'..."
    arg_db_host="localhost"
fi

if [[ -z "$arg_tenant" ]]; then
    echo "No tenant specified, exiting..."
    exit 1
fi

if [[ -z "$arg_name" ]]; then
    echo "No restore point name specified, exiting..."
    exit 1
fi


main