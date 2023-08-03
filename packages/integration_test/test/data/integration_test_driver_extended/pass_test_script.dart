// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

import 'fake_flutter_web_connection.dart';

void main() {
  group('integrationDriver', () {
    late FakeFlutterWebConnection fakeConnection;
    late WebFlutterDriver driver;
    late bool called = false;

    setUpAll(() {
      fakeConnection = FakeFlutterWebConnection();
      driver = WebFlutterDriver.connectedTo(fakeConnection);
    });

    test('write response data when all test pass', () async {
      fakeConnection.fakeResponse = r'''
{
  "isError": false,
  "response": {
    "message": "{\"result\": \"true\", \"data\": {\"reports\": \"passed\"}}"
  }
}
''';

      await integrationDriver(
        driver: driver,
        responseDataCallback: (_) {
          // We use this print to communicate with ../../integration_test_driver_extended_test.dart
          // ignore: avoid_print
          print('responseDataCallback called');
          called = true;
        },
      );
      expect(called, true);
    });
  });
}
