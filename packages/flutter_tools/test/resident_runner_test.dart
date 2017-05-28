// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/context.dart';

class TestRunner extends ResidentRunner {
  TestRunner(List<FlutterDevice> devices)
      : super(devices);

  bool hasHelpBeenPrinted = false;
  String receivedCommand;

  @override
  Future<Null> cleanupAfterSignal() => null;

  @override
  Future<Null> cleanupAtFinish() => null;

  @override
  Future<Null> handleTerminalCommand(String code) async {
    receivedCommand = code;
  }

  @override
  void printHelp({ bool details }) {
    hasHelpBeenPrinted = true;
  }

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<dynamic> appStartedCompleter,
    String route,
    bool shouldBuild: true,
  }) => null;
}

void main() {
  TestRunner testRunner;

  setUp(() {
    testRunner = new TestRunner(
        <FlutterDevice>[new FlutterDevice(new MockDevice())]
    );
  });

  group('keyboard input handling', () {
    testUsingContext('single help character', () async {
      expect(testRunner.hasHelpBeenPrinted, isFalse);
      await testRunner.processTerminalInput('h');
      expect(testRunner.hasHelpBeenPrinted, isTrue);
    });
    testUsingContext('help character surrounded with newlines', () async {
      expect(testRunner.hasHelpBeenPrinted, isFalse);
      await testRunner.processTerminalInput('\nh\n');
      expect(testRunner.hasHelpBeenPrinted, isTrue);
    });
    testUsingContext('reload character with trailing newline', () async {
      expect(testRunner.receivedCommand, isNull);
      await testRunner.processTerminalInput('r\n');
      expect(testRunner.receivedCommand, equals('r'));
    });
    testUsingContext('newlines', () async {
      expect(testRunner.receivedCommand, isNull);
      await testRunner.processTerminalInput('\n\n');
      expect(testRunner.receivedCommand, equals(''));
    });
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}
