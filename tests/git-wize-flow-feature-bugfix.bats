#!/usr/bin/env bats

setup() {
    # Unit testing support for feature|bugfix functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for feature|bugfix workflow"
    load common/setup
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
    load common/remote_cleanup
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for feature|bugfix workflow"
    load common/remote_cleanup
    git wize-flow remove "$(pwd)"
    load common/teardown 
}

@test "Running 'git wize-flow feature|bugfix finish' after 'git wize-flow feature|bugfix publish' executed successfully should validate PR" {

    for workflow in "feature" "bugfix"; do 
        local user_and_hostname="$(whoami)-$(hostname)"
        local branch_name="my-branch-$user_and_hostname"
        git wize-flow "$workflow" start "$branch_name"
        touch "$user_and_hostname"
        git add "$user_and_hostname"
        git commit -m "touching $user_and_hostname"
        
        # Calling finish without publishing should fail 
        run git wize-flow "$workflow" finish "$branch_name"
        [ "$status" != "0" ]
        [[ "$output" == *"No PR has been created from $workflow/$branch_name to develop on repository wize-flow-test"* ]]

        git wize-flow publish

        # Calling finish with published branch but no PR should fail
        run git wize-flow "$workflow" finish "$branch_name"
        [ "$status" != "0" ]
        [[ "$output" == *"No PR has been created from $workflow/$branch_name to develop on repository wize-flow-test"* ]]
        
        # Create PR on github from $workflow/$branch_name to develop
        local pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b develop -h "$workflow/$branch_name")
        local pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

        # Calling finish with open unmerged PR should fail
        run git wize-flow "$workflow" finish "$branch_name"
        [ "$status" != "0" ]
        [[ "$output" == *"The PR $pr_num on repository wize-flow-test has not been merged"* ]]

        # This will merge the open PR
        git checkout develop && git merge "$workflow/$branch_name"
        FORCE_PUSH=true git push origin develop

        # Sleep one second to wait for back-end API to sync
        sleep 1

        # Calling finish with merged PR should succeed
        run git wize-flow "$workflow" finish "$branch_name"
        [ "$status" == "0" ]
        [[ "$output" == *"branch '$workflow/$branch_name' was merged into 'develop'"* ]]
        [[ "$output" == *"branch '$workflow/$branch_name' has been locally deleted"* ]]
        [[ "$output" == *"has been remotely deleted from 'origin'"* ]]
        [[ "$output" == *"Congratulations!"* ]]

        # Verifying that the branch was both locally and remotely deleted
        git fetch --prune
        [[ -z "$(git branch -a | grep "$workflow/$branch_name")" ]]

        # Running git wize-flow "$workflow" finish with the same branch name should fail
        git wize-flow "$workflow" start "$branch_name"
        touch "$user_and_hostname-2"
        git add "$user_and_hostname-2"
        git commit -m "touching $user_and_hostname-2"
        git wize-flow publish

        run git wize-flow "$workflow" finish "$branch_name"
        [ "$status" != "0" ]
        [[ "$output" == *"No PR has been created from $workflow/$branch_name to develop on repository wize-flow-test"* ]]

        load common/remote_cleanup

    done
    
}
