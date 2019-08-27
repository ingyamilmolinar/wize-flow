#!/usr/bin/env bash

function usage {
    #TODO: More accurate usage
    echo "usage: $0 <install|uninstall|reinstall> [<repository-path>] [<git-hub-repository-url>]" 1>&2
    exit 1
}

function install() {
    if [[ -z $(git rev-parse --show-toplevel 2>&1 | grep 'fatal') ]]; then
        local -r wize_flow_dir="$(git rev-parse --show-toplevel)"/.git/wize-flow
        if [[ -d "$wize_flow_dir" ]]; then
            echo "Wize-flow has been already initialized. Run \"$0 uninstall $__repository_directory\" to uninstall" 1>&2
            exit 1
        fi
    fi
    
    echo "Updating brew and verifying dependencies..."
    brew update &>/dev/null
    brew install git-flow-avh &>/dev/null
    brew install hub &>/dev/null

    if [[ ! -z $(git branch 2>&1 | grep 'not a git repository') ]]; then
        echo "Initializing git repo..."
        git init &>/dev/null
    fi

    if [[ -z $(git remote | grep 'origin') ]]; then
        echo "Adding remote..."
        git remote add origin "$__remote" &>/dev/null
        git fetch &>/dev/null
    fi

    if [[ ! -z $(git branch -a | grep 'remotes/origin/develop') ]]; then
        echo "Pulling remote develop branch..."
        git checkout develop
        if [[ ! -z $(git pull origin develop 2>&1 | grep 'unrelated histories') ]]; then
            echo "Your local and remote 'develop' branch have unrelated histories. Please verify and try again" 1>&2
            exit 1
        fi
    fi
    if [[ ! -z $(git branch -a | grep 'remotes/origin/master') ]]; then
        echo "Pulling remote master branch..."
        git checkout master
        if [[ ! -z $(git pull origin master 2>&1 | grep 'unrelated histories') ]]; then
            echo "Your local and remote 'master' branch have unrelated histories. Please verify and try again" 1>&2
            exit 1
        fi
    fi

    if [[ ! -z $(git log 2>&1 | grep 'does not have any commits yet') ]]; then
        echo "Your current branch does not have any commits yet. Commiting README.md..."
        touch README.md
        git add README.md
        git commit -m "initial commit"  &>/dev/null
    fi

    if [[ -z $(git branch | grep 'develop') ]]; then
        echo "Creating develop branch..."
        git checkout -b develop  &>/dev/null
    fi

    if [[ ! -z $(git flow log 2>&1 | grep 'Fatal') ]]; then
        echo "Initializing git-flow..." 
        # Need to provide the defaults when using -d option
        # See: https://github.com/petervanderdoes/gitflow-avh/issues/393 and https://github.com/nvie/gitflow/issues/6442
        git flow init -f -d --feature 'feature/' --bugfix 'bugfix/' --release 'release/' --hotfix 'hotfix/' --support 'support/' --local &>/dev/null
        git config --add gitflow.origin origin &>/dev/null
    fi
    
    if [[ -z $(git branch -a | grep ' remotes/origin/master') ]]; then
        echo "Pushing master branch to remote..."
        git push -u origin master &>/dev/null
    fi
    if [[ -z $(git branch -a | grep ' remotes/origin/develop') ]]; then
        echo "Pushing develop branch to remote..."
        git push -u origin develop &>/dev/null
    fi

    echo "Installing wize-flow..."
    mkdir -p .git/wize-flow
    local -r init_script_relative_path=$(dirname "$0")
    cp -f $init_script_relative_path/* .git/wize-flow && chmod +x .git/wize-flow/*

    # Install pre-push script
    cp -f .git/wize-flow/pre-push-hook .git/hooks/pre-push

    # Put git-wize-flow script in /usr/local/bin. 
    # This will extend git with 'git wize-flow'. See: https://stackoverflow.com/questions/10978257/extending-git-functionality
    cp -f .git/wize-flow/git-wize-flow /usr/local/bin

    # Set git defaults
    .git/wize-flow/git-flow-defaults.sh
    
    echo
    echo "Successfully installed wize-flow!"
    echo "Run \"$0 uninstall $__repository_directory\" to uninstall"
    echo
    git wize-flow 
    echo
}

function uninstall() {

    if [[ -z $(git rev-parse --show-toplevel 2>&1 | grep 'fatal') ]]; then
        local -r wize_flow_dir="$(git rev-parse --show-toplevel)"/.git/wize-flow
        if [[ ! -d "$wize_flow_dir" ]]; then
            echo "Wize-flow has not been intalled on this repository. Run \"$0 install $__repository_directory <git-hub-repository-url>\" to install" 1>&2
            exit 1
        fi
    fi

    echo "Uninstalling dependencies..."
    #TODO: Do we uninstall git-flow-avh or only wize-flow?
    brew uninstall git-flow-avh
    brew uninstall hub 

    echo "Uninstalling wize-flow..."
    rm -fr "${__repository_directory}"/.git/wize-flow
    rm -f "${__repository_directory}"/.git/hooks/pre-push
    rm -f /usr/local/bin/git-wize-flow

    echo
    echo "Successfully uninstalled wize-flow!"
    echo
    
}

function reinstall() {
    uninstall
    install
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

    [[ "$#" < 1 || "$#" > 3 ]] && usage
    
    case "${1-undefined}" in
        install|uninstall|reinstall)
            __setup_command="$1"
            case "${2-undefined}" in
                undefined)
                    __repository_directory="$(pwd)"
                    ;;
                *)
                    __repository_directory="$2"
                    [[ ! -d "$__repository_directory" ]] && usage
                    ;;
            esac
            if [[ "$__setup_command" == "install" || "$__setup_command" == "reinstall" ]]; then
                if [[ ! -z $(git ls-remote "${3-undefined}" 2>&1 | grep 'fatal') ]]; then
                    usage
                fi 
                __remote="$3"
            fi
            ;;
        *)
            usage
            ;;
    esac
    
    "$__setup_command"
}

main "$@"
