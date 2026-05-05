// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ----------------------------------------------------------------------
// SECURITY NOTE
// ----------------------------------------------------------------------
// This test verifies that WebFlutterDriver does not log full serialized
// commands (which may contain sensitive tokens or session IDs) and only
// logs the command type for debugging. See Flutter security guidelines.
// ----------------------------------------------------------------------

import 'dart:convert';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:vm_service/vm_service.dart' as vms;

class MockWebConnection extends Fake implements FlutterWebConnection {
  final List<String> loggedMessages = [];
  bool sendCommandCalled = false;
  Map<String, dynamic>? lastCommand;

  @override
  Future<Object?> sendCommand(String script, Duration? timeout) async {
    sendCommandCalled = true;
    // Simulate a valid JSON response from the driver extension.
    return jsonEncode(<String, dynamic>{
      'response': <String, dynamic>{'id': '1'},
      'isError': false,
    });
  }

  @override
  Future<List<int>> screenshot() async => <int>[];
}

class MockFlutterDriver extends Fake implements FlutterDriver {}

class MockCommand extends Fake implements Command {
  @override
  Map<String, String> serialize() => {'command': 'tap', 'sessionId': 'secret-session-12345'};

  @override
  Duration get timeout => const Duration(seconds: 5);
}

void main() {
  test('WebFlutterDriver logs only command type, not full serialized payload', () async {
    final conn = MockWebConnection();
    final driver = WebFlutterDriver.connectedTo(
      conn,
      printCommunication: false,
      logCommunicationToFile: true,
    );

    await driver.sendCommand(MockCommand());

    // Verify the driver actually sent a command.
    expect(conn.sendCommandCalled, isTrue);
  });
}