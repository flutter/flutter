// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e2e/common.dart' as e2e;
import 'package:flutter_driver/flutter_driver.dart';

import 'package:path/path.dart' as path;

Future<void> main() async {
  const Duration timeout = Duration(minutes: 1);
  const String testName = 'frame_policy';

  final FlutterDriver driver = await FlutterDriver.connect();
  String jsonResult;
  jsonResult = await driver.requestData(null, timeout: timeout);
  final e2e.Response response = e2e.Response.fromJson(jsonResult);
  await driver.close();
  final Map<String, dynamic> benchmarkLiveResult =
      response.data['benchmarkLive'] as Map<String,dynamic>;
  final Map<String, dynamic> fullyLiveResult =
      response.data['fullyLive'] as Map<String,dynamic>;

  if (response.allTestsPassed) {
    if(benchmarkLiveResult['frame_count'] as int < 10
       || fullyLiveResult['frame_count'] as int < 10) {
      print('Failure Details:\nNot Enough frames collected:'
            'benchmarkLive ${benchmarkLiveResult['frameCount']},'
            '${fullyLiveResult['frameCount']}.');
      exit(1);
    }
    print('All tests passed.');
    const String destinationDirectory = 'build';
    await fs.directory(destinationDirectory).create(recursive: true);
    final File file = fs.file(path.join(
      destinationDirectory,
      '${testName}_event_delay.json'
    ));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(
      <String, dynamic>{
        'benchmarkLive': benchmarkLiveResult,
        'fullyLive': fullyLiveResult,
      },
    ));
    exit(0);
  } else {
    print('Failure Details:\n${response.formattedFailureDetails}');
    exit(1);
  }
}
