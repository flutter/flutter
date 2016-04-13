#!/bin/bash
set -ex

export PATH="$PWD/bin:$PATH"

# analyze all the Dart code in the repo
flutter analyze --flutter-repo --no-current-directory --no-current-package --congratulate

(cd packages/cassowary; dart -c test/all.dart)
(cd packages/flutter; flutter test)
(cd packages/flutter_driver; dart -c test/all.dart)
(cd packages/flutter_sprites; flutter test)
(cd packages/flutter_tools; dart -c test/all.dart)
(cd packages/flx; dart -c test/all.dart)
(cd packages/newton; dart -c test/all.dart)

(cd dev/manual_tests; flutter test)
(cd examples/hello_world; flutter test)
(cd examples/layers; flutter test)
(cd examples/material_gallery; flutter test)
(cd examples/stocks; flutter test)
