#!/bin/bash
set -e

# If you want to run this script locally, make sure you run it from
# the root of the flutter repository.

# Install dartdoc.
pub global activate dartdoc 0.11.1

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc.
(cd dev/tools; pub get)
FLUTTER_ROOT=$PWD dart dev/tools/dartdoc.dart
FLUTTER_ROOT=$PWD dart dev/tools/javadoc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis and branch is master.
if [ "$TRAVIS_PULL_REQUEST" = "false" ] && [ "$TRAVIS_BRANCH" = "master" ]; then
  cd dev/docs
  firebase deploy --project docs-flutter-io
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
      >&2 echo "Error deploying docs via firebase ($exit_code)"
      exit $exit_code
  fi
fi
