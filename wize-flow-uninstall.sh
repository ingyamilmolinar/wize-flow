#!/usr/bin/env bash

function usage() {
    echo "wize-flow-uninstall.sh [--force]" 1>&2
}

[[ "$#" > "1" ]] && usage && exit 1

if [[ ! -d "/usr/local/opt/wize-flow" && "$1" != "--force" ]]; then
    echo "Wize-flow has not been installed. Run wize-flow-install.sh to install" 1>&2
    exit 1
fi

echo "Uninstalling dependencies..."
brew uninstall git-flow-avh &>/dev/null
brew uninstall hub &>/dev/null
brew uninstall candid82/brew/joker &>/dev/null

echo "Uninstalling wize-flow..."
rm -f /usr/local/bin/git-wize-flow
rm -fr /usr/local/opt/wize-flow

echo
echo "Successfully uninstalled wize-flow!"
echo
