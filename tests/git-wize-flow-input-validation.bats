#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
    git wize-flow init "$BATS_TMPDIR"/"$BATS_TEST_NAME" git@github.com:wizeline/wize-flow-test.git
}

teardown() {
    git wize-flow remove "$BATS_TMPDIR"/"$BATS_TEST_NAME"
    load common/teardown
}

@test "Running 'git wize-flow' with no arguments should show usage" {
    run git wize-flow 
    [ "$status" != "0" ]
    [[ "$output" == *"usage:"* ]]
}

@test "Running 'git wize-flow' with invalid argument should show usage" {
    run git wize-flow star 
    [ "$status" != "0" ]
    [[ "$output" == *"usage:"* ]]
}

@test "Running 'git wize-flow feature|bugfix|release|hotfix' should throw error" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        run git wize-flow "$workflow"
        [ "$status" != "0" ]
    done
}

@test "Running 'git wize-flow start|publish|finish' should throw error" {
    for stage in "start" "publish" "finish"; do
        run git wize-flow "$stage"
        [ "$status" != "0" ]
    done
}

@test "Running 'git wize-flow feature|bugfix|release|hotfix start|publish|finish' should throw error" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        for stage in "start" "publish" "finish"; do
            run git wize-flow "$workflow" "$stage"
            [ "$status" != "0" ]
        done
    done
}
