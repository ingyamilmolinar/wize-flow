#!/usr/bin/env bash

readonly absolute_execution_directory="$(cd "$(dirname $0)" && pwd)"
PATH="$absolute_execution_directory":"$PATH"
case "$1" in
    bash)
            PATH="$absolute_execution_directory"/src/bash:"$PATH"
            ;;
    joker)
            # We only support unit tests on BASH
            INTEGRATION_TESTS="true"
            PATH="$absolute_execution_directory"/src/joker:"$PATH"
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

PATH="$PATH" INTEGRATION_TESTS="${INTEGRATION_TESTS-false}" WIZE_FLOW_IMPLEMENTATION="$1" bats tests/$test_name
