#!/usr/bin/env bash

case "$1" in
bash)  echo "bash"
       ;;
joker) export PATH=./src/joker:$PATH
       ;;
*)     echo "Run with option <bash|joker>"
       exit -1
       ;;
esac

bats tests/* 
