// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/microbenchmarks.dart';

/// Runs microbenchmarks on iOS.
Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(createMicrobenchmarkTask());
}
