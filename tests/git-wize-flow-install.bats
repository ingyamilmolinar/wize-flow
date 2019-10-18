#!/usr/bin/env bats

setup() {
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup skip_install
}

teardown() {
    load common/teardown skip_uninstall 
}

@test "Running install script with wize-flow-uninstalled should finish succesfully" {

    run "$BATS_TEST_DIRNAME"/../wize-flow-install.sh \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies
    
    [ "$status" == "0" ]
    [[ "$output" == *"Wize-flow was installed successfully"* ]]
    [[ -f "$WIZE_FLOW_TEST_INSTALL/wize-flow/bin/git-wize-flow" ]]
    [[ -d "$WIZE_FLOW_TEST_INSTALL/wize-flow" ]]

    PATH="$WIZE_FLOW_TEST_INSTALL/wize-flow/bin:$PATH"
    WIZE_FLOW_DIR="$WIZE_FLOW_TEST_INSTALL/wize-flow"
    
    run git wize-flow version
    [[ "$output" == *"0.0.0"* ]]
    run command -v git-wize-flow
    [[ "$output" == "$WIZE_FLOW_TEST_INSTALL/wize-flow/bin/git-wize-flow" ]]
}

@test "Running install script with wize-flow already installed should throw error" {
    
    "$BATS_TEST_DIRNAME"/../wize-flow-install.sh \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    run $BATS_TEST_DIRNAME/../wize-flow-install.sh \
        $WIZE_FLOW_IMPLEMENTATION \
        $WIZE_FLOW_TEST_INSTALL \
        --ignore-dependencies

    [ "$status" != "0" ]
    [[ "$output" == *"Wize-flow has been already installed"* ]]

}
