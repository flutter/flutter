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

    # TODO(eseidel): This should just call a helper script.
    # If you add a package to this list, update doc/index.html to point to it.
    (cd packages/flutter; ~/.pub-cache/bin/dartdoc --header=/tmp/_header.html)
    (cd packages/playfair; ~/.pub-cache/bin/dartdoc --header=/tmp/_header.html)
    (cd packages/newton; ~/.pub-cache/bin/dartdoc --header=/tmp/_header.html)
    (cd packages/cassowary; ~/.pub-cache/bin/dartdoc --header=/tmp/_header.html)
    (cd packages/flutter_test; ~/.pub-cache/bin/dartdoc --header=/tmp/_header.html)

    GSUTIL=$HOME/google-cloud-sdk/bin/gsutil
    GCLOUD=$HOME/google-cloud-sdk/bin/gcloud
    $GCLOUD auth activate-service-account --key-file gcloud_key_file.json
    $GSUTIL -m -q cp doc/index.html gs://docs.flutter.io/index.html

    $GSUTIL -m -q rsync -r -d packages/flutter/doc/api gs://docs.flutter.io/flutter
    $GSUTIL -m -q rsync -r -d packages/playfair/doc/api gs://docs.flutter.io/playfair
    $GSUTIL -m -q rsync -r -d packages/newton/doc/api gs://docs.flutter.io/newton
    $GSUTIL -m -q rsync -r -d packages/cassowary/doc/api gs://docs.flutter.io/cassowary
    $GSUTIL -m -q rsync -r -d packages/flutter_test/doc/api gs://docs.flutter.io/flutter_test
  fi
fi
