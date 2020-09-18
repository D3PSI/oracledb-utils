#!/bin/bash
#-------------------------------------------------------------------------------
#- DATABASE
#-------------------------------------------------------------------------------
#- File         : restore.sh
#- Description  : Restores a database from a dump
#-------------------------------------------------------------------------------
#- Version      : 1.0
#-------------------------------------------------------------------------------

set -eo pipefail

if [[ -f $HOME/.bash_profile ]]; then
    . $HOME/.bash_profile
fi


function usage() {
    cat << _EOF_
Usage: $0 -s SID -d HOST -u USER -p PASS -t TARGET_DIR [OPTIONS]

    OPTIONS:

        -s, --service-id    :           The Oracle-SID to run the script against (Mandatory)
        -d, --db-host       :           The database host to run the script against (Defaults to localhost if not specified)
        -u, --user          :           The oracle user with the necessary rights to perform the export (Mandatory)
        -p, --pass          :           The password of the oracle user (Mandatory)
        -t, --target        :           The target directory where the dump will be stored (Mandatory)

    Examples:

_EOF_
}


function main() {
    echo "Restoring complete database from local disk..."
    DATE=$(date +'%Y%m%d')
    TARGET_DIR="$arg_target/$DATE"
    DB_EXPORT_ORACLE_SID="export ORACLE_SID=$arg_service_id"
    DB_SQLPLUS_START_SESSION="sqlplus $arg_user/$arg_pass"
    DB_SQLPLUS_PREPARE_CMD="CREATE OR REPLACE DIRECTORY DUMP_$DATE as '$arg_target'; GRANT READ, WRITE ON DIRECTORY DUMP_$DATE TO IMP_FULL_DATABASE; EXIT;"
    DB_PREPARE_CMD="$DB_EXPORT_ORACLE_SID; $DB_SQLPLUS_PREPARE_CMD | $DB_SQLPLUS_START_SESSION"
    DB_DUMP_CMD="impdp $arg_user/$arg_pass directory=DUMP_$DATE dumpfile=data.dmp logfile=data.log"
    if [ "$arg_db_host" != "localhost" ]; then
        echo "Database is not hosted on local machine, this functionality has not yet been implemented"
        exit 1
    else
        echo "Running on local machine"
        mkdir -p "$TARGET_DIR"
        chown oracle:oinstall "$TARGET_DIR"
        bash -c "$DB_PREPARE_CMD"
        if [[ $? -ne 0 ]]; then
            echo "An unknown error occurred. Check that the database user has 'IMP_FULL_DATABASE' role. You can give your database user this role by running the following in sqlplus:\n\n\t\tGRANT IMP_FULL_DATABASE TO $arg_user;"
            exit 1
        fi
        bash -c "$DB_DUMP_CMD"
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
        "--user") set -- "$@" "-u";;
        "--pass") set -- "$@" "-p";;
        "--target") set -- "$@" "-t";;
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
        "u") arg_user=${OPTARG};;
        "p") arg_pass=${OPTARG};;
        "t") arg_target=${OPTARG};;
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

if [[ -z "$arg_user" ]]; then
    echo "No user specified, exiting..."
    exit 1
fi

if [[ -z "$arg_pass" ]]; then
    echo "No pass specified, exiting..."
    exit 1
fi

if [[ -z "$arg_target" ]]; then
    echo "No target directory specified, exiting..."
    exit 1
fi


main
