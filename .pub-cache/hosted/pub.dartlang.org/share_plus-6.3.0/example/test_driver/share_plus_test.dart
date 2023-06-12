// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final data =
      await driver.requestData(null, timeout: const Duration(minutes: 1));
  await driver.close();
  final Map<String, dynamic> result = jsonDecode(data);
  exit(result['result'] == 'true' ? 0 : 1);
}
