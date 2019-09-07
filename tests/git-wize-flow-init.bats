#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
}

teardown() {
    load common/teardown
}

@test "Running 'git wize-flow init' without an argument should show usage" {
    run git wize-flow init
    [ "$status" != "0" ]
    [[ "$output" == *"usage"* ]]
}

@test "Running 'git wize-flow init' with one missing argument should throw usage" {
    run git wize-flow init /my/path/
    [ "$status" != "0" ]
    [[ "$output" == *"usage"* ]]
}

@test "Running 'git wize-flow init' with an invalid path should throw error" {
    run git wize-flow init /my/path/ git@github.com:wizeline/wize-flow-test.git 
    [ "$status" != "0" ]
    [[ "$output" == *"directory does not exist"* ]]
}

@test "Running 'git wize-flow init' with an invalid github repository should throw error" {
    
    function git() {
        if [[ "$1" == "ls-remote" && "$2" == "git@github.com:fakeorg/fakerepo.git" ]]; then
            return 1
        fi 
        command git "$@"
        return "$?"
    }
    export -f git

    run git wize-flow init "$BATS_TMPDIR"/"$BATS_TEST_NAME" git@github.com:fakeorg/fakerepo.git 

    [ "$status" != "0" ]
    [[ "$output" == *"remote does not exist"* ]]
}

@test "Running 'git wize-flow init' on a new directory with a valid path and repository url should execute succesfully" {
    
    run git wize-flow init "$BATS_TMPDIR"/"$BATS_TEST_NAME" git@github.com:wizeline/wize-flow-test.git 
    
    [ "$status" == "0" ]
    [[ "$output" == *"Successfully initialized wize-flow"* ]]
    [[ "$output" == *"usage:"* ]]
    
    # Verify git-flow was initialized
    run git flow init
    [ "$status" == "0" ]
    [[ "$output" == *"Already initialized for gitflow"* ]]
    
    # Verify gitflow config and wize-flow enabled
    git config -l | grep gitflow > gitflow-config.actual
    cp "$BATS_TEST_DIRNAME"/expected_files/gitflow-config.expected gitflow-config.expected
    sed -i.bak "s:REPLACE_WITH_REPOSITORY_DIRECTORY:$BATS_TMPDIR/$BATS_TEST_NAME/.git/hooks:g" gitflow-config.expected
    
    cat gitflow-config.expected | tr '=' ' ' | awk '{print $1}' | xargs -L 1 -J % git config --get % > tmp.actual
    cat gitflow-config.expected | tr '=' ' ' | awk '{print $2}' > tmp.expected 

    run diff tmp.actual tmp.expected
    [ "$status" == "0" ]
    [[ "$(git config --get wizeflow.enabled | grep yes)" ]]

    # Verify pre-push hook
    run grep 'wizeflow' "$BATS_TMPDIR"/"$BATS_TEST_NAME"/.git/hooks/pre-push
    [ "$status" == "0" ]

}

#TODO: @test "Running 'git wize-flow init' without arguments in an already initialized repository should execute succesfully"

#TODO: @test "Running 'git wize-flow init' on an existing directory with git initialized should execute succesfully"

