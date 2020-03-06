// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();

  // TODO(nurhan): https://github.com/flutter/flutter/issues/51940
  final String dataRequest =
      await driver.requestData(null, timeout: const Duration(seconds: 1));
  print('result $dataRequest');
  await driver.close();

  exit(dataRequest == 'pass' ? 0 : 1);
}
