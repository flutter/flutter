#!/bin/bash
set -e

# Install dartdoc.
# We peg to this version to work around a bug affecting Flutter in 0.9.7+2.
pub global activate dartdoc 0.9.7+1

# Generate flutter docs into dev/docs/doc/api/.
(cd dev/tools; pub get)

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc
FLUTTER_ROOT=$PWD dart dev/tools/dartdoc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis and branch is master

if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  if [ "$TRAVIS_BRANCH" = "master" ]; then
    cd dev/docs
    firebase deploy --project docs-flutter-io
  fi
fi
