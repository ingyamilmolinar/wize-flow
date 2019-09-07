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

@test "Running 'git wize-flow feature start' should call 'git flow feature start', show banner and return same error code" {
    # Mock 'git flow start' command
    function git() {
        if [[ "$1" == "flow" && "$2" == "feature" && "$3" == "start" && "$4" == "my-feature" ]]; then
            echo "git $1 $2 $3 $4 mock called"
            return 1
        fi
        command git "$@" || return $?
    }
    export -f git
    run git wize-flow feature start my-feature
    [ "$status" = "1" ]
    [[ "$output" == *"mock called"* ]]
    [[ "$output" == *"- WizeFlow -"* ]]

}

@test "Running 'git wize-flow feature start my-feature' should create a branch called feature/my-feature based on top of develop" {
    run git wize-flow feature start my-feature
    [ "$status" = "0" ]
    run git branch
    [ "$status" = "0" ]
    [[ "$output" = *"* feature/my-feature"* ]]
    local -r base_branch="$(git show-branch | grep '\*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')"
    [[ "$base_branch" == "develop" ]]
}

@test "Running 'git wize-flow bugfix|release|hotfix publish' after 'git wize-flow feature start my-feature' should throw an error" {
    run git wize-flow feature start my-feature
    [ "$status" = "0" ]
    for workflow in "bugfix" "release" "hotfix"; do
        run git wize-flow $workflow publish
        [ "$status" != "0" ]
        [[ "$output" == *"The current HEAD is no $workflow branch"* ]]
    done
}

@test "Running 'git wize-flow feature publish my-feature' without a 'feature/my-feature' branch should throw an error" {
    run git wize-flow feature publish my-feature
    [ "$status" != "0" ]
    [[ "$output" == *"feature/my-feature"* ]]
    [[ "$output" == *"does not exist"* ]]
}

#TODO: @test "Running git wize-flow feature finish and doing the entire cycle again (without PR approval and merging) with the same branch name should not work"
