#!/usr/bin/env bats

setup() {
    skip
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
}

teardown() {
    load common/teardown
}

@test "Running install script with wize-flow-uninstalled should finish succesfully" {
    wize-flow-uninstall.sh
    run wize-flow-install.sh "${WIZE_FLOW_IMPLEMENTATION-bash}"
    [ "$status" == "0" ]
    [[ "$output" == *"Wize-flow was installed successfully"* ]]
    #TODO: Verify git-flow-avh and hub dependencies
    #TODO: Verify all scripts are present under /usr/local/opt/wize-flow
    #TODO: Verify git-wize-flow is available under /usr/local/bin
}

#TODO: @test "Running install script with wize-flow already installed should throw error"
