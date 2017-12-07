// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<Null> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  final Directory iosDirectory = dir(
    '${flutterDirectory.path}/examples/flutter_view/ios',
  );
  final Stopwatch stopwatch = new Stopwatch()..start();
  await inDirectory(iosDirectory, () async {
    await exec('pod', <String>['install']);
  });

  print('pod install executed in ${stopwatch.elapsed}');
  await task(createFlutterViewStartupTest());
}
