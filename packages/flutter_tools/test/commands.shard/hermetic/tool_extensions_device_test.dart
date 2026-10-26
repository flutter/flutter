// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart'
    show
        BuiltInPlaceholders,
        ExtensionBuildResult,
        ExtensionDebuggingOptions,
        ExtensionFlutterProject,
        TargetDevice;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget({
    required super.description,
    required this.name,
    this.errorMessage,
    this.executableUri,
    super.outputDir = '${BuiltInPlaceholders.outputDir}/custom',
    this.shouldSucceed = true,
    super.targetPlatform = 'linux-x64',
  });

  @override
  final String name;

  final String? errorMessage;
  final Uri? executableUri;
  final bool shouldSucceed;

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return shouldSucceed
        ? ExtensionBuildResult(success: true, executableUri: executableUri)
        : ExtensionBuildResult(success: false, errorMessage: errorMessage ?? 'Build failed.');
  }
}

final class _FakeTestBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[
    _TestBuildTarget(
      description: 'Fake test build target',
      name: 'fake-test-build',
      executableUri: Uri.parse('file:///tmp/fake_bundle/app'),
    ),
    const _TestBuildTarget(
      description: 'Fake failing build target',
      name: 'fake-failing-build',
      shouldSucceed: false,
      errorMessage: 'Simulated build error',
    ),
  ];
}

final class _FakeTestDeviceService extends DeviceService {
  final _runningDevices = <String>{};

  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        category: Category.desktop,
        id: 'fake_test_device',
        name: 'Fake Test Extension Device',
        buildTarget: 'fake-test-build',
        ephemeral: false,
        sdkNameAndVersion: 'Fake OS 1.0',
        targetPlatform: 'linux-x64',
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'no_target_device',
        name: 'No Target Device',
        ephemeral: false,
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'failing_build_device',
        name: 'Failing Build Device',
        buildTarget: 'fake-failing-build',
        ephemeral: false,
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'failing_launch_device',
        name: 'Failing Launch Device',
        buildTarget: 'fake-test-build',
        ephemeral: false,
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'missing_vm_service_device',
        name: 'Missing VM Service Device',
        buildTarget: 'fake-test-build',
        ephemeral: false,
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => deviceId == 'fake_test_device';

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async {
    if (deviceId == 'fake_test_device') {
      final bool launched =
          executableUri == Uri.file('/tmp/fake_bundle/app') &&
          debuggingOptions ==
              const ExtensionDebuggingOptions(buildMode: .debug, debuggingEnabled: true);
      if (launched) {
        _runningDevices.add(deviceId);
      }
      return launched;
    }
    if (deviceId == 'missing_vm_service_device') {
      final launched = executableUri == Uri.file('/tmp/fake_bundle/app');
      if (launched) {
        _runningDevices.add(deviceId);
      }
      return launched;
    }
    return false;
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async =>
      deviceId == 'fake_test_device' ? Uri.parse('http://127.0.0.1:8181/abcd=/') : null;

  @override
  Future<bool> stopApp({required String deviceId}) async => _runningDevices.remove(deviceId);
}

void _fakeLaunchExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_FakeTestBuildService(), _FakeTestDeviceService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Tool Extensions Device Integration - Disabled', () {
    testUsingContext(
      'ExtensionDevices returns empty device list when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final discovery = ExtensionDevices(
          extensionBuildManager: ExtensionBuildManager(
            extensionManager: manager,
            featureFlags: featureFlags,
            logger: testLogger,
          ),
          extensionManager: manager,
          fileSystem: MemoryFileSystem.test(),
          logger: testLogger,
        );

