// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/base/net.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/web_runner.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  group('run', () {
    MockApplicationPackageFactory mockApplicationPackageFactory;
    MockDeviceManager mockDeviceManager;
    MockFlutterVersion mockStableFlutterVersion;
    MockFlutterVersion mockUnstableFlutterVersion;

    setUpAll(() {
      Cache.disableLocking();
      mockApplicationPackageFactory = MockApplicationPackageFactory();
      mockDeviceManager = MockDeviceManager();
      mockStableFlutterVersion = MockFlutterVersion(isStable: true);
      mockUnstableFlutterVersion = MockFlutterVersion(isStable: false);
    });

    testUsingContext('fails when target not found', () async {
      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>['run', '-t', 'abc123', '--no-pub']);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
      }
    });

    testUsingContext('does not support "--use-application-binary" and "--fast-start"', () async {
      globals.fs.file(globals.fs.path.join('lib', 'main.dart')).createSync(recursive: true);
      globals.fs.file('pubspec.yaml').createSync();
      globals.fs.file('.packages').createSync();

      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>[
          'run',
          '--use-application-binary=app/bar/faz',
          '--fast-start',
          '--no-pub',
          '--show-test-device',
        ]);
        fail('Expect exception');
      } catch (e) {
        expect(e.toString(), isNot(contains('--fast-start is not supported with --use-application-binary')));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Walks upward looking for a pubspec.yaml and succeeds if found', () async {
      globals.fs.file('pubspec.yaml').createSync();
      globals.fs.file('.packages')
        ..createSync()
        ..writeAsStringSync('Not a valid package');

      globals.fs.currentDirectory = globals.fs.directory(globals.fs.path.join('a', 'b', 'c'))
        ..createSync(recursive: true);

      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>[
          'run',
          '--fast-start',
          '--no-pub',
        ]);
        fail('Expect exception');
      } catch (e) {
        expect(e, isInstanceOf<ToolExit>());
      }
      final BufferLogger bufferLogger = globals.logger as BufferLogger;
      expect(bufferLogger.statusText, contains(
        'Changing current working directory to:'
      ));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Walks upward looking for a pubspec.yaml and exits if missing', () async {
      globals.fs.currentDirectory = globals.fs.directory(globals.fs.path.join('a', 'b', 'c'))
        ..createSync(recursive: true);

      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>[
          'run',
          '--fast-start',
          '--no-pub',
        ]);
        fail('Expect exception');
      } catch (e) {
        expect(e, isInstanceOf<ToolExit>());
        expect(e.toString(), contains('No pubspec.yaml file found'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });


    group('run app', () {
      MemoryFileSystem fs;
      MockArtifacts mockArtifacts;
      MockCache mockCache;
      MockProcessManager mockProcessManager;
      MockUsage mockUsage;
      Directory tempDir;

      setUpAll(() {
        mockArtifacts = MockArtifacts();
        mockCache = MockCache();
        mockUsage = MockUsage();
        fs = MemoryFileSystem();
        mockProcessManager = MockProcessManager();

        tempDir = fs.systemTempDirectory.createTempSync('flutter_run_test.');
        fs.currentDirectory = tempDir;

        tempDir.childFile('pubspec.yaml')
          .writeAsStringSync('name: flutter_app');
        tempDir.childFile('.packages')
          .writeAsStringSync('# Generated by pub on 2019-11-25 12:38:01.801784.');
        final Directory libDir = tempDir.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');

        when(mockDeviceManager.hasSpecifiedDeviceId).thenReturn(false);
        when(mockDeviceManager.hasSpecifiedAllDevices).thenReturn(false);
      });

      testUsingContext('exits with a user message when no supported devices attached', () async {
        final RunCommand command = RunCommand();
        applyMocksToCommand(command);

        const List<Device> noDevices = <Device>[];
        when(mockDeviceManager.getDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(noDevices)
        );
        when(mockDeviceManager.findTargetDevices(any)).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(noDevices)
        );

        try {
          await createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
          ]);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.message, null);
        }

        expect(testLogger.statusText, contains(userMessages.flutterNoSupportedDevices));
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('updates cache before checking for devices', () async {
        final RunCommand command = RunCommand();
        applyMocksToCommand(command);

        // Called as part of requiredArtifacts()
        when(mockDeviceManager.getDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[])
        );
        // No devices are attached, we just want to verify update the cache
        // BEFORE checking for devices
        when(mockDeviceManager.findTargetDevices(any)).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[])
        );

        try {
          await createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
          ]);
          fail('Exception expected');
        } on ToolExit catch (e) {
          // We expect a ToolExit because no devices are attached
          expect(e.message, null);
        } catch (e) {
          fail('ToolExit expected');
        }

        verifyInOrder(<void>[
          // cache update
          mockCache.updateAll(<DevelopmentArtifact>{DevelopmentArtifact.universal}),
          // as part of gathering `requiredArtifacts`
          mockDeviceManager.getDevices(),
          // in validateCommand()
          mockDeviceManager.findTargetDevices(any),
        ]);
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        Cache: () => mockCache,
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('passes device target platform to usage', () async {
        final RunCommand command = RunCommand();
        applyMocksToCommand(command);
        final MockDevice mockDevice = MockDevice(TargetPlatform.ios);
        when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) => Future<bool>.value(false));
        when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(MockDeviceLogReader());
        when(mockDevice.supportsFastStart).thenReturn(true);
        when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) => Future<String>.value('iOS 13'));
        // App fails to start because we're only interested in usage
        when(mockDevice.startApp(
          any,
          mainPath: anyNamed('mainPath'),
          debuggingOptions: anyNamed('debuggingOptions'),
          platformArgs: anyNamed('platformArgs'),
          route: anyNamed('route'),
          prebuiltApplication: anyNamed('prebuiltApplication'),
          ipv6: anyNamed('ipv6'),
        )).thenAnswer((Invocation invocation) => Future<LaunchResult>.value(LaunchResult.failed()));

        when(mockArtifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: anyNamed('platform'),
          mode: anyNamed('mode'),
        )).thenReturn('/path/to/sdk');

        when(mockDeviceManager.getDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[mockDevice])
        );

        when(mockDeviceManager.findTargetDevices(any)).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[mockDevice])
        );

        final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_run_test.');
        tempDir.childDirectory('ios').childFile('AppDelegate.swift').createSync(recursive: true);
        tempDir.childFile('.packages').createSync();
        tempDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
        tempDir.childFile('pubspec.yaml')
          ..createSync()
          ..writeAsStringSync('# Hello, World');
        globals.fs.currentDirectory = tempDir;

        try {
          await createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
          ]);
          fail('Exception expected');
        } on ToolExit catch (e) {
          // We expect a ToolExit because app does not start
          expect(e.message, null);
        } catch (e) {
          fail('ToolExit expected');
        }
        final List<dynamic> captures = verify(mockUsage.sendCommand(
          captureAny,
          parameters: captureAnyNamed('parameters'),
        )).captured;
        expect(captures[0], 'run');
        final Map<String, String> parameters = captures[1] as Map<String, String>;

        expect(parameters[cdKey(CustomDimensions.commandRunIsEmulator)], 'false');
        expect(parameters[cdKey(CustomDimensions.commandRunTargetName)], 'ios');
        expect(parameters[cdKey(CustomDimensions.commandRunProjectHostLanguage)], 'swift');
        expect(parameters[cdKey(CustomDimensions.commandRunTargetOsVersion)], 'iOS 13');
        expect(parameters[cdKey(CustomDimensions.commandRunModeName)], 'debug');
        expect(parameters[cdKey(CustomDimensions.commandRunProjectModule)], 'false');
        expect(parameters.containsKey(cdKey(CustomDimensions.commandRunAndroidEmbeddingVersion)), false);
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        Artifacts: () => mockArtifacts,
        Cache: () => mockCache,
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
        Usage: () => mockUsage,
      });
    });

    group('dart-flags option', () {
      setUpAll(() {
        final FakeDevice fakeDevice = FakeDevice();
        when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
          return Future<List<Device>>.value(<Device>[fakeDevice]);
        });
        when(mockDeviceManager.findTargetDevices(any)).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[fakeDevice])
        );
      });

      RunCommand command;
      List<String> args;
      setUp(() {
        command = TestRunCommand();
        args = <String> [
          'run',
          '--dart-flags', '"--observe"',
          '--no-hot',
          '--no-pub',
        ];
      });

      testUsingContext('is not available on stable channel', () async {
        // Stable branch.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        // ignore: unused_catch_clause
        } on UsageException catch(e) {
          // Not available while on stable branch.
        }
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockStableFlutterVersion,
      });

      testUsingContext('is populated in debug mode', () async {
        // FakeDevice.startApp checks that --dart-flags doesn't get dropped and
        // throws ToolExit with FakeDevice.kSuccess if the flag is populated.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.exitCode, FakeDevice.kSuccess);
        }
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockUnstableFlutterVersion,
      });

      testUsingContext('is populated in profile mode', () async {
        args.add('--profile');

        // FakeDevice.startApp checks that --dart-flags doesn't get dropped and
        // throws ToolExit with FakeDevice.kSuccess if the flag is populated.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.exitCode, FakeDevice.kSuccess);
        }
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockUnstableFlutterVersion,
      });

      testUsingContext('is not populated in release mode', () async {
        args.add('--release');

        // FakeDevice.startApp checks that --dart-flags *does* get dropped and
        // throws ToolExit with FakeDevice.kSuccess if the flag is set to the
        // empty string.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.exitCode, FakeDevice.kSuccess);
        }
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockUnstableFlutterVersion,
      });
    });

    testUsingContext('should only request artifacts corresponding to connected devices', () async {
      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Future<List<Device>>.value(<Device>[
          MockDevice(TargetPlatform.android_arm),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.androidGenSnapshot,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Future<List<Device>>.value(<Device>[
          MockDevice(TargetPlatform.ios),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Future<List<Device>>.value(<Device>[
          MockDevice(TargetPlatform.ios),
          MockDevice(TargetPlatform.android_arm),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
        DevelopmentArtifact.androidGenSnapshot,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Future<List<Device>>.value(<Device>[
          MockDevice(TargetPlatform.web_javascript),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.web,
      }));
    }, overrides: <Type, Generator>{
      DeviceManager: () => mockDeviceManager,
    });

    group('--dart-define option', () {
      MemoryFileSystem fs;
      MockProcessManager mockProcessManager;
      MockWebRunnerFactory mockWebRunnerFactory;

      setUpAll(() {
        final FakeDevice fakeDevice = FakeDevice().._targetPlatform = TargetPlatform.web_javascript;
        when(mockDeviceManager.getDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[fakeDevice])
        );
        when(mockDeviceManager.findTargetDevices(any)).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[fakeDevice])
        );
      });

      RunCommand command;
      List<String> args;
      setUp(() {
        command = TestRunCommand();
        args = <String> [
          'run',
          '--dart-define=FOO=bar',
          '--no-hot',
          '--no-pub',
        ];
        applyMocksToCommand(command);
        fs = MemoryFileSystem();
        mockProcessManager = MockProcessManager();
        mockWebRunnerFactory = MockWebRunnerFactory();
      });

      testUsingContext('populates the environment', () async {
        final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_run_test.');
        globals.fs.currentDirectory = tempDir;

        final Directory libDir = tempDir.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');

        final Directory webDir = tempDir.childDirectory('web');
        webDir.createSync();
        final File indexFile = libDir.childFile('index.html');
        indexFile.writeAsStringSync('<h1>Hello</h1>');

        await createTestCommandRunner(command).run(args);
        expect(mockWebRunnerFactory._dartDefines, <String>['FOO=bar']);
      }, overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(
          isWebEnabled: true,
        ),
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockStableFlutterVersion,
        WebRunnerFactory: () => mockWebRunnerFactory,
      });

      testUsingContext('populates dartDefines in --machine mode', () async {
        final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_run_test.');
        globals.fs.currentDirectory = tempDir;

        final Directory libDir = tempDir.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');

        final Directory webDir = tempDir.childDirectory('web');
        webDir.createSync();
        final File indexFile = libDir.childFile('index.html');
        indexFile.writeAsStringSync('<h1>Hello</h1>');

        when(mockDeviceManager.deviceDiscoverers).thenReturn(<DeviceDiscovery>[]);

        args.add('--machine');
        await createTestCommandRunner(command).run(args);
        expect(mockWebRunnerFactory._dartDefines, <String>['FOO=bar']);
      }, overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(
          isWebEnabled: true,
        ),
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockStableFlutterVersion,
        WebRunnerFactory: () => mockWebRunnerFactory,
      });
    });
  });
}

