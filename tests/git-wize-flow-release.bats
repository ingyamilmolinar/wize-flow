#!/usr/bin/env bats

setup() {
    # Unit testing support for release functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for release workflow"
    load common/setup
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
    load common/remote_cleanup
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for release workflow"
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown 
}

@test "Running 'git wize-flow release start my-release' should create a branch called release/my-release based on top of develop" {

    run git wize-flow release start my-release
    [ "$status" == "0" ]
    [[ "$output" == *"Switched to a new branch 'release/my-release'"* ]]
    [[ "$output" == *"Next step: Implement, add and commit"* ]]

    run git branch
    [ "$status" == "0" ]
    [[ "$output" == *"* release/my-release"* ]]
    
    #TODO: Find a way to check for the base branch
}

@test "Running 'git wize-flow feature|release|bugfix publish' after 'git wize-flow release start my-release' should throw an error" {
    git wize-flow release start my-release
    for workflow in "feature" "hotfix" "bugfix"; do
        run git wize-flow "$workflow" publish
        [ "$status" != "0" ]
        [[ "$output" == *"HEAD is no $workflow branch"* ]]
    done
}

@test "Running 'git wize-flow release publish my-release' without a 'release/my-release' branch should throw an error" {
    run git wize-flow release publish my-release
    [ "$status" != "0" ]
    [[ "$output" == *"release/my-release"* ]]
    [[ "$output" == *"does not exist"* ]]
}

@test "Running 'git wize-flow release start' with a repeated branch should throw an error" {
    git wize-flow release start my-release
    run git wize-flow release start my-release
    [ "$status" != "0" ]
    [[ "$output" == *"There is an existing release branch 'my-release'"* ]]
}

@test "Running 'git wize-flow release publish' after 'git wize-flow release start my-release' should execute successfully" {
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-release-$user_and_hostname"
    git wize-flow release start "$branch_name"
    run git wize-flow publish
    [ "$status" == "0" ]
    [[ "$output" == *"To github.com:wizeline/wize-flow-test.git"* ]]
    [[ "$output" == *"release/$branch_name -> release/$branch_name"* ]]
    [[ "$output" == *"Next step: Open PR"* ]]
}

@test "Running 'git wize-flow release finish' after 'git wize-flow release publish' executed successfully should validate PR" {
    
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-release-$user_and_hostname"
    git wize-flow release start "$branch_name"
    touch "$user_and_hostname"
    git add "$user_and_hostname"
    git commit -m "touching $user_and_hostname"
    
    # Calling finish without publishing should fail 
    run git wize-flow release finish "$branch_name" "0.2.0"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from release/$branch_name to develop on repository wize-flow-test"* ]]

    git wize-flow publish

    # Calling finish with published branch but no PR should fail
    run git wize-flow release finish "$branch_name" "0.2.0"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from release/$branch_name to develop on repository wize-flow-test"* ]]
    
    # Create PR on github from release/$branch_name to master 
    local -r pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b develop -h "release/$branch_name")
    local -r pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

    # Calling finish with open unmerged PR should fail
    run git wize-flow release finish "$branch_name" "0.2.0"
    [ "$status" != "0" ]
    [[ "$output" == *"The PR $pr_num on repository wize-flow-test has not been merged"* ]]

    # This will merge the open PR
    git checkout develop && git merge "release/$branch_name"
    FORCE_PUSH=true git push origin develop 

    # Sleep one second to wait for back-end API to sync
    sleep 1

    # Calling finish with merged PR should succeed
    run git wize-flow release finish "$branch_name" "0.2.0"
    [ "$status" == "0" ]
    [[ "$output" != *"branch 'release/$branch_name' has been merged into 'develop'"* ]]
    [[ "$output" == *"branch 'release/$branch_name' has been merged into 'master'"* ]]
    [[ "$output" == *"release was tagged '0.2.0'"* ]]
    [[ "$output" == *"branch 'release/$branch_name' has been locally deleted"* ]]
    [[ "$output" == *"has been remotely deleted from 'origin'"* ]]
    [[ "$output" == *"'develop', 'master' and tags have been pushed to 'origin'"* ]]
    [[ "$output" == *"Congratulations!"* ]]

    # Verify that master was tagged and that release/$branch_name was merged into master
    git checkout master
    run bash -c "git log --oneline --decorate | head -n2"
    [ "$status" == "0" ]
    [[ "$output" == *"(HEAD -> master, tag: 0.2.0, origin/master) Merge branch 'release/$branch_name'"* ]]
    [[ "$output" == *"(origin/develop, develop) touching $user_and_hostname"* ]]

    # Verifying that develop points to release/$branch_name
    # TODO: This will be the PR message on real life
    git checkout develop
    run bash -c "git log --oneline --decorate | head -n1"
    [[ "$status" == "0" ]]
    [[ "$output" == *"(HEAD -> develop, origin/develop) touching $user_and_hostname"* ]]    

    # Verifying that the branch was both locally and remotely deleted
    git fetch --prune
    [[ -z "$(git branch -a | grep "release/$branch_name")" ]]

    # Running git wize-flow release finish with the same branch name should fail
    git wize-flow release start "$branch_name"
    touch "$user_and_hostname-2"
    git add "$user_and_hostname-2"
    git commit -m "touching $user_and_hostname-2"
    git wize-flow publish

    run git wize-flow release finish "$branch_name" "0.2.0"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from release/$branch_name to develop on repository wize-flow-test"* ]]
    
}

#TODO @test "Running 'git wize-flow release finish' after a conflict should prompt the user for conflict resolution"
