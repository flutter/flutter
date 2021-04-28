// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/adb.dart' show DeviceOperatingSystem;
import 'package:flutter_devicelab/framework/framework.dart';
import 'platform_channels_benchmarks.dart' as platform_channels_benchmarks;

Future<void> main() async {
  task(platform_channels_benchmarks.runTask(DeviceOperatingSystem.ios));
}
