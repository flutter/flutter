#!/bin/bash

set -ex

out/host_debug_unopt/fxl_unittests
out/host_debug_unopt/synchronization_unittests

flutter/ci/analyze.sh

pushd flutter/testing/dart
pub get
popd

# Verify that a failing test returns a failure code.
! out/host_debug_unopt/flutter_tester --disable-observatory --disable-diagnostic --non-interactive --enable-checked-mode --packages=flutter/testing/dart/.packages flutter/testing/fail_test.dart

for TEST_SCRIPT in flutter/testing/dart/*.dart; do
    out/host_debug_unopt/flutter_tester --disable-observatory --disable-diagnostic --non-interactive --enable-checked-mode --packages=flutter/testing/dart/.packages $TEST_SCRIPT
    out/host_debug_unopt/flutter_tester --disable-observatory --disable-diagnostic --non-interactive --packages=flutter/testing/dart/.packages $TEST_SCRIPT
done

pushd flutter
ci/test.sh
popd
