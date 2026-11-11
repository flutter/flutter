// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/commands/install.dart';
import 'package:flutter_tools/src/commands/logs.dart';
import 'package:flutter_tools/src/commands/screenshot.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/drive/drive_service.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/test/integration_test_device.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart'
    show
        BuiltInPlaceholders,
        ExtensionApplicationPackage,
        ExtensionApplicationResolutionContext,
        ExtensionBuildResult,
        ExtensionDebuggingOptions,
        ExtensionFlutterProject,
        TargetDevice;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_vm_services.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget({
    required super.description,
    required this.name,
    this.errorMessage,
    this.eventSendPort,
    super.outputDir = '${BuiltInPlaceholders.outputDir}/custom',
    this.shouldSucceed = true,
    super.targetPlatform = 'custom-embedder-arm64',
  });

  @override
  final String name;

  final String? errorMessage;
  final SendPort? eventSendPort;
  final bool shouldSucceed;

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    eventSendPort?.send(<String, Object?>{
      'event': 'build',
      'buildMode': context.buildMode.name,
      'mainPath': context.mainPath,
    });
    return shouldSucceed
        ? ExtensionBuildResult(
            success: true,
            executableUri: Uri.parse('file:///tmp/fake_bundle/${context.buildMode.name}/app'),
          )
        : ExtensionBuildResult(success: false, errorMessage: errorMessage ?? 'Build failed.');
  }
}

final class _FakeTestBuildService extends BuildService {
  _FakeTestBuildService({this.eventSendPort});

  final SendPort? eventSendPort;

  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[
    _TestBuildTarget(
      description: 'Fake test build target',
      eventSendPort: eventSendPort,
      name: 'fake-test-build',
    ),
    _TestBuildTarget(
      description: 'Fake failing build target',
      errorMessage: 'Simulated build error',
      eventSendPort: eventSendPort,
      name: 'fake-failing-build',
      shouldSucceed: false,
    ),
  ];
}

final class _FakeTestDeviceService extends DeviceService {
  _FakeTestDeviceService({this.eventSendPort});

  static const resolvedAppId = 'com.example.custom_test_app';

