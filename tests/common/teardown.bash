#!/usr/local/env bash

[[ ! -z "$BATS_TMPDIR" && ! -z "$BATS_TEST_NAME" ]] && rm -fr "$BATS_TMPDIR"/"$BATS_TEST_NAME"

