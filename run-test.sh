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

INTEGRATION_TESTS="$INTEGRATION_TESTS" WIZE_FLOW_IMPLEMENTATION="$1" bats ${test_names[@]}
