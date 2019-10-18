#!/usr/bin/env bash

function usage {
    #TODO: More accurate usage
    echo "usage: git wize-flow <init|remove|reinit> [<repository-path>] [<git-hub-repository-url>]" 1>&2
    exit 1
}

function init() {

    if [ "$(git config --get wizeflow.enabled)" == "yes" ]; then
        echo "Wize-flow has been already initialized" 1>&2
        echo "Run 'git wize-flow remove $__repository_directory' to remove" 1>&2
        exit 1
    fi

    if git branch 2>&1 | grep -q 'not a git repository'; then
        if [[ -z $(git config --global user.name) || -z $(git config --global user.email) ]]; then
            echo "Please set up your global git user information first with: " 1>&2
            echo "     git config --add --global user.name <username>" 1>&2
            echo "     git config --add --global user.email <email>" 1>&2
            exit 1
        fi
        echo "Initializing git repo..."
        git init
    fi

    if ! git status; then
        echo "Your current git index and staging should be empty." 1>&2
        echo "Commit or reset your changes first." 1>&2
        exit 1
    fi
   
    if git remote | ( ! grep -q 'origin' ); then
        echo "Adding remote..."
        git remote add origin "$__remote"
    fi

    # Get current branch before changing
    local -r current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    git fetch --prune
    if git branch -a | grep -q 'remotes/origin/develop'; then
        echo "Pulling remote develop branch..."
        if [[ ! $(git checkout develop && git pull origin develop) ]]; then
            echo "There was an issue pulling develop branch. Please verify and try again" 1>&2
            exit 1
        fi
    fi
    if git branch -a | grep -q 'remotes/origin/master'; then
        echo "Pulling remote master branch..."
        if [[ ! $(git checkout master && git pull origin master) ]]; then
            echo "There was an issue pulling master branch. Please verify and try again" 1>&2
            exit 1
        fi
    fi

    if git branch | ( ! grep -q 'develop' ); then
        echo "Creating develop branch..."
        git checkout -b develop 
    fi

    # Switch back to saved branch
    if [[ -n "$current_branch" && "$current_branch" != "HEAD" ]]; then
        git checkout "$current_branch"
    fi

    echo "Initializing git-flow..." 
    # Need to provide the defaults when using -d option
    # See: https://github.com/petervanderdoes/gitflow-avh/issues/393 and https://github.com/nvie/gitflow/issues/6442
    # TOFIX: --remove-section Not working
    git config --remove-section gitflow 2>/dev/null
    git flow init -f -d --feature 'feature/' \
                        --bugfix 'bugfix/' \
                        --release 'release/' \
                        --hotfix 'hotfix/' \
                        --support 'support/' \
                        --local
    git config --add gitflow.origin origin
    
    if git branch -a | grep -q ' remotes/origin/master'; then
        echo "Pushing master branch to remote..."
        git push -u origin master
    fi
    if git branch -a | grep -q ' remotes/origin/develop'; then
        echo "Pushing develop branch to remote..."
        git push -u origin develop
    fi

    echo "Initializing wize-flow..."

    # Install pre-push script
    # TODO: Preserve what's already in the pre-push (if anything)
    cp -f "$(dirname "$0")"/pre-push-hook .git/hooks/pre-push
    cp -f "$(dirname "$0")"/pre-push-script .git/hooks

    # Set git-flow defaults
    "$(dirname "$0")"/git-flow-defaults.sh

    # Flag this repo as wize-flow enabled
    git config wizeflow.enabled 'yes' --local
    
    echo
    echo "Successfully initialized wize-flow!"
    echo "Run 'git wize-flow remove $__repository_directory' to remove"
    echo
    git wize-flow 
    echo
}

#This function uninstalls 
function remove() {

    if [ "$(git config --get wizeflow.enabled)" != "yes" ]; then
        echo "Wize-flow has not been initialized on this repository" 1>&2
        echo "Run 'git wize-flow init $__repository_directory <git-hub-repository-url>' to initialize" 1>&2
        exit 1
    fi

    echo "Removing wize-flow..."

    # TODO: Remove the specific changes introduced. Not everything
    rm -f "${__repository_directory}"/.git/hooks/pre-push
    rm -f "${__repository_directory}"/.git/hooks/pre-push-script
    git config --unset wizeflow.enabled
    # TODO: Unset wize-flow specific defaults

    echo
    echo "Successfully removed wize-flow!"
    echo
    
}

function reinit() {
    remove
    init
}

function main {

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Do not catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set +o pipefail

    [[ "$#" -lt 1 || "$#" -gt 3 ]] && usage
    
    case "${1-undefined}" in
        init|remove|reinit)
            __setup_command="$1"
            case "${2-undefined}" in
                undefined)
                    __repository_directory="$(pwd)"
                    ;;
                *)
                    __repository_directory="$2"
                    if [ ! -d "$__repository_directory" ]; then 
                        echo "$__repository_directory directory does not exist" 1>&2
                        usage
                    fi
                    ;;
            esac
            if [[ "$__setup_command" == "init" || "$__setup_command" == "reinit" ]]; then
                if ! git ls-remote "${3-undefined}" &>/dev/null; then
                    echo "$3 remote does not exist" 1>&2
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