class MockArtifacts extends Mock implements Artifacts {}
class MockCache extends Mock implements Cache {}
class MockUsage extends Mock implements Usage {}

class MockDeviceManager extends Mock implements DeviceManager {}
class MockDevice extends Mock implements Device {
  MockDevice(this._targetPlatform);

  final TargetPlatform _targetPlatform;

  @override
  Future<TargetPlatform> get targetPlatform async => Future<TargetPlatform>.value(_targetPlatform);
}

class TestRunCommand extends RunCommand {
  @override
  // ignore: must_call_super
  Future<void> validateCommand() async {
    devices = await deviceManager.getDevices();
  }
}

class MockStableFlutterVersion extends MockFlutterVersion {
  @override
  bool get isMaster => false;
}

class FakeDevice extends Fake implements Device {
  static const int kSuccess = 1;
  static const int kFailure = -1;
  TargetPlatform _targetPlatform = TargetPlatform.ios;

  @override
  String get id => 'fake_device';

  void _throwToolExit(int code) => throwToolExit(null, exitCode: code);

  @override
  Future<bool> get isLocalEmulator => Future<bool>.value(false);

  @override
  bool get supportsHotReload => false;

  @override
  bool get supportsFastStart => false;

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value('');

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    return MockDeviceLogReader();
  }

  @override
  String get name => 'FakeDevice';

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  final PlatformType platformType = PlatformType.ios;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) async {
    final String dartFlags = debuggingOptions.dartFlags;
    // In release mode, --dart-flags should be set to the empty string and
    // provided flags should be dropped. In debug and profile modes,
    // --dart-flags should not be empty.
    if (debuggingOptions.buildInfo.isRelease) {
      if (dartFlags.isNotEmpty) {
        _throwToolExit(kFailure);
      }
      _throwToolExit(kSuccess);
    } else {
      if (dartFlags.isEmpty) {
        _throwToolExit(kFailure);
      }
      _throwToolExit(kSuccess);
    }
    return null;
  }
}

class MockWebRunnerFactory extends Mock implements WebRunnerFactory {
  List<String> _dartDefines;

  @override
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String target,
    bool stayResident,
    FlutterProject flutterProject,
    bool ipv6,
    DebuggingOptions debuggingOptions,
    UrlTunneller urlTunneller,
  }) {
    _dartDefines = debuggingOptions.buildInfo.dartDefines;
    return MockWebRunner();
  }
}

class MockWebRunner extends Mock implements ResidentRunner {
  @override
  bool get debuggingEnabled => false;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    return 0;
  }

  @override
  Future<int> waitForAppToFinish() async => 0;
}
