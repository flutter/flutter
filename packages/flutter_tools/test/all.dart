// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(devoncarew): These `all.dart` test files are here to work around
// https://github.com/dart-lang/test/issues/327; the `test` package currently
// doesn't support running without symlinks. We can delete these files once that
// fix lands.

import 'package:flutter_tools/src/cache.dart';

import 'adb_test.dart' as adb_test;
import 'analytics_test.dart' as analytics_test;
import 'analyze_duplicate_names_test.dart' as analyze_duplicate_names_test;
import 'analyze_test.dart' as analyze_test;
import 'android_device_test.dart' as android_device_test;
import 'android_sdk_test.dart' as android_sdk_test;
import 'application_package_test.dart' as application_package_test;
import 'base_utils_test.dart' as base_utils_test;
import 'channel_test.dart' as channel_test;
import 'config_test.dart' as config_test;
import 'context_test.dart' as context_test;
import 'create_test.dart' as create_test;
import 'daemon_test.dart' as daemon_test;
import 'devfs_test.dart' as devfs_test;
import 'device_test.dart' as device_test;
import 'devices_test.dart' as devices_test;
import 'drive_test.dart' as drive_test;
import 'format_test.dart' as format_test;
import 'install_test.dart' as install_test;
import 'logs_test.dart' as logs_test;
import 'os_utils_test.dart' as os_utils_test;
import 'packages_test.dart' as packages_test;
import 'protocol_discovery_test.dart' as protocol_discovery_test;
import 'run_test.dart' as run_test;
import 'stop_test.dart' as stop_test;
import 'test_test.dart' as test_test;
import 'toolchain_test.dart' as toolchain_test;
import 'trace_test.dart' as trace_test;
import 'upgrade_test.dart' as upgrade_test;
import 'utils_test.dart' as utils_test;

void main() {
  Cache.disableLocking();
  adb_test.main();
  analytics_test.main();
  analyze_duplicate_names_test.main();
  analyze_test.main();
  android_device_test.main();
  android_sdk_test.main();
  application_package_test.main();
  base_utils_test.main();
  channel_test.main();
  config_test.main();
  context_test.main();
  create_test.main();
  daemon_test.main();
  devfs_test.main();
  device_test.main();
  devices_test.main();
  drive_test.main();
  format_test.main();
  install_test.main();
  logs_test.main();
  os_utils_test.main();
  packages_test.main();
  protocol_discovery_test.main();
  run_test.main();
  stop_test.main();
  test_test.main();
  toolchain_test.main();
  trace_test.main();
  upgrade_test.main();
  utils_test.main();
}
