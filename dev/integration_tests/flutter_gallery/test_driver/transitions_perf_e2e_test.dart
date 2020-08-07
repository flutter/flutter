// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(CareF): avoid the warning message:
//   VMServiceFlutterDriver: request_data message is taking a long time to complete...

import 'dart:async';

import 'package:e2e/e2e_driver.dart' as driver;

Future<void> main() => driver.e2eDriver(
  responseDataCallback: (Map<String, dynamic> data) async {
    await driver.writeResponseData(
      data['performance'] as Map<String, dynamic>,
      testOutputFilename: 'e2e_perf_summary',
    );
  }
);
