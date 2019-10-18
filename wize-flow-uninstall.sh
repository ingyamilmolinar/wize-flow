#!/usr/bin/env bash

function usage() {
    echo "wize-flow-uninstall.sh [<custom-directory>] [--force] [--ignore-dependencies]" 1>&2
}

main() {

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Do not catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set +o pipefail

    if [[ "$#" != "0" && "$#" != "1" && "$#" != "2" && "$#" != "3" ]]; then
        usage
        exit 1
    fi

    local custom=false
    local installation_dir="/usr/local/opt/wize-flow"
    local binary_installation_dir="/usr/local/bin"
    if [[ "${1-undefined}" != "undefined" && "$1" != "--force" && "$1" != "--ignore-dependencies" ]]; then
        if [[ ! -d "$1" ]]; then
            echo "$1 is not a directory" 1>&2
            usage
            exit 1
        fi
        custom=true
        installation_dir="$(cd "$1"; pwd)"
        if [[ "$installation_dir" == "/usr/local/opt/wize-flow" ]]; then
            custom=false
        else
            binary_installation_dir="$installation_dir/bin"
        fi
    fi

    local forced=false
    if [[ "$*" == *"--force"* ]]; then
        forced=true
    fi

    local ignore_deps=false
    if [[ "$*" == *"--ignore-dependencies"* ]]; then
        ignore_deps=true
    fi

    if [[ ! -f "$installation_dir/wize-flow" && "$forced" == "false" ]]; then
        echo "Wize-flow has not been installed under $installation_dir" 1>&2
        if [[ "${WIZE_FLOW_DIR-undefined}" != "undefined" ]]; then
            echo "Did you mean 'wize-flow-uninstall.sh $WIZE_FLOW_DIR' ?" 1>&2
        elif [[ "$custom" == "true" && -d "$installation_dir/wize-flow" ]]; then
            echo "Perhaps you meant 'wize-flow-uninstall.sh $installation_dir/wize-flow'" 1>&2
        fi
        echo "Run wize-flow-install.sh to install" 1>&2
        exit 1
    fi

    if [[ "$ignore_deps" == "false" ]]; then
        echo "Uninstalling dependencies..."
        brew uninstall git-flow-avh &>/dev/null
        brew uninstall hub &>/dev/null
        brew uninstall candid82/brew/joker &>/dev/null
    fi

    if [[ ! -f "$installation_dir/wize-flow" || ! -f "$binary_installation_dir/git-wize-flow" ]]; then
        echo "$installation_dir directory does not contain a wize-flow installation" 1>&2
        exit 1
    fi

    echo "Uninstalling wize-flow..."
    rm -fr "$installation_dir"
    if [[ "$custom" == "true" && "$binary_installation_dir" != "/usr/local/bin" ]]; then
        rm -fr "$binary_installation_dir"
    else
        rm -f "$binary_installation_dir/git-wize-flow"
    fi

    echo
    echo "Successfully uninstalled wize-flow!"
    echo
}

main "$@"
