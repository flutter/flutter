// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'android_device_test.dart' as android_device_test;
import 'daemon_test.dart' as daemon_test;
import 'init_test.dart' as init_test;
import 'install_test.dart' as install_test;
import 'listen_test.dart' as listen_test;
import 'list_test.dart' as list_test;
import 'logs_test.dart' as logs_test;
import 'os_utils_test.dart' as os_utils_test;
import 'start_test.dart' as start_test;
import 'stop_test.dart' as stop_test;
import 'trace_test.dart' as trace_test;

main() {
  android_device_test.defineTests();
  daemon_test.defineTests();
  init_test.defineTests();
  install_test.defineTests();
  listen_test.defineTests();
  list_test.defineTests();
  logs_test.defineTests();
  os_utils_test.defineTests();
  start_test.defineTests();
  stop_test.defineTests();
  trace_test.defineTests();
}
