#!/bin/bash

run_pub_get() {
  local folder=$1
  if [ -d "$folder" ]; then
    find "$folder" -type d | while read -r dir; do
      if [ -f "$dir/pubspec.yaml" ]; then
        echo "Ran 'flutter pub get' in: $dir"
        cd "$dir" || exit
        flutter pub get
        cd - || exit
      fi
    done
  else
    echo "The folder '$folder' did not exist."
  fi
}

run_pub_get "dev"
run_pub_get "packages"
