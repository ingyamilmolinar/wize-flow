#!/usr/local/env bash

if [[ -z "$BATS_TMPDIR" || -z "$BATS_TEST_NAME" ]]; then
    # We should never reach here unless bats-core has an issue
    echo "Fatal error BATS_TMPDIR or BATS_TEST_NAME was empty" 1>&2
    exit 1
fi

rm -fr "$BATS_TMPDIR"/"$BATS_TEST_NAME"
