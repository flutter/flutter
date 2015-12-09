#!/bin/bash
set -ex

export PATH="$PWD/bin:$PATH"

# analyze all the Dart code in the repo
flutter analyze --flutter-repo --no-current-directory --no-current-package --congratulate

# flutter package tests
flutter test --flutter-repo

(cd packages/cassowary; pub run test -j1)
# (cd packages/flutter_sprites; ) # No tests to run.
(cd packages/flutter_tools; pub run test -j1)
(cd packages/flx; pub run test -j1)
(cd packages/newton; pub run test -j1)
# (cd packages/playfair; ) # No tests to run.
# (cd packages/updater; ) # No tests to run.

(cd examples/stocks; flutter test)

if [ $TRAVIS_PULL_REQUEST = "false" ]; then
  if [ $TRAVIS_BRANCH = "master" ]; then
    (cd packages/flutter; dartdoc)

    GSUTIL=$HOME/google-cloud-sdk/bin/gsutil
    GCLOUD=$HOME/google-cloud-sdk/bin/gcloud
    $GCLOUD auth activate-service-account --key-file gcloud_key_file.json
    $GSUTIL -m rsync -r -d packages/flutter/doc/api gs://docs.domokit.org/flutter
  fi
fi
