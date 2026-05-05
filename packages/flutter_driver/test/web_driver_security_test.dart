// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ----------------------------------------------------------------------
// SECURITY NOTE
// ----------------------------------------------------------------------
// This test verifies that WebFlutterDriver does not log full serialized
// command payloads (which may contain sensitive data) and logs only command
// type metadata.
// ----------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/src/common/health.dart';
import 'package:flutter_driver/src/driver/web_driver.dart';
import 'package:webdriver/async_io.dart';
import 'package:test/test.dart';
import 'src/web_tests/web_driver_test.dart' as web_tests;

void main() {
  late web_tests.FakeFlutterWebConnection fakeConnection;
  late WebFlutterDriver driver;

  setUp(() {
    fakeConnection = web_tests.FakeFlutterWebConnection();
    driver = WebFlutterDriver.connectedTo(
      fakeConnection,
      printCommunication: false,
      logCommunicationToFile: true,
    );
    final File logFile = File(driver.logFilePathName);
    if (logFile.existsSync()) {
      logFile.deleteSync();
    }
  });

  test('WebFlutterDriver logs only command type, not full serialized payload', () async {
    fakeConnection.fakeResponse = jsonEncode(<String, dynamic>{
      'isError': false,
      'response': <String, dynamic>{'status': 'ok'},
    });

    await driver.sendCommand(const GetHealth());

    final String log = File(driver.logFilePathName).readAsStringSync();
    expect(log, contains('>>> GetHealth'));
    expect(log, isNot(contains('{"command":"get_health"}')));
    expect(log, isNot(contains('session-id')));
  });
}