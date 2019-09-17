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

case "${2-undefined}" in
    undefined)
        test_name="*.bats"
        ;;
    *)
        test_name="$(echo "$2" | sed 's/.bats$//').bats"
        ;;
esac

INTEGRATION_TESTS="$INTEGRATION_TESTS" WIZE_FLOW_IMPLEMENTATION="$1" bats "$(dirname $0)"/tests/$test_name
