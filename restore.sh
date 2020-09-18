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

declare -r _PROGNAME=$(basename $0)
declare -r _PROGDIR=$(dirname $0)
declare -r _WORKING_DIR=$(pwd)

function main() {

}