  final SendPort? eventSendPort;
  final _installedAppIds = <String>{};
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
        supportsInstall: true,
        supportsScreenshot: true,
        targetPlatform: 'custom-embedder-arm64',
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'no_target_device',
        name: 'No Target Device',
        buildTarget: 'fake-test-build',
        ephemeral: false,
        targetPlatform: 'custom-embedder-arm64',
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'failing_build_device',
        name: 'Failing Build Device',
        buildTarget: 'fake-failing-build',
        ephemeral: false,
        supportsInstall: true,
        targetPlatform: 'custom-embedder-arm64',
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'failing_launch_device',
        name: 'Failing Launch Device',
        buildTarget: 'fake-test-build',
        ephemeral: false,
        targetPlatform: 'custom-embedder-arm64',
      ),
      TargetDevice(
        category: Category.desktop,
        id: 'missing_vm_service_device',
        name: 'Missing VM Service Device',
        buildTarget: 'fake-test-build',
        ephemeral: false,
        targetPlatform: 'custom-embedder-arm64',
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => deviceId == 'fake_test_device';

  @override
  Future<ExtensionApplicationPackage?> resolveApplication(
    ExtensionApplicationResolutionContext context,
  ) async {
    eventSendPort?.send(<String, Object?>{
      'event': 'resolve',
      'buildMode': context.buildMode.cliName,
      'deviceId': context.deviceId,
      'flavor': context.flavor,
      'applicationBinaryUri': context.applicationBinaryUri?.toString(),
    });
    final flavorSegment = context.flavor != null ? '${context.flavor}/' : '';
    return ExtensionApplicationPackage(
      appId: resolvedAppId,
      bundleUri:
          context.applicationBinaryUri ??
          context.project.buildDirectory.resolve(
            'custom_os/$flavorSegment${context.buildMode.cliName}/app.pkg',
          ),
    );
  }

  @override
  Future<void> installApp({
    required Uri bundleUri,
    required String deviceId,
    bool prebuiltApplication = false,
  }) async {
    if (deviceId != 'fake_test_device') {
      throw StateError('Simulated install error on $deviceId');
    }
    _installedAppIds.add(resolvedAppId);
    eventSendPort?.send(<String, Object?>{
      'event': 'install',
      'bundleUri': bundleUri.toString(),
      'prebuiltApplication': prebuiltApplication,
    });
  }

  @override
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    eventSendPort?.send(<String, Object?>{'event': 'isAppInstalled', 'appId': appId});
    return deviceId == 'fake_test_device' && _installedAppIds.contains(appId);
  }

  @override
  Future<void> uninstallApp({required String appId, required String deviceId}) async {
    eventSendPort?.send(<String, Object?>{'event': 'uninstall', 'appId': appId});
    if (deviceId != 'fake_test_device') {
      throw StateError('Simulated uninstall error on $deviceId');
    }
    _installedAppIds.remove(appId);
  }

  @override
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    if (deviceId != 'fake_test_device') {
      throw StateError('Simulated screenshot error on $deviceId');
    }
    eventSendPort?.send(<String, Object?>{
      'event': 'screenshot',
      'outputFileUri': outputFileUri.toString(),
    });
  }

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async {
    if (deviceId == 'fake_test_device' || deviceId == 'no_target_device') {
      final bool launched =
          executableUri == Uri.file('/tmp/fake_bundle/debug/app') &&
          debuggingOptions ==
              const ExtensionDebuggingOptions(buildMode: .debug, debuggingEnabled: true);
      if (launched) {
        _runningDevices.add(deviceId);
      }
      return launched;
    }
    if (deviceId == 'missing_vm_service_device') {
      _runningDevices.add(deviceId);
      return true;
    }
    return false;
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    if ((deviceId == 'fake_test_device' || deviceId == 'no_target_device') &&
        _runningDevices.contains(deviceId)) {
      return Uri.parse('http://127.0.0.1:8181/abcd=/');
    }
    return null;
  }

  @override
  Future<bool> stopApp({required String deviceId, String? appId}) async {
    eventSendPort?.send(<String, Object?>{'event': 'stopApp', 'appId': appId});
    return _runningDevices.remove(deviceId);
  }

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    eventSendPort?.send(<String, Object?>{'event': 'startLogStream', 'appId': appId});
  }
}

const _customExtensionDeviceId = 'custom_ext_device';
const _customExtensionDeviceName = 'Custom Extension Device';

void _customLogStreamingExtensionEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
      _CustomLogStreamingDeviceService(),
    ]),
  );
}

final class _CustomLogStreamingDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        category: Category.desktop,
        id: _customExtensionDeviceId,
        name: _customExtensionDeviceName,
        targetPlatform: 'custom-os',
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => true;

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async => false;

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => null;

  @override
  Future<bool> stopApp({required String deviceId, String? appId}) async => false;

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    emitLogLine(deviceId: deviceId, line: 'Custom device log line 1');
    emitLogLine(deviceId: deviceId, line: 'Custom device log line 2');
  }
}

void _fakeAppLaunchExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_FakeTestBuildService(), _FakeTestDeviceService()],
    supportedPlatforms: const <String>{'linux'},
  );
}

