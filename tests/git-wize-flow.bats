#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
}

teardown() {
    load common/teardown
}

@test "Running 'git wize-flow version' should return 'version' file contents" {
    run git wize-flow version
    [ "$status" == "0" ]
    [[ "$output" == "0.1.0" ]]
}

@test "Running 'git wize-flow -h' should show usage" {
    run git wize-flow -h
    [ "$status" == "0" ]
    [[ "$output" == *"usage:"* ]]
}
