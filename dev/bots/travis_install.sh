#!/bin/bash
set -ex

function retry {
  local total_tries=$1
  local remaining_tries=$total_tries
  shift
  while [ $remaining_tries -gt 0 ]; do
    "$@" && break
    remaining_tries=$(($remaining_tries - 1))
    sleep 5
  done

  [ $remaining_tries -eq 0 ] && {
    echo "Command still failed after $total_tries tries: $@"
    return 1
  }
  return 0
}

if [ -n "$TRAVIS" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  gem install coveralls-lcov
  gem install bundler
  retry 5 npm install -g firebase-tools@">=3.6.1 <3.7.0"
fi
