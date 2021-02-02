// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:e2e/e2e_driver.dart' as driver;

Future<void> main() => driver.e2eDriver(
  timeout: const Duration(minutes: 5),
  responseDataCallback: (Map<String, dynamic> data) async {
    await driver.writeResponseData(
      data,
      testOutputFilename: 'scroll_smoothness_test',
    );
  }
);
