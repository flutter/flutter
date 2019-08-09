#!/bin/bash

./compile_android_aot.sh $1 $2

pushd android
./gradlew assembleDebug --no-daemon
popd
