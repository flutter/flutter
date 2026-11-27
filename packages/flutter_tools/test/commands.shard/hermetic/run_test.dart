// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_engine_cli_flags.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/build_targets.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/daemon.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/context/apple_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/hook_runner.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/isolated/build_targets.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/web_debug_config.dart';
import 'package:flutter_tools/src/web/web_runner.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart' as analytics;
import 'package:vm_service/vm_service.dart';

import '../../src/common.dart';
import '../../src/fake_devices.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('run', () {
    late BufferLogger logger;
    late TestDeviceManager testDeviceManager;
    late FileSystem fileSystem;
    late FakeToolContext toolContext;

    setUp(() {
      logger = BufferLogger.test();
      testDeviceManager = TestDeviceManager(logger: logger);
      fileSystem = MemoryFileSystem.test();
      toolContext = FakeToolContext(fs: fileSystem, logger: logger);
    });

    test('preserves expected hidden and visible options across verboseHelp modes', () {
      final defaultCommand = RunCommand(
        appleContext: FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
        toolContext: toolContext,
      );
      expect(defaultCommand.argParser.options['track-widget-creation']?.hide, isFalse);
      expect(defaultCommand.argParser.options['native-null-assertions']?.hide, isTrue);
      expect(defaultCommand.argParser.options['adb-log-filtering']?.hide, isTrue);

      final verboseCommand = RunCommand(
        verboseHelp: true,
        appleContext: FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
        toolContext: toolContext,
      );
      expect(verboseCommand.argParser.options['track-widget-creation']?.hide, isFalse);
      expect(verboseCommand.argParser.options['native-null-assertions']?.hide, isFalse);
      expect(verboseCommand.argParser.options['adb-log-filtering']?.hide, isFalse);
    });

    test('fails when target not found', () async {
      final command = RunCommand(
        appleContext: FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
        toolContext: toolContext,
      );
      final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
        ..addCommand(command);
      await expectLater(
        () => runner.run(<String>['run', '-t', 'abc123', '--no-pub']),
        throwsA(
          isA<ToolExit>().having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1)),
        ),
      );
    });

    test('Walks upward looking for a pubspec.yaml and succeeds if found', () async {
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "packages": [],
  "configVersion": 2
}
''');
      fileSystem.file('lib/main.dart').createSync(recursive: true);
      fileSystem.currentDirectory = fileSystem.directory('a/b/c')..createSync(recursive: true);

      final command = RunCommand(
        appleContext: FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
        toolContext: toolContext,
      );
      final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
        ..addCommand(command);
      await expectLater(() => runner.run(<String>['run', '--no-pub']), throwsToolExit());
      expect(
        logger.statusText,
        containsIgnoringWhitespace('Changing current working directory to:'),
      );
    });

    test('Walks upward looking for a pubspec.yaml and exits if missing', () async {
      fileSystem.currentDirectory = fileSystem.directory('a/b/c')..createSync(recursive: true);
      fileSystem.file('lib/main.dart').createSync(recursive: true);

      final command = RunCommand(
        appleContext: FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
        toolContext: toolContext,
      );
      final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
        ..addCommand(command);
      await expectLater(
        () => runner.run(<String>['run', '--no-pub']),
        throwsToolExit(message: 'No pubspec.yaml file found'),
      );
    });

    test('accepts --[no-]deprecated-js-interop', () {
      expectAcceptsDeprecatedJsInteropFlag(
        RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        ),
      );
    });

    group('run app', () {
      late MemoryFileSystem fs;
      late Artifacts artifacts;
      late FakeAnsiTerminal fakeTerminal;
      late FakeStdio fakeStdio;
      late analytics.FakeAnalytics fakeAnalytics;
      late FakeToolContext toolContext;

      setUpAll(() {
        Cache.disableLocking();
      });

      setUp(() {
        fakeTerminal = FakeAnsiTerminal();
        fakeStdio = FakeStdio();
        artifacts = Artifacts.test();
        fs = MemoryFileSystem.test();

        fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
        writePackageConfigFiles(directory: fs.currentDirectory, mainLibName: 'my_app');

        final Directory libDir = fs.currentDirectory.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');
        fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: fs,
          fakeFlutterVersion: FakeFlutterVersion(),
        );
        toolContext = FakeToolContext(
          artifacts: artifacts,
          fs: fs,
          logger: logger,
          stdio: fakeStdio,
          terminal: fakeTerminal,
        );
      });

      test(
        'prebuiltApplicationBinaryPath is set when --use-application-binary is provided',
        () async {
          testDeviceManager.devices = <Device>[FakeDevice()];
          final RunCommand command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
          final CommandRunner<void> runner = TestFlutterCommandRunner(
            deviceManager: testDeviceManager,
            toolContext: toolContext,
          )..addCommand(command);
          await runner.run(<String>['run', '--no-pub', '--use-application-binary=path/to/binary']);
          expect(command.prebuiltApplicationBinaryPath, 'path/to/binary');
        },
      );

      for (final String flag in AndroidEngineCliFlags.allFlags) {
        test(
          'fails when --use-application-binary is provided with --release and --$flag for Android',
          () async {
            testDeviceManager.devices = <Device>[FakeDevice()];
            final RunCommand command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
            final CommandRunner<void> runner = TestFlutterCommandRunner(
              deviceManager: testDeviceManager,
              toolContext: toolContext,
            )..addCommand(command);
            final String flagArg = switch (flag) {
              AndroidEngineCliFlags.route => '--route=/',
              AndroidEngineCliFlags.traceAllowlist => '--trace-allowlist=foo',
              AndroidEngineCliFlags.traceSkiaAllowlist => '--trace-skia-allowlist=foo',
              AndroidEngineCliFlags.traceToFile => '--trace-to-file=path',
              AndroidEngineCliFlags.dartFlags => '--dart-flags=--foo',
              _ => '--$flag',
            };
            await expectLater(
              () => runner.run(<String>[
                'run',
                '--no-pub',
                '--release',
                flagArg,
                '--use-application-binary=path/to/app.apk',
              ]),
              throwsA(
                isA<ToolExit>().having(
                  (ToolExit error) => error.message,
                  'message',
                  allOf(
                    contains(flag),
                    contains(
                      'https://docs.flutter.dev/release/breaking-changes/restrict-command-line-flags-prebuilt-android-release-binaries',
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      test('succeeds when --use-application-binary is provided with --release and engine config flags for iOS', () async {
        testDeviceManager.devices = <Device>[FakeDevice()];
        final RunCommand command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);

        await runner.run(<String>[
          'run',
          '--no-pub',
          '--release',
          '--route=/',
          '--use-application-binary=path/to/app.ipa',
        ]);
        expect(command.prebuiltApplicationBinaryPath, 'path/to/app.ipa');
      });

      test('succeeds when --use-application-binary is provided with --release and engine config flags for Windows', () async {
        testDeviceManager.devices = <Device>[FakeDevice()];
        final RunCommand command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);

        await runner.run(<String>[
          'run',
          '--no-pub',
          '--release',
          '--route=/',
          '--use-application-binary=path/to/app.exe',
        ]);
        expect(command.prebuiltApplicationBinaryPath, 'path/to/app.exe');
      });

      test('succeeds when --use-application-binary is provided with --release and engine config flags for macOS', () async {
        testDeviceManager.devices = <Device>[FakeDevice()];
        final RunCommand command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);

        await runner.run(<String>[
          'run',
          '--no-pub',
          '--release',
          '--route=/',
          '--use-application-binary=path/to/app.app',
        ]);
        expect(command.prebuiltApplicationBinaryPath, 'path/to/app.app');
      });

      test('exits with a user message when no supported devices attached', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        );
        testDeviceManager.devices = <Device>[];
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);

        await expectLater(
          () => runner.run(<String>['run', '--no-pub', '--no-hot']),
          throwsA(isA<ToolExit>().having((ToolExit error) => error.message, 'message', isNull)),
        );

        expect(logger.statusText, containsIgnoringWhitespace('No supported devices connected.'));
      });

      test('exits and lists available devices when specified device not found', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        );
        final device = FakeDevice(isLocalEmulator: true);
        testDeviceManager
          ..devices = <Device>[device]
          ..specifiedDeviceId = 'invalid-device-id';
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);

        await expectLater(
          () => runner.run(<String>['run', '-d', 'invalid-device-id', '--no-pub', '--no-hot']),
          throwsToolExit(),
        );
        expect(
          logger.statusText,
          contains("No supported devices found with name or id matching 'invalid-device-id'"),
        );
        expect(logger.statusText, contains('The following devices were found:'));
        expect(
          logger.statusText,
          contains('FakeDevice (mobile) • fake_device • ios •  (simulator)'),
        );
      });

      test('fails when targeted device is not Android with --device-user', () async {
        final device = FakeDevice(isLocalEmulator: true);

        testDeviceManager.devices = <Device>[device];

        final command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          runner.run(<String>['run', '--no-pub', '--device-user', '10']),
          throwsToolExit(
            message: '--device-user is only supported for Android. At least one Android device is required.',
          ),
        );
      });

      test('succeeds when targeted device is an Android device with --device-user', () async {
        final device = FakeDevice(isLocalEmulator: true, platformType: PlatformType.android);

        testDeviceManager.devices = <Device>[device];

        final command = TestRunCommandThatOnlyValidates(toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--device-user', '10']);
        // Finishes normally without error.
      });

      test('shows unsupported devices when no supported devices are found', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        );
        final mockDevice = FakeDevice(
          targetPlatform: TargetPlatform.android_arm,
          isLocalEmulator: true,
          sdkNameAndVersion: 'api-14',
          isSupported: false,
        );
        testDeviceManager.devices = <Device>[mockDevice];
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);

        await expectLater(
          () => runner.run(<String>['run', '--no-pub', '--no-hot']),
          throwsA(isA<ToolExit>().having((ToolExit error) => error.message, 'message', isNull)),
        );

        expect(logger.statusText, containsIgnoringWhitespace('No supported devices connected.'));
        expect(
          logger.statusText,
          containsIgnoringWhitespace(
            'The following devices were found, but are not supported by this project:',
          ),
        );
        expect(
          logger.statusText,
          containsIgnoringWhitespace(
            UserMessages().flutterMissPlatformProjects(
              Device.devicesPlatformTypes(<Device>[mockDevice]),
            ),
          ),
        );
      });

      test('prints warning when --flavor is used with an unsupported target platform', () async {
        const runCommand = <String>['run', '--no-pub', '--no-hot', '--flavor=vanilla', '-d', 'all'];
        // Useful for test readability.
        // ignore: avoid_redundant_argument_values
        final deviceWithoutFlavorSupport = FakeDevice(supportsFlavors: false);
        final deviceWithFlavorSupport = FakeDevice(supportsFlavors: true);
        testDeviceManager.devices = <Device>[deviceWithoutFlavorSupport, deviceWithFlavorSupport];

        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
        await runner.run(runCommand);

        expect(
          logger.warningText,
          contains(
            '--flavor is only supported for Android, Linux, macOS, iOS, and Windows devices. '
            'Flavor-related features may not function properly and could '
            'behave differently in a future release.',
          ),
        );
      });

      test('forwards --uninstall-only to DebuggingOptions', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        );
        final mockDevice = FakeDevice(sdkNameAndVersion: 'iOS 13')..startAppSuccess = false;

        testDeviceManager.devices = <Device>[mockDevice];

        // Causes swift to be detected in the analytics.
        fs.currentDirectory
            .childDirectory('ios')
            .childFile('AppDelegate.swift')
            .createSync(recursive: true);

        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(command);
        await expectToolExitLater(
          runner.run(<String>['run', '--no-pub', '--no-hot', '--uninstall-first']),
          isNull,
        );

        final DebuggingOptions options = await command.createDebuggingOptions();
        expect(options.uninstallFirst, isTrue);
      });

      test('passes device target platform to analytics', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        );
        final mockDevice = FakeDevice(sdkNameAndVersion: 'iOS 13')..startAppSuccess = false;

        testDeviceManager.devices = <Device>[mockDevice];

        // Causes swift to be detected in the analytics.
        fs.currentDirectory
            .childDirectory('ios')
            .childFile('AppDelegate.swift')
            .createSync(recursive: true);

        final CommandRunner<void> runner = TestFlutterCommandRunner(
          analytics: fakeAnalytics,
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectToolExitLater(runner.run(<String>['run', '--no-pub', '--no-hot']), isNull);

        expect(
          fakeAnalytics.sentEvents,
          contains(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: fakeStdio.hasTerminal,
              runIsEmulator: false,
              runTargetName: 'ios',
              runTargetOsVersion: 'iOS 13',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: 'swift',
              runIOSInterfaceType: 'usb',
              runIsTest: false,
            ),
          ),
        );
      });

      test('correctly reports tests to analytics', () async {
        fs.currentDirectory
            .childDirectory('test')
            .childFile('widget_test.dart')
            .createSync(recursive: true);
        fs.currentDirectory
            .childDirectory('ios')
            .childFile('AppDelegate.swift')
            .createSync(recursive: true);
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
        );
        final mockDevice = FakeDevice(sdkNameAndVersion: 'iOS 13')..startAppSuccess = false;

        testDeviceManager.devices = <Device>[mockDevice];

        final CommandRunner<void> runner = TestFlutterCommandRunner(
          analytics: fakeAnalytics,
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectToolExitLater(
          runner.run(<String>['run', '--no-pub', '--no-hot', 'test/widget_test.dart']),
          isNull,
        );

        expect(
          fakeAnalytics.sentEvents,
          contains(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: fakeStdio.hasTerminal,
              runIsEmulator: false,
              runTargetName: 'ios',
              runTargetOsVersion: 'iOS 13',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: 'swift',
              runIOSInterfaceType: 'usb',
              runIsTest: true,
            ),
          ),
        );
      });

      group('--machine', () {
        late FakeToolContext machineToolContext;

        setUp(() {
          machineToolContext = FakeToolContext(
            artifacts: artifacts,
            fs: fs,
            logger: MachineOutputLogger(parent: logger),
            stdio: fakeStdio,
          );
        });

        test('can pass --device-user', () async {
          final command = DaemonCapturingRunCommand(
            toolContext: machineToolContext,
            appleContext: FakeAppleContext(),
          );
          final device = FakeDevice(platformType: PlatformType.android);
          testDeviceManager.devices = <Device>[device];
          final CommandRunner<void> runner = TestFlutterCommandRunner(
            deviceManager: testDeviceManager,
            toolContext: machineToolContext,
          )..addCommand(command);

          await expectLater(
            () => runner.run(<String>[
              'run',
              '--no-pub',
              '--machine',
              '--device-user',
              '10',
              '-d',
              device.id,
            ]),
            throwsToolExit(),
          );
          expect(command.appDomain.userIdentifier, '10');
        });

        group('web', () {
          late FakeWebRunnerFactory fakeWebRunnerFactory;

          setUp(() {
            fakeWebRunnerFactory = FakeWebRunnerFactory();
          });

          test('can pass --web-define', () async {
            final command = RunCommand(
              appleContext: FakeAppleContext(),
              buildSystem: TestBuildSystem.all(BuildResult(success: true)),
              assetBundleFactory: _FakeAssetBundleFactory(),
              buildTargets: const BuildTargetsImpl(),
              devtoolsLauncher: FakeDevtoolsLauncher(),
              toolContext: machineToolContext,
              webRunnerFactory: fakeWebRunnerFactory,
            );
            final device = FakeDevice(
              platformType: PlatformType.web,
              targetPlatform: TargetPlatform.web_javascript,
            );
            testDeviceManager.devices = <Device>[device];
            final CommandRunner<void> runner = TestFlutterCommandRunner(
              deviceManager: testDeviceManager,
              featureFlags: FakeFeatureFlags(),
              toolContext: machineToolContext,
            )..addCommand(command);

            await expectLater(
              () => runner.run(<String>[
                'run',
                '--no-pub',
                '--machine',
                '-d',
                device.id,
                '--web-define=NAME=VAL',
              ]),
              throwsToolExit(),
            );
            expect(fakeWebRunnerFactory.lastWebDefines, <String, String>{'NAME': 'VAL'});
          });
        });

        test('can disable devtools with --no-devtools', () async {
          final command = DaemonCapturingRunCommand(
            toolContext: machineToolContext,
            appleContext: FakeAppleContext(),
          );
          final device = FakeDevice();
          testDeviceManager.devices = <Device>[device];
          final CommandRunner<void> runner = TestFlutterCommandRunner(
            deviceManager: testDeviceManager,
            toolContext: machineToolContext,
          )..addCommand(command);

          await expectLater(
            () => runner.run(<String>[
              'run',
              '--no-pub',
              '--no-devtools',
              '--machine',
              '-d',
              device.id,
            ]),
            throwsToolExit(),
          );
          expect(command.appDomain.enableDevTools, isFalse);
        });
      });
    });

    group('Fatal Logs', () {
      late TestRunCommandWithFakeResidentRunner command;
      late MemoryFileSystem fs;
      late FakeToolContext toolContext;

      setUp(() {
        fs = MemoryFileSystem.test();
        toolContext = FakeToolContext(fs: fs, logger: logger);
        command = TestRunCommandWithFakeResidentRunner(toolContext: toolContext)
          ..fakeResidentRunner = FakeResidentRunner();
      });

      test("doesn't fail if --fatal-warnings specified and no warnings occur", () async {
        final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
          ..addCommand(command);
        try {
          await runner.run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
            '--${FlutterOptions.kFatalWarnings}',
          ]);
        } on Exception {
          fail('Unexpected exception thrown');
        }
      });

      test("doesn't fail if --fatal-warnings not specified", () async {
        logger.printWarning('Warning: Mild annoyance Will Robinson!');
        final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
          ..addCommand(command);
        try {
          await runner.run(<String>['run', '--no-pub', '--no-hot']);
        } on Exception {
          fail('Unexpected exception thrown');
        }
      });

      test('fails if --fatal-warnings specified and warnings emitted', () async {
        logger.printWarning('Warning: Mild annoyance Will Robinson!');
        final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
          ..addCommand(command);
        await expectLater(
          runner.run(<String>['run', '--no-pub', '--no-hot', '--${FlutterOptions.kFatalWarnings}']),
          throwsToolExit(
            message:
                'Logger received warning output during the run, and "--${FlutterOptions.kFatalWarnings}" is enabled.',
          ),
        );
      });

      test('fails if --fatal-warnings specified and errors emitted', () async {
        logger.printError('Error: Danger Will Robinson!');
        final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
          ..addCommand(command);
        await expectLater(
          runner.run(<String>['run', '--no-pub', '--no-hot', '--${FlutterOptions.kFatalWarnings}']),
          throwsToolExit(
            message:
                'Logger received error output during the run, and "--${FlutterOptions.kFatalWarnings}" is enabled.',
          ),
        );
      });
    });

    test('should only request artifacts corresponding to connected devices', () async {
      Future<Set<DevelopmentArtifact>> getRequiredArtifacts() {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        );
        TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        ).addCommand(command);
        return command.requiredArtifacts;
      }

      testDeviceManager.devices = <Device>[FakeDevice(targetPlatform: TargetPlatform.android_arm)];

      expect(
        await getRequiredArtifacts(),
        unorderedEquals(<DevelopmentArtifact>{
          DevelopmentArtifact.universal,
          DevelopmentArtifact.androidGenSnapshot,
        }),
      );

      testDeviceManager.devices = <Device>[FakeDevice()];

      expect(
        await getRequiredArtifacts(),
        unorderedEquals(<DevelopmentArtifact>{
          DevelopmentArtifact.universal,
          DevelopmentArtifact.iOS,
        }),
      );

      testDeviceManager.devices = <Device>[
        FakeDevice(),
        FakeDevice(targetPlatform: TargetPlatform.android_arm),
      ];

      expect(
        await getRequiredArtifacts(),
        unorderedEquals(<DevelopmentArtifact>{
          DevelopmentArtifact.universal,
          DevelopmentArtifact.iOS,
          DevelopmentArtifact.androidGenSnapshot,
        }),
      );

      testDeviceManager.devices = <Device>[
        FakeDevice(targetPlatform: TargetPlatform.web_javascript),
      ];

      expect(
        await getRequiredArtifacts(),
        unorderedEquals(<DevelopmentArtifact>{
          DevelopmentArtifact.universal,
          DevelopmentArtifact.web,
        }),
      );
    });

    group('usageValues', () {
      test('with only non-iOS usb device', () async {
        final devices = <Device>[
          FakeDevice(
            targetPlatform: TargetPlatform.android_arm,
            platformType: PlatformType.android,
          ),
        ];
        final command = TestRunCommandForUsageValues(devices: devices, toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run']),
          throwsToolExit(message: 'No pubspec.yaml file found'),
        );

        final analytics.Event usageValues = await command.unifiedAnalyticsUsageValues('run');

        expect(
          usageValues,
          equals(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: false,
              runIsEmulator: false,
              runTargetName: 'android-arm',
              runTargetOsVersion: '',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: '',
              runIsTest: false,
            ),
          ),
        );
      });

      test('with only iOS usb device', () async {
        final devices = <Device>[FakeIOSDevice(sdkNameAndVersion: 'iOS 16.2')];
        final command = TestRunCommandForUsageValues(devices: devices, toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run']),
          throwsToolExit(message: 'No pubspec.yaml file found'),
        );

        final analytics.Event usageValues = await command.unifiedAnalyticsUsageValues('run');

        expect(
          usageValues,
          equals(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: false,
              runIsEmulator: false,
              runTargetName: 'ios',
              runTargetOsVersion: 'iOS 16.2',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: '',
              runIOSInterfaceType: 'usb',
              runIsTest: false,
            ),
          ),
        );
      });

      test('with only iOS wireless device', () async {
        final devices = <Device>[
          FakeIOSDevice(
            connectionInterface: DeviceConnectionInterface.wireless,
            sdkNameAndVersion: 'iOS 16.2',
          ),
        ];
        final command = TestRunCommandForUsageValues(devices: devices, toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run']),
          throwsToolExit(message: 'No pubspec.yaml file found'),
        );

        final analytics.Event usageValues = await command.unifiedAnalyticsUsageValues('run');

        expect(
          usageValues,
          equals(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: false,
              runIsEmulator: false,
              runTargetName: 'ios',
              runTargetOsVersion: 'iOS 16.2',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: '',
              runIOSInterfaceType: 'wireless',
              runIsTest: false,
            ),
          ),
        );
      });

      test('with both iOS usb and wireless devices', () async {
        final devices = <Device>[
          FakeIOSDevice(
            connectionInterface: DeviceConnectionInterface.wireless,
            sdkNameAndVersion: 'iOS 16.2',
          ),
          FakeIOSDevice(sdkNameAndVersion: 'iOS 16.2'),
        ];
        final command = TestRunCommandForUsageValues(devices: devices, toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run']),
          throwsToolExit(message: 'No pubspec.yaml file found'),
        );

        final analytics.Event usageValues = await command.unifiedAnalyticsUsageValues('run');

        expect(
          usageValues,
          equals(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: false,
              runIsEmulator: false,
              runTargetName: 'multiple',
              runTargetOsVersion: 'multiple',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: '',
              runIOSInterfaceType: 'wireless',
              runIsTest: false,
            ),
          ),
        );
      });

      test('with Android device and android project reports runEnableHcpp', () async {
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('android/build.gradle').createSync(recursive: true);
        fileSystem.file('android/app/src/main/AndroidManifest.xml').createSync(recursive: true);
        fileSystem
            .file('android/app/src/main/AndroidManifest.xml')
            .writeAsStringSync(
              '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application><meta-data android:name="flutterEmbedding" android:value="2"/></application></manifest>',
            );
        final devices = <Device>[
          FakeDevice(targetPlatform: TargetPlatform.android, platformType: PlatformType.android),
        ];
        final command = TestRunCommandForUsageValues(devices: devices, toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(() => runner.run(<String>['run', '--no-pub']), throwsToolExit());

        final analytics.Event usageValues = await command.unifiedAnalyticsUsageValues('run');

        expect(
          usageValues,
          equals(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: false,
              runIsEmulator: false,
              runTargetName: 'android',
              runTargetOsVersion: '',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: 'java',
              runAndroidEmbeddingVersion: 'v2',
              runIsTest: false,
              runEnableHcpp: true,
            ),
          ),
        );
      });

      test('with Android device and android project reports runEnableHcpp false when --no-enable-hcpp is passed', () async {
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('android/build.gradle').createSync(recursive: true);
        fileSystem.file('android/app/src/main/AndroidManifest.xml').createSync(recursive: true);
        fileSystem
            .file('android/app/src/main/AndroidManifest.xml')
            .writeAsStringSync(
              '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application><meta-data android:name="flutterEmbedding" android:value="2"/></application></manifest>',
            );
        final devices = <Device>[
          FakeDevice(targetPlatform: TargetPlatform.android, platformType: PlatformType.android),
        ];
        final command = TestRunCommandForUsageValues(devices: devices, toolContext: toolContext);
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run', '--no-pub', '--no-enable-hcpp']),
          throwsToolExit(),
        );

        final analytics.Event usageValues = await command.unifiedAnalyticsUsageValues('run');

        expect(
          usageValues,
          equals(
            analytics.Event.commandUsageValues(
              workflow: 'run',
              commandHasTerminal: false,
              runIsEmulator: false,
              runTargetName: 'android',
              runTargetOsVersion: '',
              runModeName: 'debug',
              runProjectModule: false,
              runProjectHostLanguage: 'java',
              runAndroidEmbeddingVersion: 'v2',
              runIsTest: false,
              runEnableHcpp: false,
            ),
          ),
        );
      });
    });

    group('--web-header', () {
      late FakeWebRunnerFactory fakeWebRunnerFactory;

      setUp(() {
        fakeWebRunnerFactory = FakeWebRunnerFactory();

        fileSystem.file('lib/main.dart').createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "packages": [],
  "configVersion": 2
}
''');
        final device = FakeDevice(
          isLocalEmulator: true,
          platformType: PlatformType.web,
          targetPlatform: TargetPlatform.web_javascript,
        );
        testDeviceManager.devices = <Device>[device];
      });

      test('can accept simple, valid values', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--no-hot', '--web-header', 'foo=bar']);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.headers,
          <String, String>{'foo': 'bar'},
        );
      });

      test('throws a ToolExit when no value is provided', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
            '--no-resident',
            '--web-header',
            'foo',
          ]),
          throwsToolExit(message: 'Invalid web headers: foo'),
        );
      });

      test('throws a ToolExit when value includes delimiter characters', () async {
        fileSystem.file('lib/main.dart').createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('.dart_tool/package_config.json').createSync(recursive: true);

        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>[
            'run',
            '--no-pub',
            '--no-hot',
            '--no-resident',
            '--web-header',
            'hurray/headers=flutter',
          ]),
          throwsToolExit(message: 'Invalid web headers: hurray/headers=flutter'),
        );
      });

      test('throws a ToolExit when using --wasm on a non-web platform', () async {
        testDeviceManager.devices = <Device>[FakeDevice(platformType: PlatformType.android)];
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run', '--no-pub', '--no-resident', '--wasm']),
          throwsToolExit(message: '--wasm is only supported on the web platform'),
        );
      });

      test('throws a ToolExit when using the skwasm renderer without --wasm', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>[
            'run',
            '--no-pub',
            '--no-resident',
            ...WebRendererMode.skwasm.toCliDartDefines,
          ]),
          throwsToolExit(message: 'Skwasm renderer requires --wasm'),
        );
      });

      test('accepts headers with commas in them', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--web-header',
          'hurray=flutter,flutter=hurray',
        ]);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.headers,
          <String, String>{'hurray': 'flutter,flutter=hurray'},
        );
      });
    });

    group('CLI precedence over web_dev_config.yaml', () {
      late FakeWebRunnerFactory fakeWebRunnerFactory;

      setUp(() {
        fakeWebRunnerFactory = FakeWebRunnerFactory();

        fileSystem.file('lib/main.dart').createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "packages": [],
  "configVersion": 2
}
''');
        final device = FakeDevice(
          isLocalEmulator: true,
          platformType: PlatformType.web,
          targetPlatform: TargetPlatform.web_javascript,
        );
        testDeviceManager.devices = <Device>[device];
      });

      test('CLI --web-port overrides web_dev_config.yaml port', () async {
        fileSystem.file('web_dev_config.yaml').writeAsStringSync('''
server:
  host: confighost
  port: 9000
''');
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--no-hot', '--web-port=8080']);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.port, 8080);
      });

      test('CLI --web-hostname overrides web_dev_config.yaml host', () async {
        fileSystem.file('web_dev_config.yaml').writeAsStringSync('''
server:
  host: confighost
  port: 9000
''');
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--no-hot', '--web-hostname=clihost']);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.host, 'clihost');
      });

      test('CLI --web-header overrides web_dev_config.yaml headers', () async {
        fileSystem.file('web_dev_config.yaml').writeAsStringSync('''
server:
  host: any
  port: 9000
  headers:
    - name: X-Config-Header
      value: config-value
    - name: X-Shared-Header
      value: from-config
''');
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--web-header=X-Shared-Header=from-cli',
          '--web-header=X-Cli-Header=cli-value',
        ]);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        final Map<String, String> headers =
            fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.headers;
        // CLI headers override file config headers with same name
        expect(headers['X-Shared-Header'], 'from-cli');
        // CLI-only headers are included
        expect(headers['X-Cli-Header'], 'cli-value');
        // File config headers are preserved if not overridden
        expect(headers['X-Config-Header'], 'config-value');
      });

      test('uses web_dev_config.yaml values when CLI args not provided', () async {
        fileSystem.file('web_dev_config.yaml').writeAsStringSync('''
server:
  host: confighost
  port: 9000
''');
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--no-hot']);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.host, 'confighost');
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.port, 9000);
      });

      test('CLI TLS cert args override web_dev_config.yaml https config', () async {
        fileSystem.file('web_dev_config.yaml').writeAsStringSync('''
server:
  host: any
  port: 9000
  https:
    cert-path: /config/cert.pem
    cert-key-path: /config/key.pem
''');
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--web-tls-cert-path=/cli/cert.pem',
          '--web-tls-cert-key-path=/cli/key.pem',
        ]);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https, isNotNull);
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https!.certPath,
          '/cli/cert.pem',
        );
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https!.certKeyPath,
          '/cli/key.pem',
        );
      });

      test('CLI TLS cert path with file config key path creates valid HTTPS config', () async {
        fileSystem.file('web_dev_config.yaml').writeAsStringSync('''
server:
  host: any
  port: 9000
  https:
    cert-path: /config/cert.pem
    cert-key-path: /config/key.pem
''');
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--web-tls-cert-path=/cli/cert.pem',
        ]);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https, isNotNull);
        // CLI cert path overrides file config
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https!.certPath,
          '/cli/cert.pem',
        );
        // File config key path is used as fallback
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https!.certKeyPath,
          '/config/key.pem',
        );
      });

      test('CLI TLS args work without web_dev_config.yaml file', () async {
        // No web_dev_config.yaml file exists
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>[
          'run',
          '--no-pub',
          '--no-hot',
          '--web-tls-cert-path=/cli/cert.pem',
          '--web-tls-cert-key-path=/cli/key.pem',
        ]);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https, isNotNull);
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https!.certPath,
          '/cli/cert.pem',
        );
        expect(
          fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.https!.certKeyPath,
          '/cli/key.pem',
        );
      });
    });

    group('--base-href', () {
      late FakeWebRunnerFactory fakeWebRunnerFactory;

      setUp(() {
        fakeWebRunnerFactory = FakeWebRunnerFactory();

        fileSystem.file('lib/main.dart').createSync(recursive: true);
        fileSystem.file('pubspec.yaml').createSync();
        fileSystem.file('.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "packages": [],
  "configVersion": 2
}
''');
        final device = FakeDevice(
          isLocalEmulator: true,
          platformType: PlatformType.web,
          targetPlatform: TargetPlatform.web_javascript,
        );
        testDeviceManager.devices = <Device>[device];
      });

      test('passes base-href to WebDevServerConfig', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--no-hot', '--base-href=/preview/']);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.baseHref, '/preview/');
      });

      test('throws ToolExit when base-href does not start with /', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run', '--no-pub', '--no-hot', '--base-href=preview/']),
          throwsToolExit(message: '--base-href should start and end with /'),
        );
      });

      test('throws ToolExit when base-href does not end with /', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await expectLater(
          () => runner.run(<String>['run', '--no-pub', '--no-hot', '--base-href=/preview']),
          throwsToolExit(message: '--base-href should start and end with /'),
        );
      });

      test('base-href defaults to null when not provided', () async {
        final command = RunCommand(
          appleContext: FakeAppleContext(),
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          assetBundleFactory: _FakeAssetBundleFactory(),
          buildTargets: const BuildTargetsImpl(),
          devtoolsLauncher: FakeDevtoolsLauncher(),
          toolContext: toolContext,
          webRunnerFactory: fakeWebRunnerFactory,
        );
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          featureFlags: FakeFeatureFlags(),
          toolContext: toolContext,
        )..addCommand(command);
        await runner.run(<String>['run', '--no-pub', '--no-hot']);

        expect(fakeWebRunnerFactory.lastOptions, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig, isNotNull);
        expect(fakeWebRunnerFactory.lastOptions!.webConfig.devServerConfig!.baseHref, isNull);
      });
    });
  });

  group('terminal', () {
    late FakeAnsiTerminal fakeTerminal;
    late FakeToolContext toolContext;

    setUp(() {
      fakeTerminal = FakeAnsiTerminal();
      toolContext = FakeToolContext(fs: MemoryFileSystem.test(), terminal: fakeTerminal);
    });

    test('Flutter run sets terminal singleCharMode to false on exit', () async {
      final residentRunner = FakeResidentRunner();
      final command = TestRunCommandWithFakeResidentRunner(toolContext: toolContext);
      command.fakeResidentRunner = residentRunner;
      final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
        ..addCommand(command);

      await runner.run(<String>['run', '--no-pub']);
      // The sync completer where we initially set `terminal.singleCharMode` to
      // `true` does not execute in unit tests, so explicitly check the
      // `setSingleCharModeHistory` that the finally block ran, setting this
      // back to `false`.
      expect(fakeTerminal.setSingleCharModeHistory, contains(false));
    });

    test(
      'Flutter run catches StdinException while setting terminal singleCharMode to false',
      () async {
        fakeTerminal.hasStdin = false;
        final residentRunner = FakeResidentRunner();
        final command = TestRunCommandWithFakeResidentRunner(toolContext: toolContext);
        command.fakeResidentRunner = residentRunner;
        final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
          ..addCommand(command);

        try {
          await runner.run(<String>['run', '--no-pub']);
        } catch (err) {
          fail('Expected no error, got $err');
        }
        expect(fakeTerminal.setSingleCharModeHistory, isEmpty);
      },
    );
  });

  test('Flutter run catches catches errors due to vm service disconnection by text and throws a tool exit', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
    final residentRunner = FakeResidentRunner();
    residentRunner.rpcError = RPCError(
      'flutter._listViews',
      RPCErrorKind.kServiceDisappeared.code,
      '',
    );
    final command = TestRunCommandWithFakeResidentRunner(toolContext: toolContext);
    command.fakeResidentRunner = residentRunner;
    final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
      ..addCommand(command);

    await expectToolExitLater(
      runner.run(<String>['run', '--no-pub']),
      contains('Lost connection to device.'),
    );

    residentRunner.rpcError = RPCError(
      'flutter._listViews',
      RPCErrorKind.kServerError.code,
      'Service connection disposed.',
    );

    await expectToolExitLater(
      runner.run(<String>['run', '--no-pub']),
      contains('Lost connection to device.'),
    );
  });

  test('Flutter run catches catches errors due to vm service disconnection by code and throws a tool exit', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
    final residentRunner = FakeResidentRunner();
    residentRunner.rpcError = RPCError(
      'flutter._listViews',
      RPCErrorKind.kServiceDisappeared.code,
      '',
    );
    final command = TestRunCommandWithFakeResidentRunner(toolContext: toolContext);
    command.fakeResidentRunner = residentRunner;
    final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
      ..addCommand(command);

    await expectToolExitLater(
      runner.run(<String>['run', '--no-pub']),
      contains('Lost connection to device.'),
    );

    residentRunner.rpcError = RPCError(
      'flutter._listViews',
      RPCErrorKind.kConnectionDisposed.code,
      'dummy text not matched.',
    );

    await expectToolExitLater(
      runner.run(<String>['run', '--no-pub']),
      contains('Lost connection to device.'),
    );
  });

  test('Flutter run does not catch other RPC errors', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
    final residentRunner = FakeResidentRunner();
    residentRunner.rpcError = RPCError('flutter._listViews', RPCErrorKind.kInvalidParams.code, '');
    final command = TestRunCommandWithFakeResidentRunner(toolContext: toolContext);
    command.fakeResidentRunner = residentRunner;
    final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
      ..addCommand(command);

    await expectLater(() => runner.run(<String>['run', '--no-pub']), throwsA(isA<RPCError>()));
  });

  test('Configures web connection options to use web sockets by default', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
    final command = RunCommand(
      appleContext: FakeAppleContext(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      assetBundleFactory: _FakeAssetBundleFactory(),
      buildTargets: const BuildTargetsImpl(),
      devtoolsLauncher: FakeDevtoolsLauncher(),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = TestFlutterCommandRunner(
      featureFlags: FakeFeatureFlags(),
      toolContext: toolContext,
    )..addCommand(command);
    await expectLater(() => runner.run(<String>['run', '--no-pub']), throwsToolExit());

    final DebuggingOptions options = await command.createDebuggingOptions();

    expect(options.webConfig.useSseForDebugBackend, false);
    expect(options.webConfig.useSseForDebugProxy, false);
    expect(options.webConfig.useSseForInjectedClient, false);
  });

  test('flags propagate to debugging options', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
    final command = RunCommand(
      appleContext: FakeAppleContext(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      assetBundleFactory: _FakeAssetBundleFactory(),
      buildTargets: const BuildTargetsImpl(),
      devtoolsLauncher: FakeDevtoolsLauncher(),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
      ..addCommand(command);
    await expectLater(
      () => runner.run(<String>[
        'run',
        '--start-paused',
        '--disable-service-auth-codes',
        '--disable-service-origin-check',
        '--use-test-fonts',
        '--trace-skia',
        '--trace-systrace',
        '--trace-to-file=path/to/trace.binpb',
        '--profile-microtasks',
        '--profile-startup',
        '--verbose-system-logs',
        '--native-null-assertions',
        '--enable-impeller',
        '--enable-flutter-gpu',
        '--enable-vulkan-validation',
        '--trace-systrace',
        '--enable-software-rendering',
        '--skia-deterministic-rendering',
        '--enable-embedder-api',
        '--ci',
        '--debug-logs-dir=path/to/logs',
      ]),
      throwsToolExit(),
    );

    final DebuggingOptions options = await command.createDebuggingOptions();

    expect(options.startPaused, true);
    expect(options.disableServiceAuthCodes, true);
    expect(options.disableServiceOriginCheck, true);
    expect(options.useTestFonts, true);
    expect(options.traceSkia, true);
    expect(options.traceSystrace, true);
    expect(options.traceToFile, 'path/to/trace.binpb');
    expect(options.profileMicrotasks, true);
    expect(options.profileStartup, true);
    expect(options.verboseSystemLogs, true);
    expect(options.webConfig.nativeNullAssertions, true);
    expect(options.traceSystrace, true);
    expect(options.enableImpeller, ImpellerStatus.enabled);
    expect(options.enableFlutterGpu, true);
    expect(options.enableVulkanValidation, true);
    expect(options.enableSoftwareRendering, true);
    expect(options.skiaDeterministicRendering, true);
    expect(options.usingCISystem, true);
    expect(options.debugLogsDirectoryPath, 'path/to/logs');
  });

  test('usingCISystem can also be set by environment LUCI_CI', () async {
    final toolContext = FakeToolContext(
      fs: MemoryFileSystem.test(),
      platform: FakePlatform(environment: <String, String>{'LUCI_CI': 'True'}),
    );
    final command = RunCommand(
      appleContext: FakeAppleContext(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      assetBundleFactory: _FakeAssetBundleFactory(),
      buildTargets: const BuildTargetsImpl(),
      devtoolsLauncher: FakeDevtoolsLauncher(),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
      ..addCommand(command);
    await expectLater(() => runner.run(<String>['run']), throwsToolExit());

    final DebuggingOptions options = await command.createDebuggingOptions();

    expect(options.usingCISystem, true);
  });

  test('wasm mode selects skwasm renderer by default', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test());
    final command = RunCommand(
      appleContext: FakeAppleContext(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      assetBundleFactory: _FakeAssetBundleFactory(),
      buildTargets: const BuildTargetsImpl(),
      devtoolsLauncher: FakeDevtoolsLauncher(),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = TestFlutterCommandRunner(toolContext: toolContext)
      ..addCommand(command);
    await expectLater(() => runner.run(<String>['run', '-d chrome', '--wasm']), throwsToolExit());

    final DebuggingOptions options = await command.createDebuggingOptions();

    expect(options.webConfig.useWasm, true);
    expect(options.webConfig.renderer, WebRendererMode.skwasm);
  });

  test('fails when "--web-launch-url" is not supported', () async {
    final toolContext = FakeToolContext(fs: MemoryFileSystem.test(), logger: BufferLogger.test());
    final command = RunCommand(
      appleContext: FakeAppleContext(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      assetBundleFactory: _FakeAssetBundleFactory(),
      buildTargets: const BuildTargetsImpl(),
      devtoolsLauncher: FakeDevtoolsLauncher(),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = TestFlutterCommandRunner(
      featureFlags: FakeFeatureFlags(),
      toolContext: toolContext,
    )..addCommand(command);
    await expectLater(
      () => runner.run(<String>['run', '--web-launch-url=http://flutter.dev']),
      throwsA(
        isException.having(
          (Exception exception) => exception.toString(),
          'toString',
          isNot(contains('web-launch-url')),
        ),
      ),
    );

    final DebuggingOptions options = await command.createDebuggingOptions();
    expect(options.webConfig.launchUrl, 'http://flutter.dev');

    final pattern = RegExp(r'^((http)?:\/\/)[^\s]+');
    expect(pattern.hasMatch(options.webConfig.launchUrl!), true);
  });

  group('run --web-experimental-hot-reload flag', () {
    late BufferLogger logger;
    late TestDeviceManager testDeviceManager;
    late FileSystem fileSystem;
    late FakeToolContext toolContext;

    setUp(() {
      logger = BufferLogger.test();

      final fakeDevice = FakeDevice();
      testDeviceManager = TestDeviceManager(logger: logger)..devices = <Device>[fakeDevice];
      testDeviceManager.specifiedDeviceId = fakeDevice.id;

      fileSystem = MemoryFileSystem.test();
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      final Directory libDir = fileSystem.currentDirectory.childDirectory('lib');
      libDir.createSync();
      final File mainFile = libDir.childFile('main.dart');
      mainFile.writeAsStringSync('void main() {}');
      toolContext = FakeToolContext(fs: fileSystem, logger: logger);
    });
    // TODO(nshahan): Safe to remove after
    // https://github.com/flutter/flutter/issues/142060.
    test('no warning triggered when web hot reload flag not present', () async {
      final CommandRunner<void> runner = TestFlutterCommandRunner(
        deviceManager: testDeviceManager,
        toolContext: toolContext,
      )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
      await runner.run(<String>['run']);
      expect(logger.warningText, isEmpty);
    });

    test(
      'warning triggered when web hot reload flag is passed (enabled)',
      () async {
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
        await runner.run(<String>['run', '--web-experimental-hot-reload']);
        expect(
          logger.warningText,
          contains(
            'Hot reload on the web is now enabled by default. '
            'The "--web-experimental-hot-reload" flag is deprecated '
            'and will be removed in an upcoming release.',
          ),
        );
      },
      // https://github.com/flutter/flutter/issues/142060
      skip: true,
    );

    test(
      'warning triggered when web hot reload flag is passed (disabled)',
      () async {
        final CommandRunner<void> runner = TestFlutterCommandRunner(
          deviceManager: testDeviceManager,
          toolContext: toolContext,
        )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
        await runner.run(<String>['run', '--no-web-experimental-hot-reload']);

        expect(
          logger.warningText,
          contains(
            'Hot reload on the web is now enabled by default. '
            'The "--no-web-experimental-hot-reload" flag is deprecated '
            'and will be removed in an upcoming release. '
            'If your web development workflow depends on disabling hot reload, '
            'please open an issue explaining why at '
            'https://github.com/dart-lang/sdk/issues/new?template=5_web_hot_reload.yml.',
          ),
        );
      },
      // https://github.com/flutter/flutter/issues/142060
      skip: true,
    );

    test('warning triggered when --build flag is passed', () async {
      final CommandRunner<void> runner = TestFlutterCommandRunner(
        deviceManager: testDeviceManager,
        toolContext: toolContext,
      )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
      await runner.run(<String>['run', '--build']);

      expect(
        logger.warningText,
        contains(
          'The "--build" flag is deprecated and will be removed in a future release. '
          'Building is the default behavior, so this flag can be safely removed.',
        ),
      );
    });

    test('warning triggered when --no-build flag is passed', () async {
      final CommandRunner<void> runner = TestFlutterCommandRunner(
        deviceManager: testDeviceManager,
        toolContext: toolContext,
      )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
      await runner.run(<String>['run', '--no-build']);

      expect(
        logger.warningText,
        contains(
          'The "--no-build" flag is deprecated and will be removed in a future release. '
          'To use a prebuilt application, pass "--${FlutterOptions.kUseApplicationBinary}".',
        ),
      );
    });

    test('no warning triggered when --build or --no-build flag is not passed', () async {
      final CommandRunner<void> runner = TestFlutterCommandRunner(
        deviceManager: testDeviceManager,
        toolContext: toolContext,
      )..addCommand(TestRunCommandThatOnlyValidates(toolContext: toolContext));
      await runner.run(<String>['run']);

      expect(logger.warningText, isNot(contains('is deprecated')));
    });
  });

  test('RunCommand registers --flavor, --track-widget-creation, and AndroidGradleOptionsBundle without AndroidBuildOptionsBundle flags', () {
    final command = RunCommand(
      appleContext: FakeAppleContext(),
      assetBundleFactory: _FakeAssetBundleFactory(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      buildTargets: const BuildTargetsImpl(),
      devtoolsLauncher: FakeDevtoolsLauncher(),
      toolContext: FakeToolContext(),
    );

    expect(command.argParser.options, contains('flavor'));
    expect(command.argParser.options, contains('track-widget-creation'));
    expect(command.argParser.options, contains('android-gradle-daemon'));
    expect(command.argParser.options, isNot(contains('shrink')));
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager({required super.logger, FileSystem? fileSystem})
    : super(fileSystem: fileSystem ?? MemoryFileSystem.test());
  List<Device> devices = <Device>[];

  @override
  List<DeviceDiscovery> get deviceDiscoverers {
    final discoverer = FakePollingDeviceDiscovery();
    devices.forEach(discoverer.addDevice);
    return <DeviceDiscovery>[discoverer];
  }
}

class FakeDevice extends Fake implements Device {
  FakeDevice({
    this._isLocalEmulator = false,
    this._targetPlatform = TargetPlatform.ios,
    this._sdkNameAndVersion = '',
    this._platformType = PlatformType.ios,
    this._isSupported = true,
    this._supportsFlavors = false,
  });

  static const kSuccess = 1;
  static const kFailure = -1;
  final TargetPlatform _targetPlatform;
  final bool _isLocalEmulator;
  final String _sdkNameAndVersion;
  final PlatformType _platformType;
  final bool _isSupported;
  final bool _supportsFlavors;

  @override
  Category get category => Category.mobile;

  @override
  String get id => 'fake_device';

  Never _throwToolExit(int code) => throwToolExit('FakeDevice tool exit', exitCode: code);

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
  bool get supportsFlavors => _supportsFlavors;

  @override
  bool get ephemeral => true;

  @override
  bool get isConnected => true;

  @override
  DeviceConnectionInterface get connectionInterface => DeviceConnectionInterface.attached;

  bool supported = true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => _isSupported;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value(_sdkNameAndVersion);

  @override
  Future<String> get targetPlatformDisplayName async => (await targetPlatform).getName();

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) {
    return FakeDeviceLogReader();
  }

  @override
  String get name => 'FakeDevice';

  @override
  String get displayName => name;

  // THIS IS A KEY FIX
  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  PlatformType get platformType => _platformType;

  late bool startAppSuccess;

  @override
  DevFSWriter? createDevFSWriter(ApplicationPackage? app, String? userIdentifier) {
    return null;
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    if (!startAppSuccess) {
      return LaunchResult.failed();
    }
    if (startAppSuccess) {
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
  }
}

class FakeIOSDevice extends Fake implements IOSDevice {
  FakeIOSDevice({
    this.connectionInterface = DeviceConnectionInterface.attached,
    this._isLocalEmulator = false,
    this._sdkNameAndVersion = '',
  });

  final bool _isLocalEmulator;
  final String _sdkNameAndVersion;

  @override
  Future<bool> get isLocalEmulator => Future<bool>.value(_isLocalEmulator);

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value(_sdkNameAndVersion);

  @override
  final DeviceConnectionInterface connectionInterface;

  @override
  bool get isWirelesslyConnected => connectionInterface == DeviceConnectionInterface.wireless;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;
}

class TestRunCommandForUsageValues extends RunCommand {
  TestRunCommandForUsageValues({
    required super.toolContext,
    AppleContext? appleContext,
    List<Device>? devices,
  }) : super(
         appleContext: appleContext ?? FakeAppleContext(),
         buildSystem: TestBuildSystem.all(BuildResult(success: true)),
         assetBundleFactory: _FakeAssetBundleFactory(),
         buildTargets: const BuildTargetsImpl(),
         devtoolsLauncher: FakeDevtoolsLauncher(),
       ) {
    this.devices = devices;
  }

  @override
  Future<BuildInfo> getBuildInfo({
    FlutterProject? project,
    BuildMode? forcedBuildMode,
    File? forcedTargetFile,
    bool? forcedUseLocalCanvasKit,
    bool? forcedWebEnableHotReload,
  }) async {
    return const BuildInfo(
      BuildMode.debug,
      null,
      treeShakeIcons: false,
      packageConfigPath: '.dart_tool/package_config.json',
    );
  }
}

class TestRunCommandWithFakeResidentRunner extends RunCommand {
  TestRunCommandWithFakeResidentRunner({required super.toolContext, AppleContext? appleContext})
    : super(
        appleContext: appleContext ?? FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
      );

  late FakeResidentRunner fakeResidentRunner;

  @override
  Future<ResidentRunner> createRunner({
    required bool hotMode,
    required List<FlutterDevice> flutterDevices,
    required String? applicationBinaryPath,
    required FlutterProject flutterProject,
  }) async {
    return fakeResidentRunner;
  }

  @override
  // ignore: must_call_super
  Future<void> validateCommand() async {
    devices = <Device>[FakeDevice()..supportsHotReload = true];
  }
}

class TestRunCommandThatOnlyValidates extends RunCommand {
  TestRunCommandThatOnlyValidates({required super.toolContext, AppleContext? appleContext})
    : super(
        appleContext: appleContext ?? FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
      );

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }

  @override
  bool get shouldRunPub => false;
}

class FakeResidentRunner extends Fake implements ResidentRunner {
  RPCError? rpcError;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo>? connectionInfoCompleter,
    Completer<void>? appStartedCompleter,
    bool enableDevTools = false,
    String? route,
  }) async {
    await null;
    if (rpcError != null) {
      throw rpcError!;
    }
    return 0;
  }

  @override
  DebuggingOptions get debuggingOptions {
    throwToolExit('');
  }
}

class DaemonCapturingRunCommand extends RunCommand {
  DaemonCapturingRunCommand({required super.toolContext, AppleContext? appleContext})
    : super(
        appleContext: appleContext ?? FakeAppleContext(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildTargets: const BuildTargetsImpl(),
        devtoolsLauncher: FakeDevtoolsLauncher(),
      );

  late Daemon daemon;
  late CapturingAppDomain appDomain;

  @override
  Daemon createMachineDaemon() {
    daemon = super.createMachineDaemon();
    appDomain = daemon.appDomain = CapturingAppDomain(daemon, toolContext: toolContext);
    daemon.registerDomain(appDomain);
    return daemon;
  }
}

class CapturingAppDomain extends AppDomain {
  CapturingAppDomain(super.daemon, {required ToolContext toolContext})
    : super(
        analytics: const analytics.NoOpAnalytics(),
        applicationPackageFactory: FlutterApplicationPackageFactory(
          androidSdkBuilder: () => null,
          plistParserBuilder: FakePlistParser.new,
          templatePathProvider: const TemplatePathProvider(flutterRoot: ''),
          toolContext: toolContext,
        ),
        assetBundleFactory: _FakeAssetBundleFactory(),
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        buildTargets: const BuildTargetsImpl(),
        featureFlags: TestFeatureFlags(),
        xcode: null,
      );

  String? userIdentifier;
  bool? enableDevTools;

  @override
  Future<AppInstance> startApp(
    Device device,
    String projectDirectory,
    String target,
    String? route,
    DebuggingOptions options,
    bool enableHotReload, {
    File? applicationBinary,
    required bool trackWidgetCreation,
    String? projectRootPath,
    String? packagesFilePath,
    String? dillOutputPath,
    String? isolateFilter,
    bool machine = true,
    String? userIdentifier,
  }) async {
    this.userIdentifier = userIdentifier;
    enableDevTools = options.enableDevTools;
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
      throw const StdinException(
        'Error setting terminal line mode',
        OSError('The handle is invalid', 6),
      );
    }
    setSingleCharModeHistory.add(value);
  }

  @override
  bool get singleCharMode => setSingleCharModeHistory.last;
}

/// A Fake that implements FeatureFlags and enables web.
class FakeFeatureFlags extends Fake implements FeatureFlags {
  @override
  bool get isWebEnabled => true;

  @override
  bool get isToolExtensionsEnabled => false;

  @override
  bool isEnabled(Feature feature) => feature.master.enabledByDefault;

  // Queried by getBuildInfo.
  @override
  bool get isHcppEnabled => isEnabled(hcpp);

  @override
  List<Feature> get allFeatures => const <Feature>[];
}

/// A Fake WebRunnerFactory that CAPTURES the debugging options passed to it.
class FakeWebRunnerFactory extends Fake implements WebRunnerFactory {
  DebuggingOptions? lastOptions;
  Map<String, String>? lastWebDefines;

  @override
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    required analytics.Analytics analytics,
    required ApplicationPackageFactory applicationPackageFactory,
    required AssetBundleFactory assetBundleFactory,
    required BuildSystem buildSystem,
    required BuildTargets buildTargets,
    required DebuggingOptions debuggingOptions,
    required FeatureFlags featureFlags,
    required FlutterProject flutterProject,
    required bool stayResident,
    required ToolContext toolContext,
    FlutterHookRunner? flutterHookRunner,
    bool machine = false,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    String? target,
    Future<String> Function(String)? urlTunneller,
  }) {
    lastOptions = debuggingOptions;
    lastWebDefines = debuggingOptions.webConfig.webDefines;
    return FakeResidentRunner();
  }
}

class _FakeAssetBundleFactory extends Fake implements AssetBundleFactory {
  @override
  AssetBundle createBundle() => AssetBundleFactory.defaultInstance(
    fileSystem: MemoryFileSystem.test(),
    flutterRoot: '',
    logger: BufferLogger.test(),
    platform: FakePlatform(),
  ).createBundle();
}
