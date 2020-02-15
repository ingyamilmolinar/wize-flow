#!/usr/bin/env bats

setup() {
    #TODO: Support unit tests
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for pre-push hook"
    load common/setup
    git wize-flow init "$(pwd)" "$TEST_REPOSITORY_URL"
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for pre-push hook"
    git wize-flow remove "$(pwd)"
    load common/teardown
}

@test "Running 'git push origin develop' should fail" {
    run git push origin develop
    [ "$status" != "0" ]
    [[ "$output" == *"You cannot push directly"* ]]
}

@test "Running 'git push origin --delete develop' should fail" {
    run git push --delete origin develop
    [ "$status" != "0" ]
    [[ "$output" == *"You cannot push directly"* ]]
}

@test "Running 'git push origin master' should fail" {
    run git push origin master
    [ "$status" != "0" ]
    [[ "$output" == *"You cannot push directly"* ]]
}

@test "Running 'git push origin --delete master' should fail" {
    run git push --delete origin master 
    [ "$status" != "0" ]
    [[ "$output" == *"You cannot push directly"* ]]
}

@test "Running 'git push origin feature/test' should pass" {
    git checkout -b feature/test develop
    run git push origin feature/test
    [ "$status" == "0" ]
    git push --delete origin feature/test
}

@test "Running 'git push origin --delete feature/test' should pass" {
    git checkout -b feature/test develop
    run git push origin feature/test
    run git push --delete origin feature/test
    [ "$status" == "0" ]
}

#TODO: Test when locally tracking long-lived upstream branch and pushing without arguments
