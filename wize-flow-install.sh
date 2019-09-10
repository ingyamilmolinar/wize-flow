#!/usr/bin/env bash

function usage() {
    echo "wize-flow-install.sh <bash|joker> [--force]" 1>&2
}

[[ "$#" != "1" && "$#" != "2" ]] && usage && exit 1

if [[ -d "/usr/local/opt/wize-flow" && "$2" != "--force" ]]; then 
    echo "Wize-flow has been already installed. Run wize-flow-uninstall.sh to uninstall" 1>&2
    exit 1
fi

#TODO: Catch and handle manual aborts on all scripts
if test ! "$(which brew)"; then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Updating brew and installing dependencies..."
brew update &>/dev/null
brew install git-flow-avh &>/dev/null
case "$1" in
    bash)
        brew install hub &>/dev/null
        ;;
    joker)
        brew install candid82/brew/joker &>/dev/null
        ;;
    *)
        usage
        exit 1
        ;;
esac

echo "Installing wize-flow..."
readonly init_script_relative_path="$(dirname $0)"/src/"$1"

mkdir -p /usr/local/opt/wize-flow
# Order matters in the next two commands. We override git-wize-flow on purpose
cp -f "$init_script_relative_path"/../common/* /usr/local/opt/wize-flow
cp -f "$init_script_relative_path"/* /usr/local/opt/wize-flow

# This will extend git with 'git wize-flow'. See: https://stackoverflow.com/questions/10978257/extending-git-functionality
cp -f "$init_script_relative_path"/../common/git-wize-flow /usr/local/bin

echo "Wize-flow was installed successfully on /usr/local/opt/wize-flow"

