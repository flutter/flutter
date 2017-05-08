// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/commands/doctor.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:mockito/mockito.dart';
import 'package:quiver/time.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('analytics', () {
    Directory temp;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      Cache.flutterRoot = '../..';
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Ensure we don't send anything when analytics is disabled.
    testUsingContext('doesn\'t send when disabled', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      flutterUsage.enabled = false;
      await createProject(temp);
      expect(count, 0);

      flutterUsage.enabled = true;
      await createProject(temp);
      expect(count, flutterUsage.isFirstRun ? 0 : 2);

      count = 0;
      flutterUsage.enabled = false;
      final DoctorCommand doctorCommand = new DoctorCommand();
      final CommandRunner<Null>runner = createTestCommandRunner(doctorCommand);
      await runner.run(<String>['doctor']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => new Usage(),
    });

    // Ensure we don't send for the 'flutter config' command.
    testUsingContext('config doesn\'t send', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      flutterUsage.enabled = false;
      final ConfigCommand command = new ConfigCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['config']);
      expect(count, 0);

      flutterUsage.enabled = true;
      await runner.run(<String>['config']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => new Usage(),
    });
  });

  group('analytics with mocks', () {
    Usage mockUsage;
    Clock mockClock;
    Doctor mockDoctor;
    List<int> mockTimes;

    setUp(() {
      mockUsage = new MockUsage();
      when(mockUsage.isFirstRun).thenReturn(false);
      mockClock = new MockClock();
      mockDoctor = new MockDoctor();
      when(mockClock.now()).thenAnswer(
        (Invocation _) => new DateTime.fromMillisecondsSinceEpoch(mockTimes.removeAt(0))
      );
    });

    testUsingContext('flutter commands send timing events', () async {
      mockTimes = <int>[1000, 2000];
      when(mockDoctor.diagnose()).thenReturn(true);
      final DoctorCommand command = new DoctorCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['doctor']);

      verify(mockClock.now()).called(2);

      expect(
        verify(mockUsage.sendTiming(captureAny, captureAny, captureAny, label: captureAny)).captured, 
        <dynamic>['flutter', 'doctor', const Duration(milliseconds: 1000), 'success']
      );
    }, overrides: <Type, Generator>{
      Clock: () => mockClock,
      Doctor: () => mockDoctor,
      Usage: () => mockUsage,
    });

    testUsingContext('doctor fail sends warning', () async {
      mockTimes = <int>[1000, 2000];
      when(mockDoctor.diagnose()).thenReturn(false);
      final DoctorCommand command = new DoctorCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['doctor']);

      verify(mockClock.now()).called(2);

      expect(
        verify(mockUsage.sendTiming(captureAny, captureAny, captureAny, label: captureAny)).captured, 
        <dynamic>['flutter', 'doctor', const Duration(milliseconds: 1000), 'warning']
      );
    }, overrides: <Type, Generator>{
      Clock: () => mockClock,
      Doctor: () => mockDoctor,
      Usage: () => mockUsage,
    });
  });

  group('analytics bots', () {
    testUsingContext('don\'t send on bots', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      await createTestCommandRunner().run(<String>['--version']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => new Usage(
        settingsName: 'flutter_bot_test',
        versionOverride: 'dev/unknown',
      ),
    });
  });
}

class MockUsage extends Mock implements Usage {}

class MockDoctor extends Mock implements Doctor {}
