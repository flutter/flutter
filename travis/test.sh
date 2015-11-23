#!/bin/bash
set -ex

# analyze all the Dart code in the repo
./bin/flutter analyze --flutter-repo --no-current-directory --no-current-package --congratulate

# flutter package tests
./bin/flutter test --flutter-repo --engine-src-path bin/cache/travis

(cd packages/cassowary; pub run test -j1)
# (cd packages/flutter_sprites; ) # No tests to run.
(cd packages/flutter_tools; pub run test -j1)
(cd packages/flx; pub run test -j1)
(cd packages/newton; pub run test -j1)
# (cd packages/playfair; ) # No tests to run.
# (cd packages/updater; ) # No tests to run.
