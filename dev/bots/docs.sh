#!/bin/bash
set -e

echo "Running docs.sh"

# If you want to run this script locally, make sure you run it from
# the root of the flutter repository.
export FLUTTER_ROOT="$PWD"

# This is called from travis_upload.sh on Travis.

# Make sure dart is installed
bin/flutter --version

# If the pub cache directory exists in the root, then use that.
FLUTTER_PUB_CACHE="$FLUTTER_ROOT/.pub-cache"
if [ -d "$FLUTTER_PUB_CACHE" ]; then
  # This has to be exported, because pub interprets setting it
  # to the empty string in the same way as setting it to ".".
  export PUB_CACHE="${PUB_CACHE:-"$FLUTTER_PUB_CACHE"}"
fi

# Install dartdoc.
bin/cache/dart-sdk/bin/pub global activate dartdoc 0.17.1+1

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc.
(cd dev/tools; ../../bin/cache/dart-sdk/bin/pub get)
bin/cache/dart-sdk/bin/dart dev/tools/dartdoc.dart
bin/cache/dart-sdk/bin/dart dev/tools/java_and_objc_doc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis
if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo "This is not a pull request; considering whether to upload docs... (branch=$TRAVIS_BRANCH)"
  if [ "$TRAVIS_BRANCH" == "master" -o "$TRAVIS_BRANCH" == "beta" ]; then
    cd dev/docs

    if [ "$TRAVIS_BRANCH" == "master" ]; then
      echo "Updating master docs: https://master-docs-flutter-io.firebaseapp.com/"
      echo -e "User-agent: *\nDisallow: /" > doc/robots.txt
      while : ; do
        firebase deploy --project master-docs-flutter-io && break
        echo Error: Unable to deploy documentation to firebase. Retrying in five seconds...
        sleep 5
      done
    fi

    if [ "$TRAVIS_BRANCH" == "beta" ]; then
      echo "Updating beta docs: https://docs.flutter.io/"
      while : ; do
        firebase deploy --project docs-flutter-io && break
        echo Error: Unable to deploy documentation to firebase. Retrying in five seconds...
        sleep 5
      done
    fi
  fi
fi
