// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart' as driver;

Future<void> main(List<String> args) async {
  final String testOutputDirectory = getTestOutputDirectory(args);
  driver.integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data, {String? testOutputDirectory, String? testOutputFilename}) async {
      final Map<String, dynamic> benchmarkLiveResult =
          data?['benchmarkLive'] as Map<String,dynamic>;
      final Map<String, dynamic> fullyLiveResult =
          data?['fullyLive'] as Map<String,dynamic>;

      if (benchmarkLiveResult['frame_count'] as int < 10
         || fullyLiveResult['frame_count'] as int < 10) {
        print('Failure Details:\nNot Enough frames collected: '
              'benchmarkLive ${benchmarkLiveResult['frameCount']}, '
              '${fullyLiveResult['frameCount']}.');
        exit(1);
      }
      await driver.writeResponseData(
        <String, dynamic>{
          'benchmarkLive': benchmarkLiveResult,
          'fullyLive': fullyLiveResult,
        },
        testOutputFilename: 'frame_policy_event_delay',
      );
   },
  testOutputDirectory: testOutputDirectory,
  );
}
