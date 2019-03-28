#!/bin/bash

set -o pipefail -e;

BUILDROOT_DIR="$(pwd)"
if [[ "$BUILDROOT_DIR" != */src ]]; then
  if [[ "$BUILDROOT_DIR" != */src/* ]]; then
    echo "Unable to determine build root. Exiting."
    exit 1
  fi
  BUILDROOT_DIR="${BUILDROOT_DIR%/src/*}/src"
fi
echo "Using build root: $BUILDROOT_DIR"

OUT_DIR="$BUILDROOT_DIR/out"
HOST_DIR="$OUT_DIR/${1:-host_debug_unopt}"

# Check a Dart SDK has been built.
if [[ ! -d "$HOST_DIR/dart-sdk" ]]; then
  echo "Built Dart SDK not found at $HOST_DIR/dart-sdk. Exiting."
  exit 1
fi

# Switch to buildroot dir. Some tests assume paths relative to buildroot.
cd "$BUILDROOT_DIR"

# TODO(dnfield): Re-enable this when the upstream Dart changes that make it not be flaky land.
# $HOST_DIR/embedder_unittests
echo "Running flow_unittests..."
"$HOST_DIR/flow_unittests"

echo "Running fml_unittests..."
"$HOST_DIR/fml_unittests" --gtest_filter="-*TimeSensitiveTest*"

echo "Running runtime_unittests..."
"$HOST_DIR/runtime_unittests"

echo "Running shell_unittests..."
"$HOST_DIR/shell_unittests"

echo "Running synchronization_unittests..."
"$HOST_DIR/synchronization_unittests"

echo "Running txt_unittests..."
"$HOST_DIR/txt_unittests" --font-directory="$BUILDROOT_DIR/flutter/third_party/txt/third_party/fonts"

# Build flutter/sky/packages.
#
# flutter/testing/dart/pubspec.yaml contains harcoded path deps to
# host_debug_unopt packages.
"$BUILDROOT_DIR/flutter/tools/gn" --unoptimized
ninja -C $OUT_DIR/host_debug_unopt flutter/sky/packages

# Fetch Dart test dependencies.
pushd "$BUILDROOT_DIR/flutter/testing/dart"
"$HOST_DIR/dart-sdk/bin/pub" get
popd

run_test () {
  "$HOST_DIR/dart" $HOST_DIR/gen/frontend_server.dart.snapshot \
      --sdk-root $HOST_DIR/flutter_patched_sdk \
      --incremental \
      --strong \
      --target=flutter \
      --packages flutter/testing/dart/.packages \
      --output-dill $HOST_DIR/engine_test.dill \
      $1

  "$HOST_DIR/flutter_tester" \
      --disable-observatory \
      --use-test-fonts \
      "$HOST_DIR/engine_test.dill"
}

# Verify that a failing test returns a failure code.
! run_test "$BUILDROOT_DIR/flutter/testing/smoke_test_failure/fail_test.dart"

for TEST_SCRIPT in "$BUILDROOT_DIR"/flutter/testing/dart/*.dart; do
  run_test "$TEST_SCRIPT"
done

pushd flutter
ci/test.sh
popd
exit 0
