#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
    #TOFIX: We shouldn't need to have an initialized repository just to validate inputs
    #Added this line so last tests don't break
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
}

teardown() {
    #TOFIX: Don't forget to update this line as well
    git wize-flow remove "$(pwd)"
    load common/teardown
}

@test "Running 'git wize-flow version' should return 'version' file contents" {
    run git wize-flow version
    [ "$status" == "0" ]
    [[ "$output" == "0.1.0" ]]
}

@test "Running 'git wize-flow -h' should show usage and exit succesfully" {
    run git wize-flow -h
    [ "$status" == "0" ]
    [[ "$output" == *"usage:"* ]]
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

@test "Running 'git wize-flow feature|bugfix|release|hotfix' should show usage" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        run git wize-flow "$workflow"
        [ "$status" != "0" ]
        [[ "$output" == *"usage:"* ]]
    done
}

@test "Running 'git wize-flow start|publish|finish' should show usage" {
    for stage in "start" "publish" "finish"; do
        run git wize-flow "$stage"
        [ "$status" != "0" ]
        [[ "$output" == *"usage:"* ]]
    done
}

@test "Running 'git wize-flow feature|bugfix|release|hotfix start|publish|finish' should show usage" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        for stage in "start" "publish" "finish"; do
            run git wize-flow "$workflow" "$stage"
            [ "$status" != "0" ]
            [[ "$output" == *"usage:"* ]]
        done
    done
}
