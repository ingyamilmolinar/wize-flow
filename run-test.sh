#!/usr/bin/env bash

#TODO: Add integration tests option

readonly absolute_execution_directory="$(cd "$(dirname $0)" && pwd)"
PATH="$absolute_execution_directory":"$PATH"
case "$1" in
bash)  PATH="$absolute_execution_directory"/src/bash:"$PATH"
       ;;
joker) PATH="$absolute_execution_directory"/src/joker:"$PATH"
       ;;
*)     echo "Implementation required. Run with options <bash|joker>"
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

PATH="$PATH" WIZE_FLOW_IMPLEMENTATION="$1" bats tests/$test_name
