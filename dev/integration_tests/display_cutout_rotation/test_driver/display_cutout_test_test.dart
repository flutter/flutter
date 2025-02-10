// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  print('Starting test.');
  try {
    final FlutterDriver driver = await FlutterDriver.connect();
    final String data = await driver.requestData(null, timeout: const Duration(minutes: 1));
    await driver.close();
    final Map<String, dynamic> result = jsonDecode(data) as Map<String, dynamic>;
    print(result);
    exitCode = result['result'] == 'true' ? 0 : 1;
  } catch (e, st) {
    print('Driver Error: $e');
    print('Stacktrace: $st');
    exitCode = 1;
  }
  return;
}
