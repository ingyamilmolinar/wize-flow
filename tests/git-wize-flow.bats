#!/usr/bin/env bats

setup() {
    export PATH=$(pwd)/../joker:$PATH
}

@test "Get verison info" {
    run git wize-flow version
    [ "$status" -eq 0 ]
    [[ "$output" == *"wize-flow 0.0.1"* ]]
}

@test "Running 'git wize-flow -h' should show usage" {
    run git wize-flow -h
    [ "$status" != "0" ]
    [[ "$output" == *"usage:"* ]]
}

@test "Running 'git wize-flow <subcommand>' should call 'git flow <subcommand>' (except finish)" {
    # Mock 'git flow init' command
    function git() {
        if [[ "$1" == "flow" && "$2" == "init" ]]; then
            echo "'git flow init' mock called"
            return 1
        fi
        command git "$@" || return $?
    }
    export -f git
    
    run git wize-flow init
    [ "$status" = "1" ]
    [[ "$output" == *"mock called"* ]]
}
