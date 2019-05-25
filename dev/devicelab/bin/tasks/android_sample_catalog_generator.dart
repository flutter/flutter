// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/sample_catalog_generator.dart';

Future<void> main(List<String> args) async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(() => samplePageCatalogGenerator(extractCloudAuthTokenArg(args)));
}
