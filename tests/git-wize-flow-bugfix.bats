#!/usr/bin/env bats

setup() {
    # Unit testing support for bugfix functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for bugfix workflow"
    load common/setup
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
    load common/remote_cleanup
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for bugfix workflow"
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown 
}

@test "Running 'git wize-flow bugfix start my-bugfix' should create a branch called bugfix/my-bugfix based on top of develop" {

    run git wize-flow bugfix start my-bugfix
    [ "$status" == "0" ]
    [[ "$output" == *"Switched to a new branch 'bugfix/my-bugfix'"* ]]
    [[ "$output" == *"Next step: Implement, add and commit"* ]]

    run git branch
    [ "$status" == "0" ]
    [[ "$output" == *"* bugfix/my-bugfix"* ]]
    
    #TODO: Find a way to check for the base branch
}

@test "Running 'git wize-flow feature|release|hotfix publish' after 'git wize-flow bugfix start my-bugfix' should throw an error" {
    git wize-flow bugfix start my-bugfix
    for workflow in "feature" "release" "hotfix"; do
        run git wize-flow "$workflow" publish
        [ "$status" != "0" ]
        [[ "$output" == *"HEAD is no $workflow branch"* ]]
    done
}

@test "Running 'git wize-flow bugfix publish my-bugfix' without a 'bugfix/my-bugfix' branch should throw an error" {
    run git wize-flow bugfix publish my-bugfix
    [ "$status" != "0" ]
    [[ "$output" == *"bugfix/my-bugfix"* ]]
    [[ "$output" == *"does not exist"* ]]
}

@test "Running 'git wize-flow bugfix start' with a repeated branch should throw an error" {
    git wize-flow bugfix start my-bugfix
    run git wize-flow bugfix start my-bugfix
    [ "$status" != "0" ]
    [[ "$output" == *"Branch 'bugfix/my-bugfix' already exists"* ]]
}

@test "Running 'git wize-flow bugfix publish' after 'git wize-flow bugfix start my-bugfix' should execute successfully" {
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-bugfix-$user_and_hostname"
    git wize-flow bugfix start "$branch_name"
    run git wize-flow publish
    [ "$status" == "0" ]
    [[ "$output" == *"To github.com:wizeline/wize-flow-test.git"* ]]
    [[ "$output" == *"bugfix/$branch_name -> bugfix/$branch_name"* ]]
    [[ "$output" == *"Next step: Open PR"* ]]
}

@test "Running 'git wize-flow bugfix finish' after 'git wize-flow bugfix publish' executed successfully should validate PR" {
    
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-bugfix-$user_and_hostname"
    git wize-flow bugfix start "$branch_name"
    touch "$user_and_hostname"
    git add "$user_and_hostname"
    git commit -m "touching $user_and_hostname"
    
    # Calling finish without publishing should fail 
    run git wize-flow bugfix finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from bugfix/$branch_name to develop on repository wize-flow-test"* ]]

    git wize-flow publish

    # Calling finish with published branch but no PR should fail
    run git wize-flow bugfix finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from bugfix/$branch_name to develop on repository wize-flow-test"* ]]
    
    # Create PR on github from bugfix/$branch_name to develop
    local -r pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b develop -h "bugfix/$branch_name")
    local -r pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

    # Calling finish with open unmerged PR should fail
    run git wize-flow bugfix finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"The PR $pr_num on repository wize-flow-test has not been merged"* ]]

    # This will merge the open PR
    git checkout develop && git merge "bugfix/$branch_name"
    FORCE_PUSH=true git push origin develop

    # Sleep one second to wait for back-end API to sync
    sleep 1

    # Calling finish with merged PR should succeed
    run git wize-flow bugfix finish "$branch_name"
    [ "$status" == "0" ]
    [[ "$output" == *"branch 'bugfix/$branch_name' was merged into 'develop'"* ]]
    [[ "$output" == *"branch 'bugfix/$branch_name' has been locally deleted"* ]]
    [[ "$output" == *"has been remotely deleted from 'origin'"* ]]
    [[ "$output" == *"Congratulations!"* ]]

    # Verifying that the branch was both locally and remotely deleted
    git fetch --prune
    [[ -z "$(git branch -a | grep "bugfix/$branch_name")" ]]

    # Running git wize-flow bugfix finish with the same branch name should fail
    git wize-flow bugfix start "$branch_name"
    touch "$user_and_hostname-2"
    git add "$user_and_hostname-2"
    git commit -m "touching $user_and_hostname-2"
    git wize-flow publish

    run git wize-flow bugfix finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from bugfix/$branch_name to develop on repository wize-flow-test"* ]]
    
}
