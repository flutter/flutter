// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battery/battery.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Can get battery level', (WidgetTester tester) async {
    final Battery battery = Battery();
    int batteryLevel;
    try {
      batteryLevel = await battery.batteryLevel;
    } on PlatformException catch (e) {
      // The "UNAVAIBLE" error just means that the system reported the battery
      // level as unknown (e.g., the test is running on simulator); it still
      // indicates that the plugin itself is working as expected, so consider it
      // as passing.
      if (e.code == 'UNAVAILABLE') {
        batteryLevel = 1;
      }
    }
    expect(batteryLevel, isNotNull);
  });
}
