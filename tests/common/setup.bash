#!/usr/local/env bash

if [[ -z "$BATS_TMPDIR" || -z "$BATS_TEST_NAME" ]]; then
    # We should never reach here unless bats-core has an issue
    echo "Fatal error BATS_TMPDIR or BATS_TEST_NAME were empty" 1>&2
    exit 1
fi

rm -fr "$BATS_TMPDIR"/"$BATS_TEST_NAME"
mkdir -p "$BATS_TMPDIR"/"$BATS_TEST_NAME"/wize-flow-install
mkdir -p "$BATS_TMPDIR"/"$BATS_TEST_NAME"/git-repository

# Simulate installation on wize-flow-install
# TODO: We could use the same installation script with an optional parameter for custom installation
cp -f "$BATS_TEST_DIRNAME"/../src/common/* "$BATS_TMPDIR"/"$BATS_TEST_NAME"/wize-flow-install
cp -f "$BATS_TEST_DIRNAME"/../src/"$WIZE_FLOW_IMPLEMENTATION"/* "$BATS_TMPDIR"/"$BATS_TEST_NAME"/wize-flow-install
PATH="$BATS_TMPDIR"/"$BATS_TEST_NAME"/wize-flow-install:"$PATH"

# Change directory to where the tests are going to run
cd "$BATS_TMPDIR"/"$BATS_TEST_NAME"/git-repository

echo "# Running tests on directory: $BATS_TMPDIR/$BATS_TEST_NAME/git-repository" >&3
echo "# Running wize-flow from installation directory: $BATS_TMPDIR/$BATS_TEST_NAME/wize-flow-install" >&3
