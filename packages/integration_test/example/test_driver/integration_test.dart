// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main(List<String> args) async {
  final String testOutputDirectory = getTestOutputDirectory(args);
  integrationDriver(writeResponseOnFailure: true, testOutputDirectory: testOutputDirectory);
}