ExtensionEntryPoint _createInstallTestEntryPoint(SendPort eventSendPort) {
  return (SendPort sendPort) {
    ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[
        _FakeTestBuildService(eventSendPort: eventSendPort),
        _FakeTestDeviceService(eventSendPort: eventSendPort),
      ],
      supportedPlatforms: const <String>{'linux'},
    );
  };
}

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Tool Extensions Device Integration - Disabled', () {
    testWithoutContext(
      'ExtensionDevices returns empty device list when feature flag disabled',
      () async {
        final logger = BufferLogger.test();
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
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
          toolContext: FakeToolContext(fs: MemoryFileSystem.test(), logger: logger),
        );

        final List<Device> devices = await discovery.devices();
        expect(devices, isEmpty);
        expect(manager.deviceExtensions, isEmpty);
      },
    );

    testWithoutContext(
      'DevicesCommand output does not include custom extension devices when feature flag disabled',
      () async {
        final logger = BufferLogger.test();
        final toolContext = FakeToolContext(fs: MemoryFileSystem.test(), logger: logger);
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        addTearDown(manager.dispose);
        final deviceManager = TestDeviceManager(
          discoverers: <DeviceDiscovery>[
            ExtensionDevices(
              extensionBuildManager: ExtensionBuildManager(
                extensionManager: manager,
                featureFlags: featureFlags,
                logger: logger,
              ),
              extensionManager: manager,
              toolContext: toolContext,
            ),
          ],
          logger: logger,
        );
        final devicesCommand = DevicesCommand(
          deviceManager: deviceManager,
          doctor: FakeDoctor(),
          toolContext: toolContext,
        );
        final runner = TestFlutterCommandRunner(
          deviceManager: deviceManager,
          featureFlags: featureFlags,
          toolContext: toolContext,
        )..addCommand(devicesCommand);

        await runner.run(<String>['devices']);
        expect(logger.statusText, isNot(contains('Linux Custom Extension Prototype Device')));
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

    testWithoutContext(
      'ExtensionDevices discovers custom device when feature flag enabled',
      () async {
        final logger = BufferLogger.test();
        final localFs = LocalFileSystem.test(signals: FakeSignals());
        addTearDown(localFs.dispose);
        final Directory tempDir = localFs.systemTempDirectory.createTempSync(
          'flutter_tool_extensions_device_test.',
        );

        final projectFactory = FlutterProjectFactory(
          fileSystem: localFs,
          logger: logger,
          config: FakeConfig(),
        );
        final FlutterProject project = projectFactory.fromDirectory(tempDir);

        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
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
          toolContext: FakeToolContext(fs: localFs, logger: logger, projectFactory: projectFactory),
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
      },
    );

    testWithoutContext(
      'DevicesCommand output includes custom extension device when feature flag enabled',
      () async {
        final logger = BufferLogger.test();
        final toolContext = FakeToolContext(fs: MemoryFileSystem.test(), logger: logger);
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        addTearDown(manager.dispose);
        final deviceManager = TestDeviceManager(
          discoverers: <DeviceDiscovery>[
            ExtensionDevices(
              extensionBuildManager: ExtensionBuildManager(
                extensionManager: manager,
                featureFlags: featureFlags,
                logger: logger,
              ),
              extensionManager: manager,
              toolContext: toolContext,
            ),
          ],
          logger: logger,
        );
        final devicesCommand = DevicesCommand(
          deviceManager: deviceManager,
          doctor: FakeDoctor(),
          toolContext: toolContext,
        );
        final runner = TestFlutterCommandRunner(
          deviceManager: deviceManager,
          featureFlags: featureFlags,
          toolContext: toolContext,
        )..addCommand(devicesCommand);

        await runner.run(<String>['devices']);
        expect(logger.statusText, contains('Linux Custom Extension Prototype Device'));
      },
    );

    testWithoutContext('LogsCommand streams device-wide log output without calling ApplicationPackageFactory on extension devices', () async {
      final logger = _LogLineWaitingBufferLogger(targetLine: 'Custom device log line 2');
      final toolContext = FakeToolContext(fs: MemoryFileSystem.test(), logger: logger);
      final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
      final manager = ExtensionManager(
        entryPoints: <ExtensionEntryPoint>[_customLogStreamingExtensionEntryPoint],
        featureFlags: featureFlags,
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);
      final deviceManager = TestDeviceManager(
        discoverers: <DeviceDiscovery>[
          ExtensionDevices(
            extensionBuildManager: ExtensionBuildManager(
              extensionManager: manager,
              featureFlags: featureFlags,
              logger: logger,
            ),
            extensionManager: manager,
            toolContext: toolContext,
          ),
        ],
        logger: logger,
      );
      final intSignal = _FakeProcessSignal();
      final termSignal = _FakeProcessSignal();
      final logsCommand = LogsCommand(
        applicationPackageFactory: _FakeApplicationPackageFactory(),
        sigint: intSignal,
        sigterm: termSignal,
        toolContext: toolContext,
      );
      final runner = TestFlutterCommandRunner(
        deviceManager: deviceManager,
        doctor: FakeDoctor(),
        featureFlags: featureFlags,
        toolContext: toolContext,
      )..addCommand(logsCommand);

      final Future<void> commandFuture = runner.run(<String>[
        'logs',
        '-d',
        _customExtensionDeviceId,
      ]);

      await logger.receivedTargetLine.future;

      expect(logger.statusText, contains('Showing $_customExtensionDeviceName logs:'));
      expect(logger.statusText, contains('Custom device log line 1'));
      expect(logger.statusText, contains('Custom device log line 2'));

      intSignal.send(1);
      await commandFuture;
      await logsCommand.device?.dispose();
    });

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
          entryPoints: <ExtensionEntryPoint>[_fakeAppLaunchExtensionEntryPoint],
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
          toolContext: FakeToolContext(fs: fileSystem, logger: logger),
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

    group(
      'InstallCommand, ScreenshotCommand, Drive, and IntegrationTest on ExtensionBackedDevice',
      () {
        late MemoryFileSystem fileSystem;
        late BufferLogger logger;
        late ReceivePort eventPort;
        late List<Map<String, Object?>> recordedEvents;
        late ExtensionManager extensionManager;
        late FakeToolContext toolContext;
        late TestDeviceManager deviceManager;

        setUp(() {
          fileSystem = MemoryFileSystem.test();
          fileSystem.currentDirectory
              .childFile('pubspec.yaml')
              .writeAsStringSync('name: test_app\n');
          logger = BufferLogger.test();
          recordedEvents = <Map<String, Object?>>[];
          eventPort = ReceivePort();
          eventPort.listen((Object? message) {
            if (message case final Map<String, Object?> map) {
              recordedEvents.add(map);
            }
          });

          final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
          toolContext = FakeToolContext(
            cache: Cache.test(processManager: FakeProcessManager.any()),
            fs: fileSystem,
            logger: logger,
            processManager: FakeProcessManager.any(),
            projectFactory: FlutterProjectFactory(
              config: Config.test(),
              fileSystem: fileSystem,
              logger: logger,
            ),
          );
          extensionManager = ExtensionManager(
            entryPoints: <ExtensionEntryPoint>[_createInstallTestEntryPoint(eventPort.sendPort)],
            featureFlags: featureFlags,
            hostPlatform: HostPlatform.linux_x64,
            logger: logger,
          );
          deviceManager = TestDeviceManager(
            discoverers: <DeviceDiscovery>[
              ExtensionDevices(
                extensionBuildManager: ExtensionBuildManager(
                  extensionManager: extensionManager,
                  featureFlags: featureFlags,
                  logger: logger,
                ),
                extensionManager: extensionManager,
                toolContext: toolContext,
              ),
            ],
            fileSystem: fileSystem,
            logger: logger,
          );
        });

        tearDown(() async {
          eventPort.close();
          await extensionManager.dispose();
        });

        CommandRunner<void> createRunnerWith(FlutterCommand command) {
          return TestFlutterCommandRunner(
            deviceManager: deviceManager,
            doctor: FakeDoctor(),
            featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
            toolContext: toolContext,
          )..addCommand(command);
        }

        testWithoutContext('InstallCommand resolves appId via resolveApplication for --use-application-binary and --uninstall-only', () async {
          final File prebuiltFile = fileSystem.file('prebuilt.bin')..createSync();
          final command = InstallCommand(
            applicationPackageFactory: _FakeApplicationPackageFactory(),
            toolContext: toolContext,
            verboseHelp: false,
          );
          final CommandRunner<void> runner = createRunnerWith(command);

          await runner.run(<String>[
            'install',
            '-d',
            'fake_test_device',
            '--use-application-binary=prebuilt.bin',
          ]);
          await pumpEventQueue();
          expect(
            logger.statusText,
            contains('Installing prebuilt.bin to Fake Test Extension Device...'),
          );
          expect(recordedEvents.where((Map<String, Object?> e) => e['event'] == 'build'), isEmpty);
          expect(
            recordedEvents,
            containsAll(<Object>[
              <String, Object?>{
                'event': 'isAppInstalled',
                'appId': _FakeTestDeviceService.resolvedAppId,
              },
              <String, Object?>{
                'event': 'install',
                'bundleUri': prebuiltFile.absolute.uri.toString(),
                'prebuiltApplication': true,
              },
            ]),
          );

          // Running install a second time detects the installed app and uninstalls it first.
          logger.clear();
          await runner.run(<String>[
            'install',
            '-d',
            'fake_test_device',
            '--use-application-binary=prebuilt.bin',
          ]);
          await pumpEventQueue();
          expect(logger.statusText, contains('Uninstalling old version...'));
          expect(
            recordedEvents,
            contains(
              equals(<String, Object?>{
                'event': 'uninstall',
                'appId': _FakeTestDeviceService.resolvedAppId,
              }),
            ),
          );

          // --uninstall-only uninstalls using resolved appId, and skips when not installed.
          logger.clear();
          await runner.run(<String>['install', '-d', 'fake_test_device', '--uninstall-only']);
          expect(
            logger.statusText,
            contains('Uninstalling test_app from Fake Test Extension Device...'),
          );
          logger.clear();
          await runner.run(<String>['install', '-d', 'fake_test_device', '--uninstall-only']);
          expect(
            logger.statusText,
            contains('test_app not found on Fake Test Extension Device, skipping uninstall'),
          );

          // Directory bundles (--use-application-binary=prebuilt_dir.app) pass validation and install cleanly.
          logger.clear();
          recordedEvents.clear();
          final Directory prebuiltDir = fileSystem.directory('prebuilt_dir.app')..createSync();
          await runner.run(<String>[
            'install',
            '-d',
            'fake_test_device',
            '--use-application-binary=prebuilt_dir.app',
          ]);
          await pumpEventQueue();
          expect(
            recordedEvents,
            contains(
              equals(<String, Object?>{
                'event': 'install',
                'bundleUri': prebuiltDir.absolute.uri.toString(),
                'prebuiltApplication': true,
              }),
            ),
          );
        });

        testWithoutContext('InstallCommand without --use-application-binary never builds, preserves installed app when bundle is missing, and installs existing built bundle', () async {
          fileSystem.file('prebuilt.bin').createSync();
          final command = InstallCommand(
            applicationPackageFactory: _FakeApplicationPackageFactory(),
            toolContext: toolContext,
            verboseHelp: false,
          );
          final CommandRunner<void> runner = createRunnerWith(command);

          // Pre-install an app so we can prove a missing non-prebuilt bundle does NOT uninstall it!
          await runner.run(<String>[
            'install',
            '-d',
            'fake_test_device',
            '--use-application-binary=prebuilt.bin',
          ]);
          await pumpEventQueue();
          recordedEvents.clear();
          logger.clear();

          // Non-prebuilt install before building fails with actionable hint and does NOT uninstall!
          await expectLater(
            runner.run(<String>['install', '-d', 'fake_test_device', '--flavor', 'prod']),
            throwsToolExit(message: 'Install failed'),
          );
          await pumpEventQueue();
          expect(
            logger.errorText,
            contains(
              'Run "flutter build fake-test-build" first, or pass "--use-application-binary".',
            ),
          );
          expect(
            recordedEvents.where(
              (Map<String, Object?> e) =>
                  e['event'] == 'build' ||
                  e['event'] == 'isAppInstalled' ||
                  e['event'] == 'uninstall',
            ),
            isEmpty,
          );

          // Once the prior build output exists at the resolved bundleUri, flutter install installs it.
          logger.clear();
          final File builtBundle =
              fileSystem.currentDirectory
                  .childDirectory('build')
                  .childDirectory('custom_os')
                  .childDirectory('prod')
                  .childDirectory('release')
                  .childFile('app.pkg')
                ..createSync(recursive: true);
          await runner.run(<String>['install', '-d', 'fake_test_device', '--flavor', 'prod']);
          await pumpEventQueue();
          expect(logger.statusText, contains('Uninstalling old version...'));
          expect(
            logger.statusText,
            contains('Installing test_app to Fake Test Extension Device...'),
          );
          expect(
            recordedEvents,
            contains(
              equals(<String, Object?>{
                'event': 'install',
                'bundleUri': builtBundle.absolute.uri.toString(),
                'prebuiltApplication': false,
              }),
            ),
          );
        });

        testWithoutContext(
          'InstallCommand throws ToolExit when extension device has supportsInstall false',
          () async {
            final command = InstallCommand(
              applicationPackageFactory: _FakeApplicationPackageFactory(),
              toolContext: toolContext,
              verboseHelp: false,
            );
            final CommandRunner<void> runner = createRunnerWith(command);

            await expectLater(
              runner.run(<String>['install', '-d', 'no_target_device']),
              throwsToolExit(message: 'flutter install is not supported on No Target Device'),
            );
          },
        );

        testWithoutContext('ScreenshotCommand captures screenshot when supportsScreenshot is true and rejects unsupported devices', () async {
          final File outputFile = fileSystem.file('shot.png')..writeAsBytesSync(<int>[1, 2, 3, 4]);
          final command = ScreenshotCommand(toolContext: toolContext);
          final CommandRunner<void> runner = createRunnerWith(command);

          await runner.run(<String>[
            'screenshot',
            '-d',
            'fake_test_device',
            '--out',
            outputFile.path,
          ]);
          await pumpEventQueue();
          expect(logger.statusText, contains('Screenshot written to shot.png'));
          expect(
            recordedEvents,
            contains(
              equals(<String, Object?>{
                'event': 'screenshot',
                'outputFileUri': outputFile.absolute.uri.toString(),
              }),
            ),
          );

          await expectLater(
            runner.run(<String>['screenshot', '-d', 'no_target_device', '--out', outputFile.path]),
            throwsToolExit(message: 'Screenshot not supported for No Target Device.'),
          );
        });

        testWithoutContext('FlutterDriverService resolves extension package on TargetPlatform.unsupported and tears down cleanly regardless of supportsInstall', () async {
          final List<Device> devices = await deviceManager.getDevices();
          final Device installableDevice = devices.firstWhere(
            (Device d) => d.id == 'fake_test_device',
          );
          final Device nonInstallableDevice = devices.firstWhere(
            (Device d) => d.id == 'no_target_device',
          );
          expect(await installableDevice.targetPlatform, TargetPlatform.unsupported);
          expect(await nonInstallableDevice.targetPlatform, TargetPlatform.unsupported);

          final fakeVmServiceHost = FakeVmServiceHost(requests: const <VmServiceExpectation>[]);
          final driverService = FlutterDriverService(
            applicationPackageFactory: _FakeApplicationPackageFactory(),
            dartSdkPath: 'dart',
            devtoolsLauncher: FakeDevtoolsLauncher(),
            toolContext: toolContext,
            vmServiceConnector: (
              Uri httpUri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              FlutterVersion? flutterVersion,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              CompressionOptions compression = CompressionOptions.compressionDefault,
              Device? device,
              required Logger logger,
            }) async => fakeVmServiceHost.vmService,
          );

          // 1. Device with supportsInstall: true resolves package, starts app-scoped log stream, stops, and uninstalls.
          await driverService.start(
            BuildInfo.debug,
            installableDevice,
            DebuggingOptions.enabled(BuildInfo.debug, enableDds: false),
            mainPath: 'test_driver/app.dart',
          );
          await driverService.stop();
          await pumpEventQueue();
          expect(logger.errorText, isEmpty);
          expect(
            recordedEvents,
            containsAll(<Object>[
              <String, Object?>{
                'event': 'startLogStream',
                'appId': _FakeTestDeviceService.resolvedAppId,
              },
              <String, Object?>{'event': 'stopApp', 'appId': _FakeTestDeviceService.resolvedAppId},
              <String, Object?>{
                'event': 'uninstall',
                'appId': _FakeTestDeviceService.resolvedAppId,
              },
            ]),
          );

          // 2. Device with supportsInstall: false succeeds teardown quietly without printing Failed to uninstall app.
          recordedEvents.clear();
          logger.clear();
          final fakeVmServiceHost2 = FakeVmServiceHost(requests: const <VmServiceExpectation>[]);
          final driverService2 = FlutterDriverService(
            applicationPackageFactory: _FakeApplicationPackageFactory(),
            dartSdkPath: 'dart',
            devtoolsLauncher: FakeDevtoolsLauncher(),
            toolContext: toolContext,
            vmServiceConnector: (
              Uri httpUri, {
              ReloadSources? reloadSources,
              Restart? restart,
              CompileExpression? compileExpression,
              FlutterProject? flutterProject,
              FlutterVersion? flutterVersion,
              PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
              CompressionOptions compression = CompressionOptions.compressionDefault,
              Device? device,
              required Logger logger,
            }) async => fakeVmServiceHost2.vmService,
          );
          await driverService2.start(
            BuildInfo.debug,
            nonInstallableDevice,
            DebuggingOptions.enabled(BuildInfo.debug, enableDds: false),
            mainPath: 'test_driver/app.dart',
          );
          await driverService2.stop();
          await pumpEventQueue();
          expect(logger.errorText, isEmpty);
          expect(
            recordedEvents.where((Map<String, Object?> e) => e['event'] == 'uninstall'),
            isEmpty,
          );
        });

        testWithoutContext('IntegrationTestTestDevice resolves extension package on TargetPlatform.unsupported and forwards external entrypointPath and teardown appId', () async {
          final List<Device> devices = await deviceManager.getDevices();
          final Device device = devices.firstWhere((Device d) => d.id == 'fake_test_device');
          expect(await device.targetPlatform, TargetPlatform.unsupported);

          final testDevice = IntegrationTestTestDevice(
            applicationPackageFactory: _FakeApplicationPackageFactory(),
            compileExpression: null,
            debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug, enableDds: false),
            device: device,
            id: 1,
            toolContext: toolContext,
            userIdentifier: null,
          );

          // Launch with an external generated entrypoint path; start() connects to VM service
          // (which fails in this hermetic test because 127.0.0.1:8181 is not open, AFTER
          // package resolution and startApp have succeeded), then kill() stops and uninstalls.
          await expectLater(
            testDevice.start('/tmp/flutter_test_listener.1234/listener.dart'),
            throwsA(anything),
          );
          await testDevice.kill();
          await pumpEventQueue();

          expect(
            recordedEvents,
            containsAll(<Object>[
              <String, Object?>{
                'event': 'build',
                'buildMode': 'debug',
                'mainPath': '/tmp/flutter_test_listener.1234/listener.dart',
              },
              <String, Object?>{'event': 'stopApp', 'appId': _FakeTestDeviceService.resolvedAppId},
              <String, Object?>{
                'event': 'uninstall',
                'appId': _FakeTestDeviceService.resolvedAppId,
              },
            ]),
          );
        });
      },
    );
  });
}

