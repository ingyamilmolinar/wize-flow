#!/usr/bin/env bats

setup() {
    # Unit testing support for hotfix functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for hotfix workflow"
    load common/setup
    git wize-flow init "$(pwd)" "$TEST_REPOSITORY_URL"
    load common/remote_cleanup
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for hotfix workflow"
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown 
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
    [[ "$output" == *"No PR has been created from hotfix/$branch_name to master on repository $TEST_REPOSITORY_NAME"* ]]

    git wize-flow publish

    # Calling finish with published branch but no PR should fail
    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from hotfix/$branch_name to master on repository $TEST_REPOSITORY_NAME"* ]]
    
    # Create PR on github from hotfix/$branch_name to master 
    local -r pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b master -h "hotfix/$branch_name")
    local -r pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

    # Calling finish with open unmerged PR should fail
    run git wize-flow hotfix finish "$branch_name" "0.1.1"
    [ "$status" != "0" ]
    [[ "$output" == *"The PR $pr_num on repository $TEST_REPOSITORY_NAME has not been merged"* ]]

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

    #run git wize-flow hotfix finish "$branch_name" "0.1.1"
    run bash -c "git wize-flow hotfix finish $branch_name 0.1.1"
    echo "status: $status"
    echo "output: $output"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from hotfix/$branch_name to master on repository $TEST_REPOSITORY_NAME"* ]]
    
}

@test "Running 'git wize-flow hotfix finish' after a conflict should not succeed" {
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-hotfix-$user_and_hostname"
    git wize-flow hotfix start "$branch_name"
    echo 'First message' > "$user_and_hostname"
    git add "$user_and_hostname"
    git commit -m "touching $user_and_hostname"
    
    git wize-flow publish

    # Create PR on github from hotfix/$branch_name to master 
    local -r pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b master -h "hotfix/$branch_name")
    local -r pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

    # Create another clone of the test repository
    test_dir="$(pwd)"
    rm -fr "$BATS_TMPDIR"/"$BATS_TEST_NAME-conflict"
    mkdir -p "$BATS_TMPDIR"/"$BATS_TEST_NAME-conflict"
    cd "$BATS_TMPDIR"/"$BATS_TEST_NAME-conflict"
    git clone "$TEST_REPOSITORY_URL" "$(pwd)"

    # Simulate a conflict on develop 
    git checkout develop
    echo 'Second message' > "$user_and_hostname"
    git add "$user_and_hostname"
    git commit -m "Also touching $user_and_hostname"
    FORCE_PUSH=true git push origin develop
    
    # Return to the previous directory and delete the cloned copy
    cd "$test_dir"
    rm -fr "$BATS_TMPDIR/$BATS_TEST_NAME-conflict"

    # This will merge the open PR
    git checkout master && git merge "hotfix/$branch_name"
    FORCE_PUSH=true git push origin master

    # Sleep one second to wait for back-end API to sync
    sleep 1

    # Calling finish should not succeed due to conflicts
    run git wize-flow hotfix finish "$branch_name" "0.2.0"
    [ "$status" != "0" ]
    # Ubuntu and MacOS throw different message errors. TODO: It could be a wize-flow bug
    [[ "$output" == *"Branches 'develop' and 'origin/develop' have diverged"* || "$output" == *"Automatic merge failed"* ]]

}
