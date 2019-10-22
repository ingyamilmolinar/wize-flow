#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup skip_install
}

teardown() {
    load common/teardown skip_uninstall 
}


@test "Running install script without implementation should fail" {

    run "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    [ "$status" != "0" ]
    [[ "$output" == *"Unsupported implementation"* ]]
}

@test "Running install script with wize-flow uninstalled should finish succesfully" {

    run "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies
    
    [ "$status" == "0" ]
    [[ "$output" == *"wize-flow was installed successfully"* ]]
    [[ -f "$WIZE_FLOW_TEST_INSTALL/wize-flow/git-wize-flow" ]]
    [[ -d "$WIZE_FLOW_TEST_INSTALL/wize-flow" ]]

    PATH="$WIZE_FLOW_TEST_INSTALL/wize-flow:$PATH"
    WIZE_FLOW_DIR="$WIZE_FLOW_TEST_INSTALL/wize-flow"
    
    run git wize-flow version
    [[ "$output" == *"0.0.0"* ]]
    run command -v git-wize-flow
    [[ "$output" == "$WIZE_FLOW_TEST_INSTALL/wize-flow/git-wize-flow" ]]
}

@test "Running install script without --ignore-dependencies should run brew or apt-get" {
    
    brew() {
        touch DEPENDENCIES_INSTALLED
        return 0
    }
    apt-get() {
        touch DEPENDENCIES_INSTALLED
        return 0
    }
    export -f brew apt-get
    
    run "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL"

    [ "$status" == "0" ]
    [[ -f DEPENDENCIES_INSTALLED ]]

}

@test "Running install script with wize-flow already installed should throw error" {
    
    "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    run $BATS_TEST_DIRNAME/../setup.sh install \
        $WIZE_FLOW_IMPLEMENTATION \
        $WIZE_FLOW_TEST_INSTALL \
        --ignore-dependencies

    [ "$status" != "0" ]
    [[ "$output" == *"Wize-flow has been already installed"* ]]

}

@test "Running install script with --force and wize-flow already installed should succeed" {
    
    "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    run $BATS_TEST_DIRNAME/../setup.sh install \
        $WIZE_FLOW_IMPLEMENTATION \
        $WIZE_FLOW_TEST_INSTALL \
        --ignore-dependencies \
        --force

    [ "$status" == "0" ]
    [[ "$output" == *"wize-flow was installed successfully"* ]]
}
