#!/usr/bin/env bash

main() {

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set -o pipefail

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
        # Hacky way to avoid an unbound error for an empty array.
        # See: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u
        [[ "$i" -gt 0 ]] && test_names=("${test_names[@]+${test_names[@]}}" "$(dirname $0)/tests/$(echo "$arg" | sed 's:tests::' | sed 's:/::g' | sed 's/.bats$//').bats")
        ((i++))
    done 

    [[ "${2-undefined}" == "undefined" ]] && test_names=("$(dirname $0)/tests/*.bats")

    verify_and_set_synchronization_flag
    INTEGRATION_TESTS="$INTEGRATION_TESTS" WIZE_FLOW_IMPLEMENTATION="$1" bats ${test_names[@]}
    remove_synchronization_flag "$?"
}

remote_test_is_running() {
    tags="$(git ls-remote --tags git@github.com:wizeline/wize-flow-test)"
    [[ "$tags" == *"refs/tags/INTEGRATION_TEST_RUNNING"* ]]
}

get_remote_tag_age_in_secs() {
    last_tag_creation_secs="$(git ls-remote --tags git@github.com:wizeline/wize-flow-test | awk '{print $2}' | grep 'INTEGRATION_TEST_RUNNING' | sed 's:refs/tags/INTEGRATION_TEST_RUNNING-::')"
    current_date_secs="$(date +%s)"
    remote_tag_age_in_secs=$(($current_date_secs - $last_tag_creation_secs))
    echo "$remote_tag_age_in_secs"
}

remove_remote_tag() {
    local -r current_dir="$(pwd)"
    [[ ! -d "/tmp/wize-flow-test/.git" ]] && git clone git@github.com:wizeline/wize-flow-test /tmp/wize-flow-test &>/dev/null
    cd /tmp/wize-flow-test
    git push origin --delete "refs/tags/$1" &>/dev/null
    cd "$current_dir"
    rm -fr /tmp/wize-flow-test
}

remove_current_remote_tag() {
    tag_to_delete="$(git ls-remote --tags git@github.com:wizeline/wize-flow-test | awk '{print $2}' | grep 'INTEGRATION_TEST_RUNNING' | sed 's:refs/tags/::')"
    remove_remote_tag "$tag_to_delete" 
}

verify_and_set_synchronization_flag() {
    if [[ "$INTEGRATION_TESTS" == "true" ]]; then 
        # We create a local file for local synchronization and a tag on wize-flow-test master to synchronize remote executions
        if [[ -f ~/.wize-flow.lock ]] || remote_test_is_running; then 
            if [[ -f ~/.wize-flow.lock ]]; then
                echo "Integration test currently running locally. Try again later" 2>&1
                echo "You can manually remove lock by runnning 'rm ~/.wize-flow.lock'" 2>&1
                exit 1
            else
                # Remove tags oldest than 30 minutes
                echo "Remote integration test found. Verifying staleness..."
                remote_tag_age_in_secs="$(get_remote_tag_age_in_secs)"
                echo "Current remote test duration: $remote_tag_age_in_secs seconds"
                [[ $remote_tag_age_in_secs -ge 1800 ]] && remove_current_remote_tag

                #Auto retry logic
                i=0
                while remote_test_is_running; do
                    [[ $i -eq 20 ]] && echo "Retried 20 times every 30 seconds. Exiting..." 2>&1 && exit 1
                    echo "Integration test running remotely. Retrying in 30 seconds..."
                    sleep 30
                    ((i++))
                done
                echo "Remote test finished! I'll try to acquire the lock..."
            fi
        fi

        echo "Acquiring synchronization lock..."
        touch ~/.wize-flow.lock
        trap remove_synchronization_flag INT TERM EXIT

        local -r current_dir="$(pwd)"

        #TODO: We are assuming /tmp/ exists and is writable
        git clone git@github.com:wizeline/wize-flow-test /tmp/wize-flow-test &>/dev/null
        cd /tmp/wize-flow-test

        if ! git push origin origin/master:refs/tags/INTEGRATION_TEST_RUNNING-"$(date +%s)" &>/dev/null; then
            cd "$current_dir"
            rm -fr /tmp/wize-flow-test
            rm -f ~/.wize-flow.lock
            echo "Error occurred while trying to acquire lock. Probably another execution got here first. Try again later" 2>&1
            exit 1
        else
            cd "$current_dir"
        fi
    fi
}

remove_synchronization_flag() {
    [[ "${1-undefined}" != "undefined" ]] && trap '' INT TERM EXIT 
    if [[ "$INTEGRATION_TESTS" == "true" && -f ~/.wize-flow.lock ]]; then
        echo "Releasing synchronization lock..."
        # We remove the created tag on wize-flow-test master to allow for other integration test executions
        if [[ -d /tmp/wize-flow-test ]]; then
            remove_current_remote_tag
        fi
        rm -f ~/.wize-flow.lock
    fi
    exit "${1:-1}"
}

main "$@"
