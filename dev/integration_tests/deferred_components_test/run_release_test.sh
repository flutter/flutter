#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage:
#
#   ./run_release_test.sh <bundletool.jar path> <adb path>
#
# In CI, this script currently depends on a modified version of bundletool because
# ddmlib which bundletool depends on does not yet support detecting QEMU emulator device
# density system properties. See https://android.googlesource.com/platform/tools/base/+/refs/heads/master/ddmlib/src/main/java/com/android/ddmlib/IDevice.java#46
#
# The modified bundletool which waives the density requirement is at:
# https://chrome-infra-packages.appspot.com/p/flutter/android/bundletool/+/vFt1jA0cUeZLmUCVR5NG2JVB-SgJ18GH_pVYKMOlfUIC

bundletool_jar_path=$1
adb_path=$2

# Store the time to prevent capturing logs from previous runs.
script_start_time=$($adb_path shell 'date +"%m-%d %H:%M:%S.0"')

$adb_path uninstall "io.flutter.integration.deferred_components_test"

rm -f build/app/outputs/bundle/release/app-release.apks
rm -f build/app/outputs/bundle/release/run_logcat.log

flutter build appbundle

java -jar $bundletool_jar_path build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=build/app/outputs/bundle/release/app-release.apks --local-testing --ks android/testing-keystore.jks --ks-key-alias testing_key --ks-pass pass:012345
java -jar $bundletool_jar_path install-apks --apks=build/app/outputs/bundle/release/app-release.apks

$adb_path shell "
am start -n io.flutter.integration.deferred_components_test/.MainActivity
exit
"
run_start_time_seconds=$(date +%s)
while read LOGLINE
do
    if [[ "${LOGLINE}" == *"Running deferred code"* ]]; then
        echo "Found ${LOGLINE}"
        echo "All tests passed."
        pkill -P $$
        exit 0
    fi
    # Timeout if expected log not found
    current_time=$(date +%s)
    if [[ $((current_time - run_start_time_seconds)) -ge 300 ]]; then
        echo "Failure: Timed out, deferred component did not load."
        pkill -P $$
        exit 1
    fi
done < <($adb_path logcat -T "$script_start_time")

echo "Failure: Deferred component did not load."
exit 1
