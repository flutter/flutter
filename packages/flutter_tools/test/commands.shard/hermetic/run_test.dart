// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  group('run', () {
    MockApplicationPackageFactory mockApplicationPackageFactory;
    MockDeviceManager mockDeviceManager;
    FileSystem fileSystem;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      mockApplicationPackageFactory = MockApplicationPackageFactory();
      mockDeviceManager = MockDeviceManager();
      fileSystem = MemoryFileSystem.test();
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
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => BufferLogger.test(),
    });

    testUsingContext('does not support "--use-application-binary" and "--fast-start"', () async {
      fileSystem.file('lib/main.dart').createSync(recursive: true);
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.packages').createSync();

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
      } on Exception catch (e) {
        expect(e.toString(), isNot(contains('--fast-start is not supported with --use-application-binary')));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => BufferLogger.test(),
    });

    testUsingContext('Walks upward looking for a pubspec.yaml and succeeds if found', () async {
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.packages')
        .writeAsStringSync('\n');
      fileSystem.file('lib/main.dart')
        .createSync(recursive: true);
      fileSystem.currentDirectory = fileSystem.directory('a/b/c')
        ..createSync(recursive: true);

      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
        ]);
        fail('Expect exception');
      } on Exception catch (e) {
        expect(e, isA<ToolExit>());
      }
      final BufferLogger bufferLogger = globals.logger as BufferLogger;
      expect(
        bufferLogger.statusText,
        containsIgnoringWhitespace('Changing current working directory to:'),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => BufferLogger.test(),
    });

    testUsingContext('Walks upward looking for a pubspec.yaml and exits if missing', () async {
      fileSystem.currentDirectory = fileSystem.directory('a/b/c')
        ..createSync(recursive: true);
      fileSystem.file('lib/main.dart')
        .createSync(recursive: true);

      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
        ]);
        fail('Expect exception');
      } on Exception catch (e) {
        expect(e, isA<ToolExit>());
        expect(e.toString(), contains('No pubspec.yaml file found'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => BufferLogger.test(),
    });

    group('run app', () {
      MemoryFileSystem fs;
      MockArtifacts mockArtifacts;
      MockCache mockCache;
      MockProcessManager mockProcessManager;
      MockUsage mockUsage;
      Directory tempDir;

      setUp(() {
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
        when(mockDeviceManager.findTargetDevices(any, timeout: anyNamed('timeout'))).thenAnswer(
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

        expect(
          testLogger.statusText,
          containsIgnoringWhitespace(userMessages.flutterNoSupportedDevices),
        );
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
      });

      testUsingContext('fails when targeted device is not Android with --device-user', () async {
        globals.fs.file('pubspec.yaml').createSync();
        globals.fs.file('.packages').writeAsStringSync('\n');
        globals.fs.file('lib/main.dart').createSync(recursive: true);
        final FakeDevice device = FakeDevice(isLocalEmulator: true);
        when(mockDeviceManager.getAllConnectedDevices()).thenAnswer((Invocation invocation) async {
          return <Device>[device];
        });
        when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) async {
          return <Device>[device];
        });
        when(mockDeviceManager.findTargetDevices(any, timeout: anyNamed('timeout'))).thenAnswer((Invocation invocation) async {
          return <Device>[device];
        });
        when(mockDeviceManager.hasSpecifiedAllDevices).thenReturn(false);
        when(mockDeviceManager.deviceDiscoverers).thenReturn(<DeviceDiscovery>[]);

        final RunCommand command = RunCommand();
        applyMocksToCommand(command);
        await expectLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
          '--device-user',
          '10',
        ]), throwsToolExit(message: '--device-user is only supported for Android. At least one Android device is required.'));
      }, overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        DeviceManager: () => mockDeviceManager,
        Stdio: () => MockStdio(),
      });

      testUsingContext('shows unsupported devices when no supported devices are found',  () async {
        final RunCommand command = RunCommand();
        applyMocksToCommand(command);

        final MockDevice mockDevice = MockDevice(TargetPlatform.android_arm);
        when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) => Future<bool>.value(true));
        when(mockDevice.isSupported()).thenAnswer((Invocation invocation) => true);
        when(mockDevice.supportsFastStart).thenReturn(true);
        when(mockDevice.id).thenReturn('mock-id');
        when(mockDevice.name).thenReturn('mock-name');
        when(mockDevice.platformType).thenReturn(PlatformType.android);
        when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation invocation) => Future<String>.value('api-14'));

        when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
          return Future<List<Device>>.value(<Device>[
            mockDevice,
          ]);
        });

        when(mockDeviceManager.findTargetDevices(any, timeout: anyNamed('timeout'))).thenAnswer(
            (Invocation invocation) => Future<List<Device>>.value(<Device>[]),
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

        expect(
          testLogger.statusText,
          containsIgnoringWhitespace(userMessages.flutterNoSupportedDevices),
        );
        expect(
          testLogger.statusText,
          containsIgnoringWhitespace(userMessages.flutterFoundButUnsupportedDevices),
        );
        expect(
          testLogger.statusText,
          containsIgnoringWhitespace(
            userMessages.flutterMissPlatformProjects(
              Device.devicesPlatformTypes(<Device>[mockDevice]),
            ),
          ),
        );
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
        const Duration timeout = Duration(seconds: 10);
        when(mockDeviceManager.findTargetDevices(any, timeout: timeout)).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[])
        );

        try {
          await createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--device-timeout',
            '10',
          ]);
          fail('Exception expected');
        } on ToolExit catch (e) {
          // We expect a ToolExit because no devices are attached
          expect(e.message, null);
        } on Exception catch (e) {
          fail('ToolExit expected, got $e');
        }

        verifyInOrder(<void>[
          // cache update
          mockCache.updateAll(<DevelopmentArtifact>{DevelopmentArtifact.universal}),
          // as part of gathering `requiredArtifacts`
          mockDeviceManager.getDevices(),
          // in validateCommand()
          mockDeviceManager.findTargetDevices(any, timeout: anyNamed('timeout')),
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
        when(mockDevice.supportsRuntimeMode(any)).thenAnswer((Invocation invocation) => true);
        when(mockDevice.isLocalEmulator).thenAnswer((Invocation invocation) => Future<bool>.value(false));
        when(mockDevice.getLogReader(app: anyNamed('app'))).thenReturn(FakeDeviceLogReader());
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
          userIdentifier: anyNamed('userIdentifier'),
        )).thenAnswer((Invocation invocation) => Future<LaunchResult>.value(LaunchResult.failed()));

        when(mockArtifacts.getArtifactPath(
          Artifact.flutterPatchedSdkPath,
          platform: anyNamed('platform'),
          mode: anyNamed('mode'),
        )).thenReturn('/path/to/sdk');

        when(mockDeviceManager.getDevices()).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[mockDevice])
        );

        when(mockDeviceManager.findTargetDevices(any, timeout: anyNamed('timeout'))).thenAnswer(
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
        } on Exception catch (e) {
          fail('ToolExit expected, got $e');
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
      RunCommand command;
      List<String> args;
      MockDeviceManager mockDeviceManager;

      setUp(() {
        command = TestRunCommand();
        args = <String> [
          'run',
          '--dart-flags', '"--observe"',
          '--no-hot',
          '--no-pub',
        ];
        mockDeviceManager = MockDeviceManager();
        final FakeDevice fakeDevice = FakeDevice();
        when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
          return Future<List<Device>>.value(<Device>[fakeDevice]);
        });
        when(mockDeviceManager.findTargetDevices(any, timeout: anyNamed('timeout'))).thenAnswer(
          (Invocation invocation) => Future<List<Device>>.value(<Device>[fakeDevice])
        );
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
    devices = await globals.deviceManager.getDevices();
  }
}

class FakeDevice extends Fake implements Device {
  FakeDevice({bool isLocalEmulator = false})
   : _isLocalEmulator = isLocalEmulator;

  static const int kSuccess = 1;
  static const int kFailure = -1;
  final TargetPlatform _targetPlatform = TargetPlatform.ios;
  final bool _isLocalEmulator;

  @override
  String get id => 'fake_device';

  void _throwToolExit(int code) => throwToolExit(null, exitCode: code);

  @override
  Future<bool> get isLocalEmulator => Future<bool>.value(_isLocalEmulator);

  @override
  bool supportsRuntimeMode(BuildMode mode) => true;

  @override
  bool get supportsHotReload => false;

  @override
  bool get supportsFastStart => false;

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value('');

  @override
  DeviceLogReader getLogReader({
    ApplicationPackage app,
    bool includePastLogs = false,
  }) {
    return FakeDeviceLogReader();
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
    String userIdentifier,
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
