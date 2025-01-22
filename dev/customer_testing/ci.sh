#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This should match the ci.bat file in this directory.

# This is called from the LUCI recipes:
# https://github.com/flutter/flutter/blob/main/dev/bots/suite_runners/run_customer_testing_tests.dart

set -e

# This script does not assume that "flutter update-packages" has been
# run, to allow CIs to save time by skipping that steps since it's
# largely not needed to run the flutter/tests tests.
#
# However, we do need to update this directory.
dart pub get

function script_location() {
  local script_location="${BASH_SOURCE[0]}"
  # Resolve symlinks
  while [[ -h "$script_location" ]]; do
    DIR="$(cd -P "$( dirname "$script_location")" >/dev/null && pwd)"
    script_location="$(readlink "$script_location")"
    [[ "$script_location" != /* ]] && script_location="$DIR/$script_location"
  done
  cd -P "$(dirname "$script_location")" >/dev/null && pwd
}

# So that users can run this script from anywhere and it will work as expected.
SCRIPT_LOCATION="$(script_location)"
FLUTTER_ROOT="$(dirname "$(dirname "$SCRIPT_LOCATION")")"

# Next we need to update the flutter/tests checkout.
#
# We use the SHA listed in the sibling file "tests.version" so that upstream
# changes to flutter/tests do not turn the flutter/flutter tree red, and instead
# require an atomic update (of the SHA listed in "tests.version").
#
# See https://github.com/flutter/flutter/issues/162041.

# Read the SHA from the file "tests.version"
tests_sha=$(cat $SCRIPT_LOCATION/tests.version)
echo "Running tests @ flutter/tests $tests_sha"

# Clone the flutter/tests repository and checkout the provided SHA
git clone --depth 1 https://github.com/flutter/tests.git $FLUTTER_ROOT/bin/cache/pkg/tests
git -C $FLUTTER_ROOT/bin/cache/pkg/tests checkout $tests_sha

# Run the tests
set -ex
dart --enable-asserts $SCRIPT_LOCATION/run_tests.dart --skip-on-fetch-failure --skip-template $FLUTTER_ROOT/bin/cache/pkg/tests/registry/*.test
