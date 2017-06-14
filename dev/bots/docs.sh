#!/bin/bash
set -e

# If you want to run this script locally, make sure you run it from
# the root of the flutter repository.

# Make sure dart is installed
bin/flutter --version

# Install dartdoc.
bin/cache/dart-sdk/bin/pub global activate dartdoc 0.12.0

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc.
(cd dev/tools; ../../bin/cache/dart-sdk/bin/pub get)
FLUTTER_ROOT=$PWD bin/cache/dart-sdk/bin/dart dev/tools/dartdoc.dart
FLUTTER_ROOT=$PWD bin/cache/dart-sdk/bin/dart dev/tools/javadoc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis
if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  if [ "$TRAVIS_BRANCH" == "master" -o "$TRAVIS_BRANCH" == "alpha" ]; then
    cd dev/docs

    if [ "$TRAVIS_BRANCH" == "master" ]; then
      echo -e "User-agent: *\nDisallow: /" > doc/robots.txt
      firebase deploy --project master-docs-flutter-io
    fi

    if [ "$TRAVIS_BRANCH" == "alpha" ]; then
      firebase deploy --project docs-flutter-io
    fi

    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      >&2 echo "Error deploying docs via firebase ($exit_code)"
      exit $exit_code
    fi
  fi
fi
