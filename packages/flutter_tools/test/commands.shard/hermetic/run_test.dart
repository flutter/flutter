// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('run', () {
    FakeDeviceManager mockDeviceManager;
    FileSystem fileSystem;

    setUp(() {
      mockDeviceManager = FakeDeviceManager();
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('fails when target not found', () async {
      final RunCommand command = RunCommand();
      expect(
        () => createTestCommandRunner(command).run(<String>['run', '-t', 'abc123', '--no-pub']),
        throwsA(isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1))),
      );
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
      await expectLater(
        () => createTestCommandRunner(command).run(<String>[
          'run',
          '--use-application-binary=app/bar/faz',
          '--fast-start',
          '--no-pub',
          '--show-test-device',
        ]),
        throwsA(isException.having(
          (Exception exception) => exception.toString(),
          'toString',
          isNot(contains('--fast-start is not supported with --use-application-binary')),
        )),
      );
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
      await expectLater(
        () => createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
        ]),
        throwsToolExit(),
      );
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
      await expectLater(
        () => createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
        ]),
        throwsToolExit(message: 'No pubspec.yaml file found'),
      );
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => BufferLogger.test(),
    });

    group('run app', () {
      MemoryFileSystem fs;
      Artifacts artifacts;
      TestUsage usage;
      FakeAnsiTerminal fakeTerminal;

      setUpAll(() {
        Cache.disableLocking();
      });

      setUp(() {
        fakeTerminal = FakeAnsiTerminal();
        artifacts = Artifacts.test();
        usage = TestUsage();
        fs = MemoryFileSystem.test();

        fs.currentDirectory.childFile('pubspec.yaml')
          .writeAsStringSync('name: flutter_app');
        fs.currentDirectory.childFile('.packages')
          .writeAsStringSync('# Generated by pub on 2019-11-25 12:38:01.801784.');
        final Directory libDir = fs.currentDirectory.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');
      });

      testUsingContext('exits with a user message when no supported devices attached', () async {
        final RunCommand command = RunCommand();
        mockDeviceManager
          ..devices = <Device>[]
          ..targetDevices = <Device>[];

        await expectLater(
          () => createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
          ]),
          throwsA(isA<ToolExit>().having((ToolExit error) => error.message, 'message', isNull)),
        );

        expect(
          testLogger.statusText,
          containsIgnoringWhitespace(userMessages.flutterNoSupportedDevices),
        );
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      });

      testUsingContext('exits and lists available devices when specified device not found', () async {
        final RunCommand command = RunCommand();
        final FakeDevice device = FakeDevice(isLocalEmulator: true);
        mockDeviceManager
          ..devices = <Device>[device]
          ..hasSpecifiedDeviceId = true;

        await expectLater(
              () => createTestCommandRunner(command).run(<String>[
            'run',
            '-d',
            'invalid-device-id',
            '--no-pub',
            '--no-hot',
          ]),
          throwsToolExit(),
        );
        expect(testLogger.statusText, contains("No supported devices found with name or id matching 'invalid-device-id'"));
        expect(testLogger.statusText, contains('The following devices were found:'));
        expect(testLogger.statusText, contains('FakeDevice (mobile) • fake_device • ios •  (simulator)'));
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      });

      testUsingContext('fails when targeted device is not Android with --device-user', () async {
        fs.file('pubspec.yaml').createSync();
        fs.file('.packages').writeAsStringSync('\n');
        fs.file('lib/main.dart').createSync(recursive: true);
        final FakeDevice device = FakeDevice(isLocalEmulator: true);

        mockDeviceManager
          ..devices = <Device>[device]
          ..targetDevices = <Device>[device];

        final RunCommand command = RunCommand();
        await expectLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
          '--device-user',
          '10',
        ]), throwsToolExit(message: '--device-user is only supported for Android. At least one Android device is required.'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        DeviceManager: () => mockDeviceManager,
        Stdio: () => FakeStdio(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      });

      testUsingContext('fails when v1 FlutterApplication is detected', () async {
        fs.file('pubspec.yaml').createSync();
        fs.file('android/AndroidManifest.xml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
          <manifest xmlns:android="http://schemas.android.com/apk/res/android"
              package="com.example.v1">
             <application
                  android:name="io.flutter.app.FlutterApplication">
              </application>
          </manifest>
        ''', flush: true);
        fs.file('.packages').writeAsStringSync('\n');
        fs.file('lib/main.dart').createSync(recursive: true);
        final AndroidDevice device = AndroidDevice('1234',
          modelID: 'TestModel',
          logger: testLogger,
          platform: FakePlatform(),
          androidSdk: FakeAndroidSdk(),
          fileSystem: fs,
          processManager: FakeProcessManager.any(),
        );

        mockDeviceManager
          ..devices = <Device>[device]
          ..targetDevices = <Device>[device];

        final RunCommand command = RunCommand();
        await expectLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--pub',
        ]), throwsToolExit(message: 'Build failed due to use of deprecated Android v1 embedding.'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        DeviceManager: () => mockDeviceManager,
        Stdio: () => FakeStdio(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      });

      testUsingContext('fails when v1 metadata is detected', () async {
        fs.file('pubspec.yaml').createSync();
        fs.file('android/AndroidManifest.xml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
          <manifest xmlns:android="http://schemas.android.com/apk/res/android"
              package="com.example.v1">
              <application >
                <meta-data
                    android:name="flutterEmbedding"
                    android:value="1" />
              </application>
          </manifest>
        ''', flush: true);
        fs.file('.packages').writeAsStringSync('\n');
        fs.file('lib/main.dart').createSync(recursive: true);
        final AndroidDevice device = AndroidDevice('1234',
          modelID: 'TestModel',
          logger: testLogger,
          platform: FakePlatform(),
          androidSdk: FakeAndroidSdk(),
          fileSystem: fs,
          processManager: FakeProcessManager.any(),
        );

        mockDeviceManager
          ..devices = <Device>[device]
          ..targetDevices = <Device>[device];

        final RunCommand command = RunCommand();
        await expectLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--pub',
        ]), throwsToolExit(message: 'Build failed due to use of deprecated Android v1 embedding.'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        DeviceManager: () => mockDeviceManager,
        Stdio: () => FakeStdio(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      });

      testUsingContext('shows unsupported devices when no supported devices are found',  () async {
        final RunCommand command = RunCommand();
        final FakeDevice mockDevice = FakeDevice(targetPlatform: TargetPlatform.android_arm, isLocalEmulator: true, sdkNameAndVersion: 'api-14');
        mockDeviceManager
          ..devices = <Device>[mockDevice]
          ..targetDevices = <Device>[];

        await expectLater(
          () => createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
          ]),
          throwsA(isA<ToolExit>().having((ToolExit error) => error.message, 'message', isNull)),
        );

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
        ProcessManager: () => FakeProcessManager.any(),
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      });

      testUsingContext('forwards --uninstall-only to DebuggingOptions', () async {
        final RunCommand command = RunCommand();
        final FakeDevice mockDevice = FakeDevice(
          sdkNameAndVersion: 'iOS 13',
        )..startAppSuccess = false;

        mockDeviceManager
          ..devices = <Device>[
            mockDevice,
          ]
          ..targetDevices = <Device>[
            mockDevice,
          ];

        // Causes swift to be detected in the analytics.
        fs.currentDirectory.childDirectory('ios').childFile('AppDelegate.swift').createSync(recursive: true);

        await expectToolExitLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--uninstall-first',
        ]), isNull);

        final DebuggingOptions options = await command.createDebuggingOptions(false);
        expect(options.uninstallFirst, isTrue);
      }, overrides: <Type, Generator>{
        Artifacts: () => artifacts,
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Usage: () => usage,
      });

      testUsingContext('passes device target platform to usage', () async {
        final RunCommand command = RunCommand();
        final FakeDevice mockDevice = FakeDevice(sdkNameAndVersion: 'iOS 13')
          ..startAppSuccess = false;

        mockDeviceManager
          ..devices = <Device>[
            mockDevice,
          ]
          ..targetDevices = <Device>[
            mockDevice,
          ];

        // Causes swift to be detected in the analytics.
        fs.currentDirectory.childDirectory('ios').childFile('AppDelegate.swift').createSync(recursive: true);

        await expectToolExitLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
        ]), isNull);

        expect(usage.commands, contains(
          TestUsageCommand('run', parameters: CustomDimensions.fromMap(<String, String>{
            'cd3': 'false', 'cd4': 'ios', 'cd22': 'iOS 13',
            'cd23': 'debug', 'cd18': 'false', 'cd15': 'swift', 'cd31': 'true',
            'cd56': 'false',
          })
        )));
      }, overrides: <Type, Generator>{
        AnsiTerminal: () => fakeTerminal,
        Artifacts: () => artifacts,
        Cache: () => Cache.test(processManager: FakeProcessManager.any()),
        DeviceManager: () => mockDeviceManager,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => FakeStdio(),
        Usage: () => usage,
      });

      group('--machine', () {
        testUsingContext('enables multidex by default', () async {
          final DaemonCapturingRunCommand command = DaemonCapturingRunCommand();
          final FakeDevice device = FakeDevice();
          mockDeviceManager
          ..devices = <Device>[device]
          ..targetDevices = <Device>[device];

          await expectLater(
                () => createTestCommandRunner(command).run(<String>[
              'run',
              '--no-pub',
              '--machine',
              '-d',
              device.id,
            ]),
            throwsToolExit(),
          );
          expect(command.appDomain.multidexEnabled, isTrue);
        }, overrides: <Type, Generator>{
          Artifacts: () => artifacts,
          Cache: () => Cache.test(processManager: FakeProcessManager.any()),
          DeviceManager: () => mockDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
          Usage: () => usage,
          Stdio: () => FakeStdio(),
          Logger: () => AppRunLogger(parent: BufferLogger.test()),
        });

        testUsingContext('can disable multidex with --no-multidex', () async {
          final DaemonCapturingRunCommand command = DaemonCapturingRunCommand();
          final FakeDevice device = FakeDevice();
          mockDeviceManager
          ..devices = <Device>[device]
          ..targetDevices = <Device>[device];

          await expectLater(
                () => createTestCommandRunner(command).run(<String>[
              'run',
              '--no-pub',
              '--no-multidex',
              '--machine',
              '-d',
              device.id,
            ]),
            throwsToolExit(),
          );
          expect(command.appDomain.multidexEnabled, isFalse);
        }, overrides: <Type, Generator>{
          Artifacts: () => artifacts,
          Cache: () => Cache.test(processManager: FakeProcessManager.any()),
          DeviceManager: () => mockDeviceManager,
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
          Usage: () => usage,
          Stdio: () => FakeStdio(),
          Logger: () => AppRunLogger(parent: BufferLogger.test()),
        });
      });
    });

    group('Fatal Logs', () {
      TestRunCommandWithFakeResidentRunner command;
      MemoryFileSystem fs;

      setUp(() {
        command = TestRunCommandWithFakeResidentRunner()
          ..fakeResidentRunner = FakeResidentRunner();
        fs = MemoryFileSystem.test();
      });

      testUsingContext("doesn't fail if --fatal-warnings specified and no warnings occur", () async {
        try {
          await createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
            '--${FlutterOptions.kFatalWarnings}',
          ]);
        } on Exception {
          fail('Unexpected exception thrown');
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext("doesn't fail if --fatal-warnings not specified", () async {
        testLogger.printWarning('Warning: Mild annoyance Will Robinson!');
        try {
          await createTestCommandRunner(command).run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
          ]);
        } on Exception {
          fail('Unexpected exception thrown');
        }
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('fails if --fatal-warnings specified and warnings emitted', () async {
        testLogger.printWarning('Warning: Mild annoyance Will Robinson!');
        await expectLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--${FlutterOptions.kFatalWarnings}',
        ]), throwsToolExit(message: 'Logger received warning output during the run, and "--${FlutterOptions.kFatalWarnings}" is enabled.'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('fails if --fatal-warnings specified and errors emitted', () async {
        testLogger.printError('Error: Danger Will Robinson!');
        await expectLater(createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--${FlutterOptions.kFatalWarnings}',
        ]), throwsToolExit(message: 'Logger received error output during the run, and "--${FlutterOptions.kFatalWarnings}" is enabled.'));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    testUsingContext('should only request artifacts corresponding to connected devices', () async {
      mockDeviceManager.devices = <Device>[FakeDevice(targetPlatform: TargetPlatform.android_arm)];

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.androidGenSnapshot,
      }));

      mockDeviceManager.devices = <Device>[FakeDevice()];

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
      }));

      mockDeviceManager.devices = <Device>[
        FakeDevice(),
        FakeDevice(targetPlatform: TargetPlatform.android_arm),
      ];

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
        DevelopmentArtifact.androidGenSnapshot,
      }));

      mockDeviceManager.devices = <Device>[
        FakeDevice(targetPlatform: TargetPlatform.web_javascript),
      ];

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.web,
      }));
    }, overrides: <Type, Generator>{
      DeviceManager: () => mockDeviceManager,
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('dart-defines and web-renderer options', () {
    List<String> dartDefines;

    setUp(() {
      dartDefines = <String>[];
    });

    test('auto web-renderer with no dart-defines', () {
      dartDefines = FlutterCommand.updateDartDefines(dartDefines, 'auto');
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=true']);
    });

    test('canvaskit web-renderer with no dart-defines', () {
      dartDefines = FlutterCommand.updateDartDefines(dartDefines, 'canvaskit');
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=true']);
    });

    test('html web-renderer with no dart-defines', () {
      dartDefines = FlutterCommand.updateDartDefines(dartDefines, 'html');
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=false']);
    });

    test('auto web-renderer with existing dart-defines', () {
      dartDefines = <String>['FLUTTER_WEB_USE_SKIA=false'];
      dartDefines = FlutterCommand.updateDartDefines(dartDefines, 'auto');
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=true']);
    });

    test('canvaskit web-renderer with no dart-defines', () {
      dartDefines = <String>['FLUTTER_WEB_USE_SKIA=false'];
      dartDefines = FlutterCommand.updateDartDefines(dartDefines, 'canvaskit');
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=true']);
    });

    test('html web-renderer with no dart-defines', () {
      dartDefines = <String>['FLUTTER_WEB_USE_SKIA=true'];
      dartDefines = FlutterCommand.updateDartDefines(dartDefines, 'html');
      expect(dartDefines, <String>['FLUTTER_WEB_AUTO_DETECT=false','FLUTTER_WEB_USE_SKIA=false']);
    });
  });

  group('terminal', () {
    FakeAnsiTerminal fakeTerminal;

    setUp(() {
      fakeTerminal = FakeAnsiTerminal();
    });

    testUsingContext('Flutter run sets terminal singleCharMode to false on exit', () async {
      final FakeResidentRunner residentRunner = FakeResidentRunner();
      final TestRunCommandWithFakeResidentRunner command = TestRunCommandWithFakeResidentRunner();
      command.fakeResidentRunner = residentRunner;

      await createTestCommandRunner(command).run(<String>[
        'run',
        '--no-pub',
      ]);
      // The sync completer where we initially set `terminal.singleCharMode` to
      // `true` does not execute in unit tests, so explicitly check the
      // `setSingleCharModeHistory` that the finally block ran, setting this
      // back to `false`.
      expect(fakeTerminal.setSingleCharModeHistory, contains(false));
    }, overrides: <Type, Generator>{
      AnsiTerminal: () => fakeTerminal,
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Flutter run catches StdinException while setting terminal singleCharMode to false', () async {
      fakeTerminal.hasStdin = false;
      final FakeResidentRunner residentRunner = FakeResidentRunner();
      final TestRunCommandWithFakeResidentRunner command = TestRunCommandWithFakeResidentRunner();
      command.fakeResidentRunner = residentRunner;

      try {
        await createTestCommandRunner(command).run(<String>[
          'run',
          '--no-pub',
        ]);
      } catch (err) { // ignore: avoid_catches_without_on_clauses
        fail('Expected no error, got $err');
      }
      expect(fakeTerminal.setSingleCharModeHistory, isEmpty);
    }, overrides: <Type, Generator>{
      AnsiTerminal: () => fakeTerminal,
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  testUsingContext('Flutter run catches service has disappear errors and throws a tool exit', () async {
    final FakeResidentRunner residentRunner = FakeResidentRunner();
    residentRunner.rpcError = RPCError('flutter._listViews', RPCErrorCodes.kServiceDisappeared, '');
    final TestRunCommandWithFakeResidentRunner command = TestRunCommandWithFakeResidentRunner();
    command.fakeResidentRunner = residentRunner;

    await expectToolExitLater(createTestCommandRunner(command).run(<String>[
      'run',
      '--no-pub',
    ]), contains('Lost connection to device.'));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Flutter run does not catch other RPC errors', () async {
    final FakeResidentRunner residentRunner = FakeResidentRunner();
    residentRunner.rpcError = RPCError('flutter._listViews', RPCErrorCodes.kInvalidParams, '');
    final TestRunCommandWithFakeResidentRunner command = TestRunCommandWithFakeResidentRunner();
    command.fakeResidentRunner = residentRunner;

    await expectLater(() => createTestCommandRunner(command).run(<String>[
      'run',
      '--no-pub',
    ]), throwsA(isA<RPCError>()));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Passes sksl bundle info the build options', () async {
    final TestRunCommandWithFakeResidentRunner command = TestRunCommandWithFakeResidentRunner();

    await expectLater(() => createTestCommandRunner(command).run(<String>[
      'run',
      '--no-pub',
      '--bundle-sksl-path=foo.json',
    ]), throwsToolExit(message: 'No SkSL shader bundle found at foo.json'));
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Configures web connection options to use web sockets by default', () async {
    final RunCommand command = RunCommand();
    await expectLater(() => createTestCommandRunner(command).run(<String>[
      'run',
      '--no-pub',
    ]), throwsToolExit());

    final DebuggingOptions options = await command.createDebuggingOptions(true);

    expect(options.webUseSseForDebugBackend, false);
    expect(options.webUseSseForDebugProxy, false);
    expect(options.webUseSseForInjectedClient, false);
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('flags propagate to debugging options', () async {
    final RunCommand command = RunCommand();
    await expectLater(() => createTestCommandRunner(command).run(<String>[
      'run',
      '--start-paused',
      '--disable-service-auth-codes',
      '--use-test-fonts',
      '--trace-skia',
      '--trace-systrace',
      '--verbose-system-logs',
      '--null-assertions',
      '--native-null-assertions',
      '--enable-impeller',
      '--trace-systrace',
      '--enable-software-rendering',
      '--skia-deterministic-rendering',
    ]), throwsToolExit());

    final DebuggingOptions options = await command.createDebuggingOptions(false);

    expect(options.startPaused, true);
    expect(options.disableServiceAuthCodes, true);
    expect(options.useTestFonts, true);
    expect(options.traceSkia, true);
    expect(options.traceSystrace, true);
    expect(options.verboseSystemLogs, true);
    expect(options.nullAssertions, true);
    expect(options.nativeNullAssertions, true);
    expect(options.traceSystrace, true);
    expect(options.enableImpeller, true);
    expect(options.enableSoftwareRendering, true);
    expect(options.skiaDeterministicRendering, true);
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('fails when "--web-launch-url" is not supported', () async {
    final RunCommand command = RunCommand();
    await expectLater(
          () => createTestCommandRunner(command).run(<String>[
        'run',
        '--web-launch-url=http://flutter.dev',
      ]),
      throwsA(isException.having(
            (Exception exception) => exception.toString(),
        'toString',
        isNot(contains('web-launch-url')),
      )),
    );

    final DebuggingOptions options = await command.createDebuggingOptions(true);
    expect(options.webLaunchUrl, 'http://flutter.dev');

    final RegExp pattern = RegExp(r'^((http)?:\/\/)[^\s]+');
    expect(pattern.hasMatch(options.webLaunchUrl), true);
  }, overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => BufferLogger.test(),
  });
}

class FakeDeviceManager extends Fake implements DeviceManager {
  List<Device> devices = <Device>[];
  List<Device> targetDevices = <Device>[];

  @override
  String specifiedDeviceId;

  @override
  bool hasSpecifiedAllDevices = false;

  @override
  bool hasSpecifiedDeviceId = false;

  @override
  Future<List<Device>> getDevices() async {
    return devices;
  }

  @override
  Future<List<Device>> findTargetDevices(FlutterProject flutterProject, {Duration timeout}) async {
    return targetDevices;
  }

  @override
  List<DeviceDiscovery> get deviceDiscoverers {
    final FakePollingDeviceDiscovery discoverer = FakePollingDeviceDiscovery();
    devices.forEach(discoverer.addDevice);
    return <DeviceDiscovery>[discoverer];
  }

  @override
  Future<List<Device>> getAllConnectedDevices() async => devices;
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String get adbPath => 'adb';
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeDevice extends Fake implements Device {
  FakeDevice({bool isLocalEmulator = false, TargetPlatform targetPlatform = TargetPlatform.ios, String sdkNameAndVersion = ''})
   : _isLocalEmulator = isLocalEmulator,
     _targetPlatform = targetPlatform,
     _sdkNameAndVersion = sdkNameAndVersion;

  static const int kSuccess = 1;
  static const int kFailure = -1;
  final TargetPlatform _targetPlatform;
  final bool _isLocalEmulator;
  final String _sdkNameAndVersion;

  @override
  Category get category => Category.mobile;

  @override
  String get id => 'fake_device';

  void _throwToolExit(int code) => throwToolExit('FakeDevice tool exit', exitCode: code);

  @override
  Future<bool> get isLocalEmulator => Future<bool>.value(_isLocalEmulator);

  @override
  bool supportsRuntimeMode(BuildMode mode) => true;

  @override
  Future<bool> get supportsHardwareRendering async => true;

  @override
  bool supportsHotReload = false;

  @override
  bool get supportsHotRestart => true;

  @override
  bool get supportsFastStart => false;

  bool supported = true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  bool isSupported() => supported;

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value(_sdkNameAndVersion);

  @override
  Future<String> get targetPlatformDisplayName async =>
      getNameForTargetPlatform(await targetPlatform);

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

  bool startAppSuccess;

  @override
  DevFSWriter createDevFSWriter(
    covariant ApplicationPackage app,
    String userIdentifier,
  ) {
    return null;
  }

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
    if (startAppSuccess == false) {
      return LaunchResult.failed();
    }
    if (startAppSuccess == true) {
      return LaunchResult.succeeded();
    }
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

class TestRunCommandWithFakeResidentRunner extends RunCommand {
  FakeResidentRunner fakeResidentRunner;

  @override
  Future<ResidentRunner> createRunner({
    @required bool hotMode,
    @required List<FlutterDevice> flutterDevices,
    @required String applicationBinaryPath,
    @required FlutterProject flutterProject,
  }) async {
    return fakeResidentRunner;
  }

  @override
  // ignore: must_call_super
  Future<void> validateCommand() async {
    devices = <Device>[FakeDevice()..supportsHotReload = true];
  }
}

class FakeResidentRunner extends Fake implements ResidentRunner {
  RPCError rpcError;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    bool enableDevTools = false,
    String route,
  }) async {
    await null;
    if (rpcError != null) {
      throw rpcError;
    }
    return 0;
  }
}

class DaemonCapturingRunCommand extends RunCommand {
  /*late*/ Daemon daemon;
  /*late*/ CapturingAppDomain appDomain;

  @override
  Daemon createMachineDaemon() {
    daemon = super.createMachineDaemon();
    appDomain = daemon.appDomain = CapturingAppDomain(daemon);
    daemon.registerDomain(appDomain);
    return daemon;
  }
}

class CapturingAppDomain extends AppDomain {
  CapturingAppDomain(Daemon daemon) : super(daemon);

  bool /*?*/ multidexEnabled;

  @override
  Future<AppInstance> startApp(
    Device device,
    String projectDirectory,
    String target,
    String route,
    DebuggingOptions options,
    bool enableHotReload, {
    File applicationBinary,
    @required bool trackWidgetCreation,
    String projectRootPath,
    String packagesFilePath,
    String dillOutputPath,
    bool ipv6 = false,
    bool multidexEnabled = false,
    String isolateFilter,
    bool machine = true,
  }) async {
    this.multidexEnabled = multidexEnabled;
    throwToolExit('');
  }
}

class FakeAnsiTerminal extends Fake implements AnsiTerminal {
  /// Setting to false will cause operations to Stdin to throw a [StdinException].
  bool hasStdin = true;

  @override
  bool usesTerminalUi = false;

  /// A list of all the calls to the [singleCharMode] setter.
  List<bool> setSingleCharModeHistory = <bool>[];

  @override
  set singleCharMode(bool value) {
    if (!hasStdin) {
      throw const StdinException('Error setting terminal line mode', OSError('The handle is invalid', 6));
    }
    setSingleCharModeHistory.add(value);
  }

  @override
  bool get singleCharMode => setSingleCharModeHistory.last;
}
