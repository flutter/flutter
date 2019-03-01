#!/bin/bash

set -e

cd "$(dirname "$0")"

pushd android
./gradlew buildDebug
popd

# Install the built debug APK to the attached device. We assume only a single attached device.
# -r to replace any existing version of the app.
# -t to allow installation of a "testOnly" app, which this is.
adb install -r -t ./build/app/outputs/apk/debug/app-debug.apk

# Run the installed app on the device.
# This is left commented out for devs that may want to run the app from command line for verification.
#adb shell am start -a android.intent.action.MAIN -n io.flutter.androidembedding/.MainActivity

# Run Espresso test.
pushd android
./gradlew app:connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=io.flutter.androidembedding.TestSuite
popd
