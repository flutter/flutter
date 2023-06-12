#!/usr/bin/env bash

function run_format() {
  output=$(flutter format --set-exit-if-changed -n .)
  if [ $? -eq 1 ]; then
    echo "flutter format issues on"
    echo $output
    exit 1
  fi
}

cd $1 || exit

run_format
