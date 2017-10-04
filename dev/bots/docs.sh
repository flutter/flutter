#!/bin/bash
set -e

# If you want to run this script locally, make sure you run it from
# the root of the flutter repository.

# This is called from travis_upload.sh on Travis.

# Make sure dart is installed
bin/flutter --version

# Install dartdoc.
bin/cache/dart-sdk/bin/pub global activate dartdoc 0.13.0+3

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc.
(cd dev/tools; ../../bin/cache/dart-sdk/bin/pub get)
FLUTTER_ROOT=$PWD bin/cache/dart-sdk/bin/dart dev/tools/dartdoc.dart
FLUTTER_ROOT=$PWD bin/cache/dart-sdk/bin/dart dev/tools/java_and_objc_doc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis
if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  if [ "$TRAVIS_BRANCH" == "master" -o "$TRAVIS_BRANCH" == "alpha" ]; then
    cd dev/docs

    if [ "$TRAVIS_BRANCH" == "master" ]; then
      echo -e "User-agent: *\nDisallow: /" > doc/robots.txt
      while : ; do
        firebase deploy --project master-docs-flutter-io && break
        echo Error: Unable to deploy documentation to firebase. Retrying in five seconds...
        sleep 5
      done
    fi

    if [ "$TRAVIS_BRANCH" == "alpha" ]; then
      while : ; do
        firebase deploy --project docs-flutter-io && break
        echo Error: Unable to deploy documentation to firebase. Retrying in five seconds...
        sleep 5
      done
    fi
  fi
fi
