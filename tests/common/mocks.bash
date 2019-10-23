#!/usr/local/env bash

# Mock all git commands that will interact with the network
git() {
    [[ "$1" == "ls-remote" && "$2" == *"git@github.com"* ]] && return 0
    [[ "$1" == "remote" && "$2" == "add" ]] && return 0
    [[ "$1" == "fetch" ]] && return 0
    [[ "$1" == "pull" ]] && return 0
    [[ "$1" == "push" ]] && return 0
    command git "$@"
    return "$?"
}

hub() { return 0; }

brew() { return 0; }

curl() { return 0; }

wget() { return 0; }

export -f git hub brew curl wget
