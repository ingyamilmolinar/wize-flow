#!/usr/bin/env bats

setup() {
    skip
    [[ "$INTEGRATION_TESTS" != "true" ]] && load common/mocks
    load common/setup
}

teardown() {
    load common/teardown
}

@test "Running uninstall script with wize-flow-installed should finish succesfully" {
    run wize-flow-uninstall.sh
    [ "$status" == "0" ]
    [[ "$output" == *"Successfully uninstalled wize-flow"* ]]
    #TODO: Verify git-flow-avh and hub dependencies
    #TODO: Verify /usr/local/opt/wize-flow does not exist
    #TODO: Verify git-wize-flow is deleted from /usr/local/bin
}

#TODO: @test "Running uninstall script with wize-flow already uninstalled should throw error"
