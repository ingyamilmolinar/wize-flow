#!/usr/bin/env bash

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Updating brew and verifying dependencies..."
brew update &>/dev/null
brew install git-flow-avh &>/dev/null
brew install candid82/brew/joker &>/dev/null

echo "Installing wize-flow..."
cp -r src/joker /usr/local/opt/wize-flow
cp -f git-wize-flow /usr/local/bin

echo "Successfully installed wize-flow! Try 'git wize-flow -h' for usage."
