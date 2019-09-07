#!/usr/local/env bash

[[ ! -z "$BATS_TMPDIR" && ! -z "$BATS_TEST_NAME" ]] && rm -fr "$BATS_TMPDIR"/"$BATS_TEST_NAME" && mkdir -p "$BATS_TMPDIR"/"$BATS_TEST_NAME" && cd "$BATS_TMPDIR"/"$BATS_TEST_NAME"
