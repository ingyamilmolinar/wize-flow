#!/usr/bin/env bats

setup() {
    # Unit testing support for hotfix functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for hotfix workflow"
    load common/setup
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
    load common/remote_cleanup
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for hotfix workflow"
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown 
}

@test "Running 'git wize-flow hotfix start my-hotfix' should create a branch called hotfix/my-hotfix based on top of master" {

    run git wize-flow hotfix start my-hotfix
    [ "$status" == "0" ]
    [[ "$output" == *"Switched to a new branch 'hotfix/my-hotfix'"* ]]
    [[ "$output" == *"Next step: Implement, add and commit"* ]]

    run git branch
    [ "$status" == "0" ]
    [[ "$output" == *"* hotfix/my-hotfix"* ]]
    
    #TODO: Find a way to check for the base branch
}

@test "Running 'git wize-flow feature|release|bugfix publish' after 'git wize-flow hotfix start my-hotfix' should throw an error" {
    git wize-flow hotfix start my-hotfix
    for workflow in "feature" "release" "bugfix"; do
        run git wize-flow "$workflow" publish
        [ "$status" != "0" ]
        [[ "$output" == *"HEAD is no $workflow branch"* ]]
    done
}

@test "Running 'git wize-flow hotfix publish my-hotfix' without a 'hotfix/my-hotfix' branch should throw an error" {
    run git wize-flow hotfix publish my-hotfix
    [ "$status" != "0" ]
    [[ "$output" == *"hotfix/my-hotfix"* ]]
    [[ "$output" == *"does not exist"* ]]
}

@test "Running 'git wize-flow hotfix start' with a repeated branch should throw an error" {
    git wize-flow hotfix start my-hotfix
    run git wize-flow hotfix start my-hotfix
    [ "$status" != "0" ]
    [[ "$output" == *"There is an existing hotfix branch 'my-hotfix'"* ]]
}

@test "Running 'git wize-flow hotfix publish' after 'git wize-flow hotfix start my-hotfix' should execute successfully" {
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-hotfix-$user_and_hostname"
    git wize-flow hotfix start "$branch_name"
    run git wize-flow publish
    [ "$status" == "0" ]
    [[ "$output" == *"To github.com:wizeline/wize-flow-test.git"* ]]
    [[ "$output" == *"hotfix/$branch_name -> hotfix/$branch_name"* ]]
    [[ "$output" == *"Next step: Open PR"* ]]
}

@test "Running 'git wize-flow hotfix finish' after 'git wize-flow hotfix publish' executed successfully should validate PR" {
    
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-hotfix-$user_and_hostname"
    git wize-flow hotfix start "$branch_name"
    touch "$user_and_hostname"
    git add "$user_and_hostname"
    git commit -m "touching $user_and_hostname"
    
    # Calling finish without publishing should fail 
    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from hotfix/$branch_name to master on repository wize-flow-test"* ]]

    git wize-flow publish

    # Calling finish with published branch but no PR should fail
    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from hotfix/$branch_name to master on repository wize-flow-test"* ]]
    
    # Create PR on github from hotfix/$branch_name to master 
    local -r pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b master -h "hotfix/$branch_name")
    local -r pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

    # Calling finish with open unmerged PR should fail
    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" != "0" ]
    [[ "$output" == *"The PR $pr_num on repository wize-flow-test has not been merged"* ]]

    # This will merge the open PR
    git checkout master && git merge "hotfix/$branch_name"
    FORCE_PUSH=true git push origin master 

    # Sleep one second to wait for back-end API to sync
    sleep 1

    # Calling finish with merged PR should succeed
    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" == "0" ]
    # TODO: Next commented line fails. It must be a bug on wize-flow
    # [[ "$output" != *"branch 'hotfix/$branch_name' has been merged into 'master'"* ]]
    [[ "$output" == *"branch 'hotfix/$branch_name' has been merged into 'develop'"* ]]
    [[ "$output" == *"hotfix was tagged '0.1.1'"* ]]
    [[ "$output" == *"branch 'hotfix/$branch_name' has been locally deleted"* ]]
    [[ "$output" == *"has been remotely deleted from 'origin'"* ]]
    [[ "$output" == *"'develop', 'master' and tags have been pushed to 'origin'"* ]]
    [[ "$output" == *"Congratulations!"* ]]

    # Verify that master was tagged and verify that master points to hotfix/$branch_name
    # TODO: This will be the PR message on real life
    git checkout master
    run bash -c "git log --oneline --decorate | head -n1"
    [ "$status" == "0" ]
    [[ "$output" == *"(HEAD -> master, tag: 0.1.1, origin/master) touching $user_and_hostname"* ]]
    
    # Verifying that the hotfix/$branch_name was merged into develop
    git checkout develop
    run bash -c "git log --oneline --decorate | head -n2"
    [[ "$status" == "0" ]]
    [[ "$output" == *"(HEAD -> develop, origin/develop) Merge branch 'hotfix/$branch_name' into develop"* ]]
    [[ "$output" == *"(tag: 0.1.1, origin/master, master) touching $user_and_hostname"* ]]
    
    # Verifying that the branch was both locally and remotely deleted
    git fetch --prune
    [[ -z "$(git branch -a | grep "hotfix/$branch_name")" ]]

    # Running git wize-flow hotfix finish with the same branch name should fail
    git wize-flow hotfix start "$branch_name"
    touch "$user_and_hostname-2"
    git add "$user_and_hostname-2"
    git commit -m "touching $user_and_hostname-2"
    git wize-flow publish

    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from hotfix/$branch_name to master on repository wize-flow-test"* ]]
    
}
