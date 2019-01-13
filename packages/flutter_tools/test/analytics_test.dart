// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/commands/doctor.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/usage.dart';
import 'package:flutter_tools/src/version.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('analytics', () {
    Directory tempDir;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      Cache.flutterRoot = '../..';
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_analytics_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    // Ensure we don't send anything when analytics is disabled.
    testUsingContext('doesn\'t send when disabled', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      flutterUsage.enabled = false;
      await createProject(tempDir);
      expect(count, 0);

      flutterUsage.enabled = true;
      await createProject(tempDir);
      expect(count, flutterUsage.isFirstRun ? 0 : 2);

      count = 0;
      flutterUsage.enabled = false;
      final DoctorCommand doctorCommand = DoctorCommand();
      final CommandRunner<void>runner = createTestCommandRunner(doctorCommand);
      await runner.run(<String>['doctor']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      Usage: () => Usage(configDirOverride: tempDir.path),
    });

    // Ensure we don't send for the 'flutter config' command.
    testUsingContext('config doesn\'t send', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      flutterUsage.enabled = false;
      final ConfigCommand command = ConfigCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['config']);
      expect(count, 0);

      flutterUsage.enabled = true;
      await runner.run(<String>['config']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      Usage: () => Usage(configDirOverride: tempDir.path),
    });
  });

  group('analytics with mocks', () {
    Usage mockUsage;
    SystemClock mockClock;
    Doctor mockDoctor;
    List<int> mockTimes;

    setUp(() {
      mockUsage = MockUsage();
      when(mockUsage.isFirstRun).thenReturn(false);
      mockClock = MockClock();
      mockDoctor = MockDoctor();
      when(mockClock.now()).thenAnswer(
        (Invocation _) => DateTime.fromMillisecondsSinceEpoch(mockTimes.removeAt(0))
      );
    });

    testUsingContext('flutter commands send timing events', () async {
      mockTimes = <int>[1000, 2000];
      when(mockDoctor.diagnose(androidLicenses: false, verbose: false)).thenAnswer((_) async => true);
      final DoctorCommand command = DoctorCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['doctor']);

      verify(mockClock.now()).called(2);

      expect(
        verify(mockUsage.sendTiming(captureAny, captureAny, captureAny, label: captureAnyNamed('label'))).captured,
        <dynamic>['flutter', 'doctor', const Duration(milliseconds: 1000), 'success']
      );
    }, overrides: <Type, Generator>{
      SystemClock: () => mockClock,
      Doctor: () => mockDoctor,
      Usage: () => mockUsage,
    });

    testUsingContext('doctor fail sends warning', () async {
      mockTimes = <int>[1000, 2000];
      when(mockDoctor.diagnose(androidLicenses: false, verbose: false)).thenAnswer((_) async => false);
      final DoctorCommand command = DoctorCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['doctor']);

      verify(mockClock.now()).called(2);

      expect(
        verify(mockUsage.sendTiming(captureAny, captureAny, captureAny, label: captureAnyNamed('label'))).captured,
        <dynamic>['flutter', 'doctor', const Duration(milliseconds: 1000), 'warning']
      );
    }, overrides: <Type, Generator>{
      SystemClock: () => mockClock,
      Doctor: () => mockDoctor,
      Usage: () => mockUsage,
    });

    testUsingContext('single command usage path', () async {
      final FlutterCommand doctorCommand = DoctorCommand();
      expect(await doctorCommand.usagePath, 'doctor');
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });

    testUsingContext('compound command usage path', () async {
      final BuildCommand buildCommand = BuildCommand();
      final FlutterCommand buildApkCommand = buildCommand.subcommands['apk'];
      expect(await buildApkCommand.usagePath, 'build/apk');
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });
  });

  group('analytics bots', () {
    Directory tempDir;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_analytics_bots_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('don\'t send on bots', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      await createTestCommandRunner().run(<String>['--version']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => Usage(
        settingsName: 'flutter_bot_test',
        versionOverride: 'dev/unknown',
        configDirOverride: tempDir.path,
      ),
    });

    testUsingContext('don\'t send on bots even when opted in', () async {
      int count = 0;
      flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);
      flutterUsage.enabled = true;

      await createTestCommandRunner().run(<String>['--version']);
      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => Usage(
        settingsName: 'flutter_bot_test',
        versionOverride: 'dev/unknown',
        configDirOverride: tempDir.path,
      ),
    });
  });
}

class MockUsage extends Mock implements Usage {}

class MockDoctor extends Mock implements Doctor {}
