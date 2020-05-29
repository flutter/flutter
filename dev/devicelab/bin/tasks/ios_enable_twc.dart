// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/track_widget_creation_enabled_task.dart';

/// Verify that twc can be enabled/disabled on iOS
Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(TrackWidgetCreationEnabledTask().task);
}
