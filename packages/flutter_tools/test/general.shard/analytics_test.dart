// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/commands/doctor.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:usage/usage_io.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('analytics', () {
    Directory tempDir;
    MockFlutterConfig mockFlutterConfig;

    setUp(() {
      Cache.flutterRoot = '../..';
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_analytics_test.');
      mockFlutterConfig = MockFlutterConfig();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    // Ensure we don't send anything when analytics is disabled.
    testUsingContext("doesn't send when disabled", () async {
      int count = 0;
      globals.flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      final FlutterCommand command = FakeFlutterCommand();
      final CommandRunner<void>runner = createTestCommandRunner(command);

      globals.flutterUsage.enabled = false;
      await runner.run(<String>['fake']);
      expect(count, 0);

      globals.flutterUsage.enabled = true;
      await runner.run(<String>['fake']);
      // LogToFileAnalytics isFirstRun is hardcoded to false
      // so this usage will never act like the first run
      // (which would not send usage).
      expect(count, 4);

      count = 0;
      globals.flutterUsage.enabled = false;
      await runner.run(<String>['fake']);

      expect(count, 0);
    }, overrides: <Type, Generator>{
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      Usage: () => Usage(
        configDirOverride: tempDir.path,
        logFile: tempDir.childFile('analytics.log').path,
        runningOnBot: true,
      ),
    });

    // Ensure we don't send for the 'flutter config' command.
    testUsingContext("config doesn't send", () async {
      int count = 0;
      globals.flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);

      globals.flutterUsage.enabled = false;
      final ConfigCommand command = ConfigCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['config']);
      expect(count, 0);

      globals.flutterUsage.enabled = true;
      await runner.run(<String>['config']);

      expect(count, 0);
    }, overrides: <Type, Generator>{
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      Usage: () => Usage(
        configDirOverride: tempDir.path,
        logFile: tempDir.childFile('analytics.log').path,
        runningOnBot: true,
      ),
    });

    testUsingContext('Usage records one feature in experiment setting', () async {
      when<bool>(mockFlutterConfig.getValue(flutterWebFeature.configSetting) as bool)
          .thenReturn(true);
      final Usage usage = Usage(runningOnBot: true);
      usage.sendCommand('test');

      final String featuresKey = cdKey(CustomDimensions.enabledFlutterFeatures);

      expect(globals.fs.file('test').readAsStringSync(), contains('$featuresKey: enable-web'));
    }, overrides: <Type, Generator>{
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      Config: () => mockFlutterConfig,
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
      }),
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Usage records multiple features in experiment setting', () async {
      when<bool>(mockFlutterConfig.getValue(flutterWebFeature.configSetting) as bool)
          .thenReturn(true);
      when<bool>(mockFlutterConfig.getValue(flutterLinuxDesktopFeature.configSetting) as bool)
          .thenReturn(true);
      when<bool>(mockFlutterConfig.getValue(flutterMacOSDesktopFeature.configSetting) as bool)
          .thenReturn(true);
      final Usage usage = Usage(runningOnBot: true);
      usage.sendCommand('test');

      final String featuresKey = cdKey(CustomDimensions.enabledFlutterFeatures);

      expect(
        globals.fs.file('test').readAsStringSync(),
        contains('$featuresKey: enable-web,enable-linux-desktop,enable-macos-desktop'),
      );
    }, overrides: <Type, Generator>{
      FlutterVersion: () => FlutterVersion(const SystemClock()),
      Config: () => mockFlutterConfig,
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_ANALYTICS_LOG_FILE': 'test',
      }),
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('analytics with mocks', () {
    MemoryFileSystem memoryFileSystem;
    MockStdio mockStdio;
    Usage mockUsage;
    SystemClock mockClock;
    Doctor mockDoctor;
    List<int> mockTimes;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      mockStdio = MockStdio();
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
      when(mockDoctor.diagnose(
        androidLicenses: false,
        verbose: false,
      )).thenAnswer((_) async => true);
      final DoctorCommand command = DoctorCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['doctor']);

      verify(mockClock.now()).called(2);

      expect(
        verify(mockUsage.sendTiming(
          captureAny,
          captureAny,
          captureAny,
          label: captureAnyNamed('label'),
        )).captured,
        <dynamic>['flutter', 'doctor', const Duration(milliseconds: 1000), 'success'],
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
        verify(mockUsage.sendTiming(
          captureAny,
          captureAny,
          captureAny,
          label: captureAnyNamed('label'),
        )).captured,
        <dynamic>['flutter', 'doctor', const Duration(milliseconds: 1000), 'warning'],
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
      final FlutterCommand buildApkCommand = buildCommand.subcommands['apk'] as FlutterCommand;

      expect(await buildApkCommand.usagePath, 'build/apk');
    }, overrides: <Type, Generator>{
      Usage: () => mockUsage,
    });

    testUsingContext('command sends localtime', () async {
      const int kMillis = 1000;
      mockTimes = <int>[kMillis];
      // Since FLUTTER_ANALYTICS_LOG_FILE is set in the environment, analytics
      // will be written to a file.
      final Usage usage = Usage(
        versionOverride: 'test',
        runningOnBot: true,
      );
      usage.suppressAnalytics = false;
      usage.enabled = true;

      usage.sendCommand('test');

      final String log = globals.fs.file('analytics.log').readAsStringSync();
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(kMillis);

      expect(log.contains(formatDateTime(dateTime)), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      SystemClock: () => mockClock,
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FLUTTER_ANALYTICS_LOG_FILE': 'analytics.log',
        },
      ),
      Stdio: () => mockStdio,
    });

    testUsingContext('event sends localtime', () async {
      const int kMillis = 1000;
      mockTimes = <int>[kMillis];
      // Since FLUTTER_ANALYTICS_LOG_FILE is set in the environment, analytics
      // will be written to a file.
      final Usage usage = Usage(
        versionOverride: 'test',
        runningOnBot: true,
      );
      usage.suppressAnalytics = false;
      usage.enabled = true;

      usage.sendEvent('test', 'test');

      final String log = globals.fs.file('analytics.log').readAsStringSync();
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(kMillis);

      expect(log.contains(formatDateTime(dateTime)), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      SystemClock: () => mockClock,
      Platform: () => FakePlatform(
        environment: <String, String>{
          'FLUTTER_ANALYTICS_LOG_FILE': 'analytics.log',
        },
      ),
      Stdio: () => mockStdio,
    });
  });

  group('analytics bots', () {
    Directory tempDir;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync(
        'flutter_tools_analytics_bots_test.',
      );
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext("don't send on bots with unknown version", () async {
      int count = 0;
      globals.flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);
      await createTestCommandRunner().run(<String>['--version']);

      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => Usage(
        settingsName: 'flutter_bot_test',
        versionOverride: 'dev/unknown',
        configDirOverride: tempDir.path,
        runningOnBot: false,
      ),
    });

    testUsingContext("don't send on bots even when opted in", () async {
      int count = 0;
      globals.flutterUsage.onSend.listen((Map<String, dynamic> data) => count++);
      globals.flutterUsage.enabled = true;
      await createTestCommandRunner().run(<String>['--version']);

      expect(count, 0);
    }, overrides: <Type, Generator>{
      Usage: () => Usage(
        settingsName: 'flutter_bot_test',
        versionOverride: 'dev/unknown',
        configDirOverride: tempDir.path,
        runningOnBot: false,
      ),
    });

    testUsingContext('Uses AnalyticsMock when .flutter cannot be created', () async {
      final Usage usage = Usage(
        settingsName: 'flutter_bot_test',
        versionOverride: 'dev/known',
        configDirOverride: tempDir.path,
        analyticsIOFactory: throwingAnalyticsIOFactory,
        runningOnBot: false,
      );
      final AnalyticsMock analyticsMock = AnalyticsMock();

      expect(usage.clientId, analyticsMock.clientId);
      expect(usage.suppressAnalytics, isTrue);
    });
  });
}

Analytics throwingAnalyticsIOFactory(
  String trackingId,
  String applicationName,
  String applicationVersion, {
  String analyticsUrl,
  Directory documentDirectory,
}) {
  throw const FileSystemException('Could not create file');
}

class FakeFlutterCommand extends FlutterCommand {
  @override
  String get description => 'A fake command';

  @override
  String get name => 'fake';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class MockUsage extends Mock implements Usage {}

class MockDoctor extends Mock implements Doctor {}

class MockFlutterConfig extends Mock implements Config {}
