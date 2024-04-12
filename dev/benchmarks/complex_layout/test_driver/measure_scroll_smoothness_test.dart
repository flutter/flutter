// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart' as driver;

Future<void> main(List<String> args) async {
  final String testOutputDirectory = getTestOutputDirectory(args);
  driver.integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data, {String? testOutputDirectory, String? testOutputFilename}) async {
      await driver.writeResponseData(
        data,
        testOutputFilename: 'scroll_smoothness_test',
      );
    },
    testOutputDirectory: testOutputDirectory,
  );
}
