// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

void main() {
  task(() async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir =
        dir(path.join(flutterDirectory.path, 'dev/devicelab/test_apps/import_test_app'));
    await inDirectory(appDir, () async {
      return await flutter('run',
          options: <String>['--hot', '-d', device.deviceId, '--benchmark', '--verbose'],
          canFail: false);
    });
    return new TaskResult.success(null);
  });
}
