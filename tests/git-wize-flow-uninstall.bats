#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup skip_install
}

teardown() {
    load common/teardown skip_uninstall
}

@test "Running uninstall script with wize-flow-installed should finish succesfully" {

    "$BATS_TEST_DIRNAME"/../wize-flow-install.sh \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    run "$BATS_TEST_DIRNAME"/../wize-flow-uninstall.sh \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow" \
        --ignore-dependencies
    [ "$status" == "0" ]
    [[ "$output" == *"Successfully uninstalled wize-flow"* ]]
    [[ ! -f "$WIZE_FLOW_TEST_INSTALL/wize-flow/bin/git-wize-flow" ]]
    [[ ! -d "$WIZE_FLOW_TEST_INSTALL/wize-flow" ]]
}

@test "Running uninstall script with wize-flow already uninstalled should throw error" {
    
    run "$BATS_TEST_DIRNAME"/../wize-flow-uninstall.sh \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow" \
        --ignore-dependencies
    [ "$status" != "0" ]
    [[ "$output" == *"$WIZE_FLOW_TEST_INSTALL/wize-flow is not a directory"* ]]

}
