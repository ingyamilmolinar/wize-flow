#!/usr/bin/env bats

setup() {
    # Unit testing support for feature functionality is missing
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for feature workflow"
    load common/setup
    git wize-flow init "$(pwd)" git@github.com:wizeline/wize-flow-test.git
}

teardown() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && skip "Unit tests are not supported for feature workflow"

    # TODO: Think about concurrency safety (If someone merges to develop before I reset, the final state is undefined)
    git checkout develop && 
    git checkout "$(git log --oneline | tail -n1 | awk '{print $1}')" &&
    git reset --hard &&
    git branch -D develop &&
    git checkout -b develop &&
    FORCE_PUSH=true git push --force origin develop

    git wize-flow remove "$(pwd)"
    load common/teardown 
}

@test "Running 'git wize-flow feature start my-feature' should create a branch called feature/my-feature based on top of develop" {

    run git wize-flow feature start my-feature
    [ "$status" == "0" ]
    [[ "$output" == *"Switched to a new branch 'feature/my-feature'"* ]]
    [[ "$output" == *"Next step: Implement, add and commit"* ]]

    run git branch
    [ "$status" == "0" ]
    [[ "$output" == *"* feature/my-feature"* ]]
    
    local -r base_branch="$(git show-branch | grep '\*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')"
    [[ "$base_branch" == "develop" ]]
}

@test "Running 'git wize-flow bugfix|release|hotfix publish' after 'git wize-flow feature start my-feature' should throw an error" {
    git wize-flow feature start my-feature
    for workflow in "bugfix" "release" "hotfix"; do
        run git wize-flow $workflow publish
        [ "$status" != "0" ]
        [[ "$output" == *"HEAD is no $workflow branch"* ]]
    done
}

@test "Running 'git wize-flow feature publish my-feature' without a 'feature/my-feature' branch should throw an error" {
    run git wize-flow feature publish my-feature
    [ "$status" != "0" ]
    [[ "$output" == *"feature/my-feature"* ]]
    [[ "$output" == *"does not exist"* ]]
}

@test "Running 'git flow feature start' with a repeated branch should throw an error" {
    git wize-flow feature start my-feature
    run git wize-flow feature start my-feature
    [ "$status" != "0" ]
    [[ "$output" == *"Branch 'feature/my-feature' already exists"* ]]
}

@test "Running 'git wize-flow publish' after 'git wize-flow feature start my-feature' should execute successfully" {
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-feature-$user_and_hostname"
    git wize-flow feature start $branch_name
    run git wize-flow publish
    [ "$status" == "0" ]
    [[ "$output" == *"To github.com:wizeline/wize-flow-test.git"* ]]
    [[ "$output" == *"feature/$branch_name -> feature/$branch_name"* ]]
    [[ "$output" == *"Next step: Open PR"* ]]
    git push --delete origin "feature/$branch_name"
}

@test "Running 'git wize-flow finish' after 'git wize-flow feature publish' executed successfully should validate PR" {
    
    local -r user_and_hostname="$(whoami)-$(hostname)"
    local -r branch_name="my-feature-$user_and_hostname"
    git branch -D "feature/$branch_name" || true
    git push --delete origin "feature/$branch_name" || true
    git wize-flow feature start "$branch_name"
    touch "$user_and_hostname"
    git add "$user_and_hostname"
    git commit -m "touching $user_and_hostname"
    
    # Calling finish without publishing should fail 
    run git wize-flow feature finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from feature/$branch_name to develop on repository wize-flow-test"* ]]

    git wize-flow publish

    # Calling finish with published branch but no PR should fail
    run git wize-flow feature finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from feature/$branch_name to develop on repository wize-flow-test"* ]]
    
    # Create PR on github from feature/$branch_name to develop
    local -r pr_link=$(hub pull-request -m "Test PR created by $user_and_hostname" -b develop -h "feature/$branch_name")
    local -r pr_num=$(echo "$pr_link" | grep -Eo '[0-9]+$')

    # Calling finish with open unmerged PR should fail
    run git wize-flow feature finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"The PR $pr_num on repository wize-flow-test has not been merged"* ]]

    # This will merge the open PR
    git checkout develop && git merge "feature/$branch_name"
    FORCE_PUSH=true git push origin develop

    # Calling finish with merged PR should succeed
    run git wize-flow feature finish "$branch_name"
    [ "$status" == "0" ]
    [[ "$output" == *"branch 'feature/$branch_name' was merged into 'develop'"* ]]
    [[ "$output" == *"branch 'feature/$branch_name' has been locally deleted"* ]]
    [[ "$output" == *"has been remotely deleted from 'origin'"* ]]
    [[ "$output" == *"Congratulations!"* ]]

    # Running git wize-flow feature finish with the same branch name should fail
    git wize-flow feature start "$branch_name"
    touch "$user_and_hostname-2"
    git add "$user_and_hostname-2"
    git commit -m "touching $user_and_hostname-2"
    git wize-flow publish

    run git wize-flow feature finish "$branch_name"
    [ "$status" != "0" ]
    [[ "$output" == *"No PR has been created from feature/$branch_name to develop on repository wize-flow-test"* ]]
    git push --delete origin "feature/$branch_name"
    
}
