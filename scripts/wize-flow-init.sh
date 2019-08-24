#!/usr/bin/env bash

function usage {
    #TODO: Create uninstall script or option
    echo "usage: $0 <repository-path> <git-hub-repository-url>" 1>&2
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

    [[ "$#" != 2 || ! -d "$1" ]] || git ls-remote "$2" 2>&1 | grep 'Repository not found' && usage
   
    if ! git rev-parse --show-toplevel 2>&1 | grep 'fatal' &>/dev/null; then
        local -r wize_flow_dir="$(git rev-parse --show-toplevel)"/.git/wize-flow
        if [[ -d "$wize_flow_dir" ]]; then
            echo "Wize-flow has been already initialized" 1>&2
            exit 1
        fi
    fi
    
    brew update &>/dev/null
    brew install git-flow-avh &>/dev/null
    brew install hub &>/dev/null

    if git branch 2>&1 | grep 'not a git repository' &>/dev/null; then
        git init
    fi

    if ! git remote | grep 'origin' &>/dev/null; then
        git remote add origin "$2" &>/dev/null
        git fetch &>/dev/null
    fi

    if git branch -a | grep 'remotes/origin/develop' &>/dev/null; then
        git pull origin develop 
    fi
    if git branch -a | grep 'remotes/origin/master' &>/dev/null; then
        git pull origin master
    fi

    if git log 2>&1 | grep 'does not have any commits yet' &>/dev/null; then
        echo "Your current branch does not have any commits yet. Commiting README.md..."
        touch README.md
        git add README.md
        git commit -m "initial commit"
    fi

    if ! git branch | grep 'develop' &>/dev/null; then
        git checkout -b develop
    fi

    if ! git flow log 2>&1 | grep 'Fatal' &>/dev/null; then
        git flow init -d
    fi
    
    if ! git branch -a | grep ' remotes/origin/master' &>/dev/null; then
        git push -u origin master
    fi
    if ! git branch -a | grep ' remotes/origin/develop' &>/dev/null; then
        git push -u origin develop
    fi

    mkdir -p .git/wize-flow
    init_script_relative_path=$(dirname "$0")
    cp -f $init_script_relative_path/* .git/wize-flow && chmod +x .git/wize-flow/*

    # Install pre-push script
    cp -f .git/wize-flow/pre-push-hook .git/hooks/pre-push

    # Install git override and verify
    # TODO: Persist git function definition
    source .git/wize-flow/git-override.sh 

    # Source git defaults and verify
    .git/wize-flow/git-flow-defaults.sh
    
    echo "Successfully installed wize-flow!"
    #TODO: Link it to the actual tool usage
    echo "usage: git flow feature|bugfix|release|hotfix start|publish|finish [version-tag] [tag-message] --wize-flow"
}

main "$@"
