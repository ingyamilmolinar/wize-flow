#!/usr/local/env bash

if [[ -z "$BATS_TMPDIR" || -z "$BATS_TEST_NAME" ]]; then
    # We should never reach here unless bats-core has an issue
    echo "Fatal error BATS_TMPDIR or BATS_TEST_NAME were empty" 1>&2
    exit 1
fi

WIZE_FLOW_TEST_BASE="$BATS_TMPDIR/$BATS_TEST_NAME"
WIZE_FLOW_TEST_INSTALL="$WIZE_FLOW_TEST_BASE/wize-flow-install"
WIZE_FLOW_TEST_GIT_REPO="$WIZE_FLOW_TEST_BASE/git-repository"

rm -fr "$WIZE_FLOW_TEST_BASE"
mkdir -p "$WIZE_FLOW_TEST_INSTALL"
mkdir -p "$WIZE_FLOW_TEST_GIT_REPO"

if [[ "$2" != "skip_install" ]]; then
    "$BATS_TEST_DIRNAME"/../setup.sh install \
        "$WIZE_FLOW_IMPLEMENTATION" \
        "$WIZE_FLOW_TEST_INSTALL" \
        --ignore-dependencies

    PATH="$WIZE_FLOW_TEST_INSTALL/wize-flow/bin:$PATH"
    WIZE_FLOW_DIR="$WIZE_FLOW_TEST_INSTALL/wize-flow"
fi

# Change directory to where the tests are going to run
cd "$WIZE_FLOW_TEST_GIT_REPO"
