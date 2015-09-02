#!/bin/bash
set -ex

# Smoke test sky_shell
./out/sky_shell --help

pushd sky/unit
SKY_SHELL=../../out/sky_shell ../../third_party/dart-sdk/dart-sdk/bin/pub run sky_tools:sky_test -j 1
popd

pushd sky/packages/sky
../../../third_party/dart-sdk/dart-sdk/bin/dartanalyzer lib/widgets.dart
popd
