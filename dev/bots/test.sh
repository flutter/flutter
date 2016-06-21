#!/bin/bash
set -ex

export PATH="$PWD/bin:$PWD/bin/cache/dart-sdk/bin:$PATH"

die() {
    set +x
    echo "Error: script executed early due to error"
    exit 1
}

# analyze all the Dart code in the repo
flutter analyze --flutter-repo

# verify that the tests actually return failure on failure and success on success
(cd dev/automated_tests; ! flutter test test_smoke_test/fail_test.dart > /dev/null) || die
(cd dev/automated_tests; flutter test test_smoke_test/pass_test.dart > /dev/null) || die

# run tests
(cd packages/flutter; flutter test)
(cd packages/flutter_driver; dart -c test/all.dart)
(cd packages/flutter_sprites; flutter test)
(cd packages/flutter_test; flutter test)
(cd packages/flutter_tools; dart -c test/all.dart)

(cd dev/manual_tests; flutter test)
(cd examples/hello_world; flutter test)
(cd examples/layers; flutter test)
(cd examples/stocks; flutter test)
(cd examples/flutter_gallery; flutter test)

# generate and analyze our large sample app
dart dev/tools/mega_gallery.dart
(cd dev/benchmarks/mega_gallery; flutter analyze --watch --benchmark)
