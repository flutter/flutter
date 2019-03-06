// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/tasks/integration_ui.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';

/// End to end tests for Android.
Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(runEndToEndTests);
}