class _LogLineWaitingBufferLogger extends BufferLogger {
  _LogLineWaitingBufferLogger({required this.targetLine}) : super.test();

  final String targetLine;
  final receivedTargetLine = Completer<void>();

  @override
  void printStatus(
    String message, {
    bool? emphasis,
    TerminalColor? color,
    bool? newline,
    int? indent,
    int? hangingIndent,
    bool? wrap,
  }) {
    super.printStatus(
      message,
      emphasis: emphasis,
      color: color,
      newline: newline,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
    if (message == targetLine && !receivedTargetLine.isCompleted) {
      receivedTargetLine.complete();
    }
  }
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager({List<DeviceDiscovery>? discoverers, FileSystem? fileSystem, Logger? logger})
    : deviceDiscoverers = discoverers ?? <DeviceDiscovery>[],
      super(
        logger: logger ?? BufferLogger.test(),
        fileSystem: fileSystem ?? MemoryFileSystem.test(),
      );

  @override
  final List<DeviceDiscovery> deviceDiscoverers;
}

class _FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    throw UnsupportedError('Unexpected getPackageForPlatform($platform) on extension device');
  }
}

class _FakeProcessSignal extends Fake implements ProcessSignal {
  late final _controller = StreamController<ProcessSignal>();

  @override
  Stream<ProcessSignal> watch() => _controller.stream;

  @override
  bool send(int pid) {
    _controller.add(this);
    return true;
  }
}
