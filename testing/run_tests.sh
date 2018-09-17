#!/bin/bash

set -ex

out/host_debug_unopt/fml_unittests
out/host_debug_unopt/synchronization_unittests

pushd flutter/testing/dart
pub get
popd

run_test ()
{
  out/host_debug_unopt/dart out/host_debug_unopt/gen/frontend_server.dart.snapshot --sdk-root out/host_debug_unopt/flutter_patched_sdk --incremental --strong --target=flutter --packages flutter/testing/dart/.packages --output-dill out/host_debug_unopt/engine_test.dill $1

  out/host_debug_unopt/flutter_tester --disable-observatory out/host_debug_unopt/engine_test.dill
}

# Verify that a failing test returns a failure code.
! run_test flutter/testing/fail_test.dart

for TEST_SCRIPT in flutter/testing/dart/*.dart; do
    run_test $TEST_SCRIPT
done

pushd flutter
ci/test.sh
popd
