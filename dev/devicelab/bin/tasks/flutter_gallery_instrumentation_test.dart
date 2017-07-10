// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

Future<Null> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;

  await task(() async {
    final Directory galleryDirectory =
      dir('${flutterDirectory.path}/examples/flutter_gallery');
    await inDirectory(galleryDirectory, () async {
      await flutter('packages', options: <String>['get']);
      await flutter('build', options: <String>['clean']);  // to reset the Dart entry point
      await exec('tool/run_instrumentation_test.sh', <String>[]);
    });

    return new TaskResult.success(null);
  });
}
