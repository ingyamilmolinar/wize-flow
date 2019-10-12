#!/usr/bin/env bash

case "$1" in
    bash)
            # Default for bash is unit tests
            INTEGRATION_TESTS="${INTEGRATION_TESTS-false}"
            ;;
    joker)
            # We only support unit tests on BASH
            INTEGRATION_TESTS="true"
            ;;
    *)
            echo "Implementation required. Run with options <bash|joker>"
            exit -1
            ;;
esac

i=0
test_names=()
for arg in "$@"; do
    [[ "$i" -gt 0 ]] && test_names=("${test_names[@]}" "$(dirname $0)/tests/$(echo "$arg" | sed 's:tests::' | sed 's:/::g' | sed 's/.bats$//').bats")
    ((i++))
done 

[[ "${2-undefined}" == "undefined" ]] && test_names=("$(dirname $0)/tests/*.bats")

verify_and_set_synchronization_flag() {
    if [[ "$INTEGRATION_TESTS" == "true" ]]; then 
        # We create a local file for local synchronization and a tag on wize-flow-test master to synchronize remote executions
        if [[ -f ~/.wize-flow.lock || "$(git ls-remote git@github.com:wizeline/wize-flow-test)" == *"refs/tags/INTEGRATION_TEST_RUNNING"* ]]; then 
            echo "Integration test currently running. Try again later" 2>&1
            exit 1
        else
            echo "Acquiring synchronization lock..."
            touch ~/.wize-flow.lock
            trap remove_synchronization_flag INT

            local -r current_dir="$(pwd)"

            #TODO: We are assuming /tmp/ exists and is writable
            git clone git@github.com:wizeline/wize-flow-test /tmp/wize-flow-test &>/dev/null
            cd /tmp/wize-flow-test

            if ! git push origin origin/master:refs/tags/INTEGRATION_TEST_RUNNING &>/dev/null; then
                cd "$current_dir"
                rm -fr /tmp/wize-flow-test
                rm -f ~/.wize-flow.lock
                echo "Error occurred while trying to acquire lock. Probably another execution got here first. Try again later" 2>&1
                exit 1
            else
                cd "$current_dir"
            fi
        fi
    fi
}

remove_synchronization_flag() {
    if [[ "$INTEGRATION_TESTS" == "true" && -f ~/.wize-flow.lock ]]; then
        echo "Releasing synchronization lock..."
        # We remove the created tag on wize-flow-test master to allow for other integration test executions
        local -r current_dir="$(pwd)"
        cd /tmp/wize-flow-test
        git push origin --delete refs/tags/INTEGRATION_TEST_RUNNING &>/dev/null
        cd "$current_dir"
        rm -fr /tmp/wize-flow-test
        rm -f ~/.wize-flow.lock
    fi
}

verify_and_set_synchronization_flag
INTEGRATION_TESTS="$INTEGRATION_TESTS" WIZE_FLOW_IMPLEMENTATION="$1" bats ${test_names[@]}
remove_synchronization_flag