        final List<Device> devices = await discovery.devices();
        expect(devices, isEmpty);

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'DevicesCommand output does not include custom extension devices when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final testDeviceManager = TestDeviceManager(
          discoverers: <DeviceDiscovery>[
            ExtensionDevices(
              extensionBuildManager: ExtensionBuildManager(
                extensionManager: manager,
                featureFlags: featureFlags,
                logger: testLogger,
              ),
              extensionManager: manager,
              fileSystem: MemoryFileSystem.test(),
              logger: testLogger,
            ),
          ],
        );
        final devicesCommand = DevicesCommand(
          deviceManager: testDeviceManager,
          doctor: FakeDoctor(),
          toolContext: FakeToolContext(logger: testLogger),
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(devicesCommand);

        await commandRunner.run(<String>['devices']);
        expect(testLogger.statusText, isNot(contains('Linux Custom Extension Prototype Device')));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(),
        DeviceManager: () => TestDeviceManager(),
      },
    );
  });

  group('Tool Extensions Device Integration - Enabled', () {
    testWithoutContext(
      'FlutterProject.toExtensionProject extracts project and manifest metadata',
      () async {
        final fs = MemoryFileSystem.test();
        final Directory tempDir = fs.systemTempDirectory.createTempSync(
          'flutter_tool_extensions_project_test.',
        );
        tempDir.childFile('pubspec.yaml').writeAsStringSync('''
name: sample_app
version: 2.1.0+5
workspace:
  - packages/sub_pkg
dependencies:
  flutter:
    sdk: flutter
  path: ^1.9.0
flutter:
  module:
    androidX: true
''');

        final FlutterProject project = FlutterProject.fromDirectoryTest(
          tempDir,
          BufferLogger.test(),
        );
        final ExtensionFlutterProject extProject = project.toExtensionProject();

        expect(extProject.appName, 'sample_app');
        expect(extProject.appVersion, '2.1.0+5');
        expect(extProject.directory, project.directory.uri);
        expect(extProject.buildDirectory, project.buildDirectory.uri);
        expect(extProject.dependencies, <String>{'flutter', 'path'});
        expect(extProject.isEmpty, isFalse);
        expect(extProject.isModule, isTrue);
        expect(extProject.isPlugin, isFalse);
        expect(extProject.workspace, <String>['packages/sub_pkg']);
        expect(extProject.workspace.runtimeType, <String>[].runtimeType);
        expect(() => jsonEncode(extProject.toMap()), returnsNormally);
      },
    );

    testUsingContext(
      'ExtensionDevices discovers custom device when feature flag enabled',
      () async {
        final localFs = LocalFileSystem.test(signals: LocalSignals.instance);
        addTearDown(localFs.dispose);
        final Directory tempDir = localFs.systemTempDirectory.createTempSync(
          'flutter_tool_extensions_device_test.',
        );

        final projectFactory = FlutterProjectFactory(fileSystem: localFs, logger: testLogger);
        final FlutterProject project = projectFactory.fromDirectory(tempDir);

        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final discovery = ExtensionDevices(
          extensionBuildManager: ExtensionBuildManager(
            extensionManager: manager,
            featureFlags: featureFlags,
            logger: testLogger,
          ),
          extensionManager: manager,
          fileSystem: localFs,
          logger: testLogger,
        );

        final List<Device> devices = await discovery.devices();
        expect(devices, hasLength(1));
        expect(devices.first.id, equals('custom_linux_device'));
        expect(devices.first.name, equals('Linux Custom Extension Prototype Device'));
        expect(devices.first.category, equals(Category.desktop));
        expect(devices.first.platformType, equals(PlatformType.custom));
        expect(await devices.first.targetPlatform, equals(TargetPlatform.linux_x64));
        expect(await devices.first.targetPlatformDisplayName, equals('linux-x64'));
        expect(await devices.first.sdkNameAndVersion, equals('Custom Linux 1.0.0'));
        expect(await devices.first.isSupported(), isTrue);
        expect(await devices.first.isSupportedForProject(project), isFalse);

        tempDir.childDirectory('linux').createSync();
        expect(await devices.first.isSupportedForProject(project), isTrue);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'DevicesCommand output includes custom extension device when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final testDeviceManager = TestDeviceManager(
          discoverers: <DeviceDiscovery>[
            ExtensionDevices(
              extensionBuildManager: ExtensionBuildManager(
                extensionManager: manager,
                featureFlags: featureFlags,
                logger: testLogger,
              ),
              extensionManager: manager,
              fileSystem: MemoryFileSystem.test(),
              logger: testLogger,
            ),
          ],
        );
        final devicesCommand = DevicesCommand(
          deviceManager: testDeviceManager,
          doctor: FakeDoctor(),
          toolContext: FakeToolContext(logger: testLogger),
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(devicesCommand);

        await commandRunner.run(<String>['devices']);
        expect(testLogger.statusText, contains('Linux Custom Extension Prototype Device'));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        DeviceManager: () => TestDeviceManager(),
      },
    );

    group('ExtensionBackedDevice startApp and stopApp', () {
      Future<(ExtensionManager, BufferLogger, MemoryFileSystem, List<Device>)>
      setUpTestDevices() async {
        final logger = BufferLogger.test();
        final fileSystem = MemoryFileSystem.test();
        fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: test_app\n');
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[_fakeLaunchExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        addTearDown(manager.dispose);
        final discovery = ExtensionDevices(
          extensionBuildManager: ExtensionBuildManager(
            extensionManager: manager,
            featureFlags: featureFlags,
            logger: logger,
          ),
          extensionManager: manager,
          fileSystem: fileSystem,
          logger: logger,
        );
        final List<Device> devices = await discovery.devices();
        return (manager, logger, fileSystem, devices);
      }

      testWithoutContext(
        'delegates build, launch, VM service discovery, and stop via RPC',
        () async {
          final (_, _, _, List<Device> devices) = await setUpTestDevices();
          final Device device = devices.firstWhere((Device d) => d.id == 'fake_test_device');

          final LaunchResult launchResult = await device.startApp(
            null,
            mainPath: 'lib/main.dart',
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          );
          expect(launchResult.started, isTrue);
          expect(launchResult.vmServiceUri, Uri.parse('http://127.0.0.1:8181/abcd=/'));
          expect(await device.stopApp(null), isTrue);
        },
      );

      testWithoutContext('fails when prebuiltApplication is true', () async {
        final (_, BufferLogger logger, _, List<Device> devices) = await setUpTestDevices();
        final Device device = devices.firstWhere((Device d) => d.id == 'fake_test_device');

        final LaunchResult prebuiltResult = await device.startApp(
          null,
          prebuiltApplication: true,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
        );
        expect(prebuiltResult.started, isFalse);
        expect(
          logger.errorText,
          contains(
            'Prebuilt application bundles are not supported yet for tool extension devices.',
          ),
        );
      });

      testWithoutContext('fails when device does not specify a buildTarget', () async {
        final (_, BufferLogger logger, _, List<Device> devices) = await setUpTestDevices();
        final Device noTargetDevice = devices.firstWhere((Device d) => d.id == 'no_target_device');

        final LaunchResult noTargetResult = await noTargetDevice.startApp(
          null,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        );
        expect(noTargetResult.started, isFalse);
        expect(
          logger.errorText,
          contains('does not specify a buildTarget for launching applications.'),
        );
      });

      testWithoutContext('fails when extension build target returns failure', () async {
        final (_, BufferLogger logger, _, List<Device> devices) = await setUpTestDevices();
        final Device failingBuildDevice = devices.firstWhere(
          (Device d) => d.id == 'failing_build_device',
        );

        final LaunchResult failingBuildResult = await failingBuildDevice.startApp(
          null,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        );
        expect(failingBuildResult.started, isFalse);
        expect(logger.errorText, contains('Build failed: Simulated build error'));
      });

      testWithoutContext('fails when DeviceService.launchApp returns false', () async {
        final (_, BufferLogger logger, _, List<Device> devices) = await setUpTestDevices();
        final Device failingLaunchDevice = devices.firstWhere(
          (Device d) => d.id == 'failing_launch_device',
        );

        final LaunchResult failingLaunchResult = await failingLaunchDevice.startApp(
          null,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        );
        expect(failingLaunchResult.started, isFalse);
        expect(
          logger.errorText,
          contains('Failed to launch application on Failing Launch Device.'),
        );
      });

      testWithoutContext(
        'fails without stopping app when debugging is enabled and getVmServiceUri returns null',
        () async {
          final (_, BufferLogger logger, _, List<Device> devices) = await setUpTestDevices();
          final Device missingVmServiceDevice = devices.firstWhere(
            (Device d) => d.id == 'missing_vm_service_device',
          );

          final LaunchResult result = await missingVmServiceDevice.startApp(
            null,
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
          );
          expect(result.started, isFalse);
          expect(logger.errorText, contains('Error waiting for a debug connection.'));
          expect(await missingVmServiceDevice.stopApp(null), isTrue);
          expect(await missingVmServiceDevice.stopApp(null), isFalse);
        },
      );
    });
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager({List<DeviceDiscovery>? discoverers})
    : deviceDiscoverers = discoverers ?? <DeviceDiscovery>[],
      super(logger: testLogger);

  @override
  final List<DeviceDiscovery> deviceDiscoverers;
}
