#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup skip_install
}

teardown() {
    load common/teardown skip_uninstall
}

@test "Running uninstall script with wize-flow installed should finish succesfully" {

    "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    run "$BATS_TEST_DIRNAME"/../setup.sh uninstall \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow" \
        --ignore-dependencies

    [ "$status" == "0" ]
    [[ "$output" == *"Successfully uninstalled wize-flow"* ]]
    [[ ! -f "$WIZE_FLOW_TEST_INSTALL/wize-flow/git-wize-flow" ]]
    [[ ! -d "$WIZE_FLOW_TEST_INSTALL/wize-flow" ]]
}

@test "Running uninstall script without --ignore-dependencies should run brew or apt-get" {

    brew() { [[ "$1" == "uninstall" ]] && touch DEPENDENCIES_INSTALLED && return 0; }
    apt-get() { [[ "$1" == "remove" ]] && touch DEPENDENCIES_INSTALLED && return 0; }
    yum() { [[ "$1" == "remove" ]] && touch DEPENDENCIES_INSTALLED && return 0; }
    command() { return 0; }
    export -f brew apt-get yum command

    "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    run "$BATS_TEST_DIRNAME"/../setup.sh uninstall \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow"

    [ "$status" == "0" ]
    [[ -f DEPENDENCIES_INSTALLED ]]

}

@test "Running uninstall script with wize-flow already uninstalled should throw error" {
    
    run "$BATS_TEST_DIRNAME"/../setup.sh uninstall \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow" \
        --ignore-dependencies

    [ "$status" != "0" ]
    [[ "$output" == *"$WIZE_FLOW_TEST_INSTALL/wize-flow is not a directory"* ]]

}

@test "Running uninstall script with --force and wize-flow already uninstalled should succeed" {
    
    mkdir "$WIZE_FLOW_TEST_INSTALL/wize-flow"

    run "$BATS_TEST_DIRNAME"/../setup.sh uninstall \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow" \
        --ignore-dependencies \
        --force

    [ "$status" == "0" ]
    [[ "$output" == *"Successfully uninstalled wize-flow"* ]]

}
