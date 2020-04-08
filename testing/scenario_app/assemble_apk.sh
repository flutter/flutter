#!/bin/bash

set -e

pushd "${BASH_SOURCE%/*}/../../.."
  ./flutter/tools/gn --unopt
  ninja -C out/host_debug_unopt sky_engine sky_services
popd

pushd "${BASH_SOURCE%/*}"
  ./compile_android_aot.sh "$1" "$2"
popd

pushd "${BASH_SOURCE%/*}/android"
./gradlew assembleDebug --no-daemon
popd
