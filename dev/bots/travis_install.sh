#!/bin/bash
set -ex

if [ -n "$TRAVIS" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  gem install coveralls-lcov
  gem install bundler
  npm install -g firebase-tools@">=3.6.1 <3.7.0"
fi
