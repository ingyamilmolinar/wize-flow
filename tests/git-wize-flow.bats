#!/usr/bin/env bats

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
