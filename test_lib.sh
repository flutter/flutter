#!/bin/bash

run_tests() {
  local folder=$1
  if [ -d "$folder" ]; then
    find "$folder" -type d | while read -r dir; do
      if [ -d "$dir/test" ]; then
        echo "Ran 'flutter test' in: $dir"
        cd "$dir" || exit
        flutter test
        cd - || exit
      fi
    done
  else
    echo "The folder '$folder' did not exist."
  fi
}

run_tests "dev"
run_tests "packages"
