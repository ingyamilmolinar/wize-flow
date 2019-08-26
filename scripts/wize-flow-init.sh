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
            echo "Wize-flow has been already initialized. Run \"rm -r .git/wize-flow\" to uninstall" 1>&2
            exit 1
        fi
    fi
    
    echo "Updating brew and verifying dependencies..."
    brew update &>/dev/null
    brew install git-flow-avh &>/dev/null
    brew install hub &>/dev/null

    if git branch 2>&1 | grep 'not a git repository' &>/dev/null; then
        echo "Initializing git repo..."
        git init &>/dev/null
    fi

    if ! git remote | grep 'origin' &>/dev/null; then
        echo "Adding remote..."
        git remote add origin "$2" &>/dev/null
        git fetch &>/dev/null
    fi

    if git branch -a | grep 'remotes/origin/develop' &>/dev/null; then
        echo "Pulling remote develop branch..."
        git checkout develop
        if git pull origin develop 2>&1 | grep 'unrelated histories'; then
            echo "Your local and remote 'develop' branch have unrelated histories. Please verify and try again" 1>&2
            exit 1
        fi
    fi
    if git branch -a | grep 'remotes/origin/master' &>/dev/null; then
        echo "Pulling remote master branch..."
        git checkout master
        if git pull origin master 2>&1 | grep 'unrelated histories'; then
            echo "Your local and remote 'master' branch have unrelated histories. Please verify and try again" 1>&2
            exit 1
        fi
    fi

    if git log 2>&1 | grep 'does not have any commits yet' &>/dev/null; then
        echo "Your current branch does not have any commits yet. Commiting README.md..."
        touch README.md
        git add README.md
        git commit -m "initial commit"  &>/dev/null
    fi

    if ! git branch | grep 'develop' &>/dev/null; then
        echo "Creating develop branch..."
        git checkout -b develop  &>/dev/null
    fi

    if git flow log 2>&1 | grep 'Fatal' &>/dev/null; then
        echo "Initializing git-flow..." 
        # Need to provide the defaults when using -d option
        # See: https://github.com/petervanderdoes/gitflow-avh/issues/393 and https://github.com/nvie/gitflow/issues/6442
        git flow init -f -d --feature 'feature/' --bugfix 'bugfix/' --release 'release/' --hotfix 'hotfix/' --support 'support/' --local &>/dev/null
        git config --add gitflow.origin origin &>/dev/null
    fi
    
    if ! git branch -a | grep ' remotes/origin/master' &>/dev/null; then
        echo "Pushing master branch to remote..."
        git push -u origin master &>/dev/null
    fi
    if ! git branch -a | grep ' remotes/origin/develop' &>/dev/null; then
        echo "Pushing develop branch to remote..."
        git push -u origin develop &>/dev/null
    fi

    echo "Installing wize-flow..."
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
    
    echo
    echo "Successfully installed wize-flow!"
    echo "Run \"rm -r .git/wize-flow\" to uninstall"
    echo
    git flow show-usage --wize-flow
    echo
}

main "$@"
