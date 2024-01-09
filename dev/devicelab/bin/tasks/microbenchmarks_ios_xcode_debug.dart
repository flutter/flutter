// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/microbenchmarks.dart';

/// Runs microbenchmarks on iOS.
Future<void> main() async {
  // XcodeDebug workflow is used for CoreDevices (iOS 17+ and Xcode 15+). Use
  // FORCE_XCODE_DEBUG environment variable to force the use of XcodeDebug
  // workflow in CI to test from older versions since devicelab has not yet been
  // updated to iOS 17 and Xcode 15.
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(createMicrobenchmarkTask(
    environment: <String, String>{
      'FORCE_XCODE_DEBUG': 'true',
    },
  ));
}
