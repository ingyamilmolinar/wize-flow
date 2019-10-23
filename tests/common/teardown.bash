#!/usr/local/env bash

if [[ -z "$BATS_TMPDIR" || -z "$BATS_TEST_NAME" ]]; then
    # We should never reach here unless bats-core has an issue
    echo "Fatal error BATS_TMPDIR or BATS_TEST_NAME was empty" 1>&2
    exit 1
fi

if [[ "$2" != "skip_uninstall" ]]; then
    "$BATS_TEST_DIRNAME"/../setup.sh uninstall \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL/wize-flow" \
        --ignore-dependencies
fi
rm -fr "$WIZE_FLOW_TEST_BASE"
