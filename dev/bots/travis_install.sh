#!/bin/bash
set -ex

if [ -n "$TRAVIS" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  gem install coveralls-lcov
  npm install -g firebase-tools@">=3.0.4 <3.1.0"
fi
