#!/bin/bash
set -ex

export PATH="$PWD/bin:$PATH"

# analyze all the Dart code in the repo
flutter analyze --flutter-repo --no-current-directory --no-current-package --congratulate

(cd packages/cassowary; pub run test -j1)
(cd packages/flutter; flutter test)
(cd packages/flutter_sprites; flutter test)
(cd packages/flutter_tools; pub run test)
# (cd packages/flutter_test; ) # No tests to run.
(cd packages/flx; pub run test -j1)
(cd packages/newton; pub run test -j1)
# (cd packages/playfair; ) # No tests to run.
# (cd packages/updater; ) # No tests to run.
(cd packages/flutter_driver; pub run test -j1)

(cd examples/stocks; flutter test)
