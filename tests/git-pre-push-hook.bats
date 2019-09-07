#!/usr/bin/env bats

setup() {
    #TODO: Support unit tests
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for pre-push hook"
    load common/setup
    git wize-flow init "$BATS_TMPDIR"/"$BATS_TEST_NAME" git@github.com:wizeline/wize-flow-test.git
}

teardown() {
    git wize-flow remove "$BATS_TMPDIR"/"$BATS_TEST_NAME"
    load common/teardown
}

@test "Running 'git push origin develop' should fail" {
    run git push origin develop
    [ "$status" != "0" ]
    [[ "$output" == *"You cannot push directly"* ]]
}

@test "Running 'git push origin master' should fail" {
    run git push origin master
    [ "$status" != "0" ]
    [[ "$output" == *"You cannot push directly"* ]]
}

@test "Running 'git push origin feature/test' should pass" {
    git checkout -b feature/test develop
    run git push origin feature/test
    [ "$status" == "0" ]
}

#TODO: @test "Running 'git push origin --delete feature/test' should pass"
