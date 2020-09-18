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
Usage: $0 [OPTIONS]

    OPTIONS:

    Examples:

_EOF_
}


function main() {
    echo "Restoring complete database from local disk..."

}
