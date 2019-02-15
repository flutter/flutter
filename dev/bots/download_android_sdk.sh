#!/bin/bash

if [[ -z $ANDROID_SDK_TOOLS_URL || -z $ANDROID_HOME || -z $ANDROID_SDK_ROOT ]]; then
  exit 0
fi

curl $ANDROID_SDK_TOOLS_URL --output android_sdk_tools.zip

mkdir
unzip android_sdk_tools.zip -d $ANDROID_SDK_ROOT

yes | $ANDROID_SDK_ROOT/tools/bin/sdkmanager --licenses
$ANDROID_SDK_ROOT/tools/bin/sdkmanager tools
$ANDROID_SDK_ROOT/tools/bin/sdkmanager platform-tools
# this is large and we don't need it just yet
# $ANDROID_SDK_ROOT/tools/bin/sdkmanager emulator
$ANDROID_SDK_ROOT/tools/bin/sdkmanager  "platforms;android-28" \
    "build-tools;28.0.3" \
    "platforms;android-27" \
    "build-tools;27.0.3" \
    "extras;google;m2repository" \
    "extras;android;m2repository"


