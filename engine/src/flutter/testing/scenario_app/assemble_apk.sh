#!/bin/bash

"${BASH_SOURCE%/*}/compile_android_aot.sh" $1 $2

pushd "${BASH_SOURCE%/*}/android"
./gradlew assembleDebug --no-daemon
popd
