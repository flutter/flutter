#!/bin/bash
set -ex

export PATH="$PWD/bin:$PATH"

# analyze all the Dart code in the repo
flutter analyze --flutter-repo --no-current-directory --no-current-package --congratulate

(cd packages/cassowary; pub run test -j1)
(cd packages/flutter; flutter test)
# (cd packages/flutter_sprites; ) # No tests to run.
(cd packages/flutter_tools; pub run test -j1)
# (cd packages/flutter_test; ) # No tests to run.
(cd packages/flx; pub run test -j1)
(cd packages/newton; pub run test -j1)
# (cd packages/playfair; ) # No tests to run.
# (cd packages/updater; ) # No tests to run.

(cd examples/stocks; flutter test)

if [ $TRAVIS_PULL_REQUEST = "false" ]; then
  if [ $TRAVIS_BRANCH = "master" ]; then
    pub global activate dartdoc 0.8.4
    cat packages/flutter/doc/styles.html doc/_analytics.html > /tmp/_header.html
    (cd packages/flutter; ~/.pub-cache/bin/dartdoc --header=/tmp/_header.html)

    GSUTIL=$HOME/google-cloud-sdk/bin/gsutil
    GCLOUD=$HOME/google-cloud-sdk/bin/gcloud
    $GCLOUD auth activate-service-account --key-file gcloud_key_file.json
    $GSUTIL -m -q rsync -r -d packages/flutter/doc/api gs://docs.flutter.io/flutter
    $GSUTIL -m -q rsync -r -d packages/flutter/doc/api gs://docs.domokit.org/flutter
    $GSUTIL -m -q cp doc/index.html gs://docs.flutter.io/index.html
    $GSUTIL -m -q cp doc/index.html gs://docs.domokit.org/index.html
  fi
fi
