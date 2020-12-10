// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';

final Directory codegenAppPath = dir(path.join(flutterDirectory.path, 'dev/integration_tests/codegen'));

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(createCodegenerationIntegrationTest());
}
