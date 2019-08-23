#!/usr/bin/env bash

function usage {
    echo "usage: $0 <repository-path>" 1>&2
    exit 1
}

function main {

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set -o pipefail

    [[ ! -d "$1" ]] && usage

    brew update
    brew install git-flow-avh
    brew install hub
    if ! git branch &>/dev/null; then
        git init
    fi
    if ! git flow log &>/dev/null; then
        git flow init -d
    fi
    
    if ! git remote | grep '.' &>/dev/null; then
        echo "Wize-flow works only on GitHub repositories." 1>&2
        echo "Create one if not already created and add a remote to your local git repository using 'git remote add <name> <url>' and retry" 1>&2
        exit 1
    fi

    if ! git branch -a | grep ' remotes/origin/master' &>/dev/null; then
        git push origin master
    fi
    if ! git branch -a | grep ' remotes/origin/develop' &>/dev/null; then
        git push origin develop
    fi

    mkdir -p .git/wize-flow
    init_script_relative_path=$(dirname "$0")
    cp -f $init_script_relative_path/* .git/wize-flow && chmod +x .git/wize-flow/*

    # Install pre-push script
    mv -f .git/wize-flow/pre-push .git/hooks

    # Install git override and verify
    source .git/wize-flow/git-override.sh 

    # Source git defaults and verify
    source .git/wize-flow/git-flow-defaults.sh
    
    echo "Successfully installed wize-flow!"
}

main "$@"
