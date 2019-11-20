#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
    #TOFIX: We shouldn't need to have an initialized repository just to validate inputs
    #Added this line so last tests don't break
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
    load common/remote_cleanup
}

teardown() {
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown
}

@test "Running 'git wize-flow version' should return 'version' file contents" {
    run git wize-flow version
    [ "$status" == "0" ]
    [[ "$output" == "$(cat $WIZE_FLOW_TEST_INSTALL/wize-flow/version)" ]]

    echo "9.9.9" > $WIZE_FLOW_TEST_INSTALL/wize-flow/version
    run git wize-flow version
    [[ "$output" == "9.9.9" ]]
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

@test "Running 'git wize-flow start' should show usage" {
    run git wize-flow start
    [ "$status" != "0" ]
    [[ "$output" == *"usage:"* ]]
}

@test "Running 'git wize-flow feature|bugfix|release|hotfix start' should show usage" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        for stage in "start"; do
            run git wize-flow "$workflow" "$stage"
            [ "$status" != "0" ]
            [[ "$output" == *"usage:"* ]]
        done
    done
}

@test "Running 'git wize-flow feature|bugfix|release|hotfix publish|finish' should infer the branch from context" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        git wize-flow "$workflow" start my-branch
        run git wize-flow "$workflow" publish
        [ "$status" == "0" ]
        [[ "$output" == *"$workflow/my-branch"* ]]
        if [[ "$workflow" == "feature" || "$workflow" == "bugfix" ]]; then
            target_branch="develop"
            run git wize-flow "$workflow" finish
        else
            #TOFIX: This test case fails! Make the input validation flexible
            continue
            [[ "$workflow" == "release" ]] && target_branch="develop"
            [[ "$workflow" == "hotfix" ]] && target_branch="master"
            run git wize-flow "$workflow" finish
            [ "$status" != "0" ]
            [[ "$output" == *"tag-version is mandatory for $workflow branch"* ]]
            run git wize-flow "$workflow" finish "tag"
        fi
        [ "$status" != "0" ]
        [[ "$output" == *"No PR has been created from $workflow/my-branch to $target_branch on repository"* ]]
    done
}

@test "Running 'git wize-flow publish|finish' should infer the workflow type and branch from context" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        git wize-flow "$workflow" start my-branch
        run git wize-flow publish
        [ "$status" == "0" ]
        [[ "$output" == *"$workflow/my-branch"* ]]
        if [[ "$workflow" == "feature" || "$workflow" == "bugfix" ]]; then
            target_branch="develop"
            run git wize-flow finish
        else
            #TOFIX: This test case fails! Make the input validation flexible
            continue
            [[ "$workflow" == "release" ]] && target_branch="develop"
            [[ "$workflow" == "hotfix" ]] && target_branch="master"
            run git wize-flow finish
            [ "$status" != "0" ]
            [[ "$output" == *"tag-version is mandatory for $workflow branch"* ]]
            run git wize-flow finish "tag"
            
        fi
        [ "$status" != "0" ]
        [[ "$output" == *"No PR has been created from $workflow/my-branch to $target_branch on repository"* ]]
    done
}
