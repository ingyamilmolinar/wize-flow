#!/usr/bin/env bats

setup() {
    # Unit testing support for feature functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for workflow tests"
    load common/setup
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
    load common/remote_cleanup
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for workflow tests"
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown 
}

@test "Running 'git wize-flow <workflow> start my-branch' should create a branch called <workflow>/my-branch based on top of <base-branch>" {

    for workflow in "feature" "bugfix" "release" "hotfix"; do
        run git wize-flow "$workflow" start my-branch
        [ "$status" == "0" ]
        [[ "$output" == *"Switched to a new branch '$workflow/my-branch'"* ]]
        [[ "$output" == *"Next step: Implement, add and commit"* ]]

        run git branch
        [ "$status" == "0" ]
        [[ "$output" == *"* $workflow/my-branch"* ]]

        git checkout develop 
        git branch -d "$workflow/my-branch"
    done
    
    #TODO: Find a way to check for the base branch
}

@test "Running 'git wize-flow <other-workflows> publish' after 'git wize-flow <workflow> start my-branch' should throw an error" {

    for started_workflow in "feature" "bugfix" "release" "hotfix"; do
        git wize-flow "$started_workflow" start my-branch
        for workflow in "feature" "bugfix" "release" "hotfix"; do
            [[ "$started_workflow" == "$workflow" ]] && continue
            run git wize-flow "$workflow" publish
            [ "$status" != "0" ]
            [[ "$output" == *"HEAD is no $workflow branch"* ]]
        done

        git checkout develop 
        git branch -d "$started_workflow/my-branch"
    done
}

@test "Running 'git wize-flow <workflow> publish my-branch' without a '<workflow>/my-branch' branch should throw an error" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        run git wize-flow "$workflow" publish my-branch
        [ "$status" != "0" ]
        [[ "$output" == *"$workflow/my-branch"* ]]
        [[ "$output" == *"does not exist"* ]]
    done
}

@test "Running 'git wize-flow <workflow> start' with a repeated branch should throw an error" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        git wize-flow "$workflow" start my-branch
        run git wize-flow "$workflow" start my-branch
        [ "$status" != "0" ]
        # For hotfix and release the message is different on Ubuntu and MacOS. TODO: Could be a wize-flow bug
        [[ "$output" == *"Branch '$workflow/my-branch' already exists"* || "$output" == *"There is an existing $workflow branch 'my-branch'"* ]]

        git checkout develop 
        git branch -d "$workflow/my-branch"
    done
}

@test "Running 'git wize-flow <workflow> publish' after 'git wize-flow <workflow> start my-branch' should execute successfully" {
    for workflow in "feature" "bugfix" "release" "hotfix"; do
        local user_and_hostname="$(whoami)-$(hostname)"
        local branch_name="my-branch-$user_and_hostname"

        git wize-flow "$workflow" start "$branch_name"
        run git wize-flow publish
        [ "$status" == "0" ]
        [[ "$output" == *"To github.com:wizeline/wize-flow-test.git"* ]]
        [[ "$output" == *"$workflow/$branch_name -> $workflow/$branch_name"* ]]
        [[ "$output" == *"Next step: Open PR"* ]]

        git checkout develop 
        git branch -d "$workflow/$branch_name"
    done
}
