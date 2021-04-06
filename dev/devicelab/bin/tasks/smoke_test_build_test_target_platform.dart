// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/adb.dart';

import 'smoke_test_build_test.dart';

/// Smoke test of a build test task with [deviceOperatingSystem] set. This should
/// only pass in tests run with target platform set to fake.
Future<void> main(List<String> args) async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(FakeBuildTestTask(args));
}
