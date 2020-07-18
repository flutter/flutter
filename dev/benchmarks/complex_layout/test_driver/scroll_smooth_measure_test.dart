// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

// TODO(CareF): replace the following part after flutter/plugins#2859 is landed

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e2e/common.dart' as e2e;
import 'package:flutter_driver/flutter_driver.dart';

import 'package:path/path.dart' as path;

const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');
String testOutputsDirectory = Platform.environment['FLUTTER_TEST_OUTPUTS_DIR'] ?? 'build';
String testOutputFilename = 'scroll_smoothness_test';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  final String jsonResult =
      await driver.requestData(null, timeout: const Duration(minutes: 1));
  final e2e.Response response = e2e.Response.fromJson(jsonResult);
  await driver.close();

  if (response.allTestsPassed) {
    print('All tests passed.');

    await fs.directory(testOutputsDirectory).create(recursive: true);
    final File file = fs.file(path.join(
      testOutputsDirectory,
      '$testOutputFilename.json'
    ));
    await file.writeAsString(_encodeJson(response.data, true));

    exit(0);
  } else {
    print('Failure Details:\n${response.formattedFailureDetails}');
    exit(1);
  }
}

String _encodeJson(Map<String, dynamic> jsonObject, bool pretty) {
  return pretty
    ? _prettyEncoder.convert(jsonObject)
    : json.encode(jsonObject);
}
