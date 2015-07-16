#!/bin/bash -e

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to install SDKs needed to build chromium on android.
# See http://code.google.com/p/chromium/wiki/AndroidBuildInstructions

echo 'checking for sdk packages install'
# Use absolute path to call 'android' so script can be run from any directory.
cwd=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Get the SDK extras packages to install from the DEPS file 'sdkextras' hook.
packages="$(python ${cwd}/get_sdk_extras_packages.py)"
for package in "${packages}"; do
  pkg_id=$(${cwd}/../third_party/android_tools/sdk/tools/android list sdk | \
                grep -i "$package," | \
                awk '/^[ ]*[0-9]*- / {gsub("-",""); print $1}')
  if [[ -n ${pkg_id} ]]; then
    ${cwd}/../third_party/android_tools/sdk/tools/android update sdk --no-ui \
       --filter ${pkg_id}
  fi
done

echo "install-android-sdks.sh complete."
