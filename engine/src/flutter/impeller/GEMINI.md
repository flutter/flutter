# Impeller

This directory contains Flutter's graphics renderer, Impeller.

## Development operations

### Unit testing

Running all unit tests can take over 10 minutes. It's best to run a subset of
tests while developing, then verify all tests at the end.

#### Building and running unit-tests

```shell
../bin/et build -c host_debug_unopt_arm64 \
  //flutter/impeller:impeller_unittests
../../out/host_debug_unopt_arm64/impeller_unittests
```

#### Running a specific unit test

```shell
../../out/host_debug_unopt_arm64/impeller_unittests \
  --gtest_filter="SizeTest.SizeIsEmpty"
```

#### List unit-tests

```shell
../../out/host_debug_unopt_arm64/impeller_unittests --gtest_list_tests
```

### Golden testing

The executable for golden testing is `impeller_golden_tests`.  The CWD must be
the parent directory of `impeller_golden_tests` when executing it in order for
the dyld to resolve successfully.

The golden tests are currently only supported on macOS.

#### Build/run/examine golden test

This example assumes macOS with an arm64 processor.

```shell
../bin/et build -c host_debug_unopt_arm64 \
  //flutter/impeller/golden_tests:impeller_golden_tests
mkdir -p ~/Desktop/impeller_unit_tests
pushd $PWD
cd ../../out/host_debug_unopt_arm64
./impeller_golden_tests \
  --working_dir=~/Desktop/impeller_unit_tests \
  --gtest_filter="Play/AiksTest.CanPerformSkew/Metal"
popd
open ~/Desktop/impeller_unit_tests/impeller_Play_AiksTest_CanPerformSkew_Metal.png
```

#### List golden tests

```shell
pushd $PWD
cd ../../out/host_debug_unopt_arm64
./impeller_golden_tests --working_dir=. --gtest_list_tests
popd
```
