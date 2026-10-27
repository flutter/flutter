// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/commands/logs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart'
    show ExtensionFlutterProject, TargetDevice;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

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
  Future<void> startLogStream({required String deviceId}) async {
    emitLogLine(deviceId: deviceId, line: 'Custom device log line 1');
    emitLogLine(deviceId: deviceId, line: 'Custom device log line 2');
  }
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
        final discovery = ExtensionDevices(extensionManager: manager, logger: testLogger);

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
            ExtensionDevices(extensionManager: manager, logger: testLogger),
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
    ExtensionManager? logsExtensionManager;

    tearDown(() async {
      await logsExtensionManager?.dispose();
      logsExtensionManager = null;
    });
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

        final projectFactory = FlutterProjectFactory(
          fileSystem: localFs,
          logger: testLogger,
          config: FakeConfig(),
        );
        final FlutterProject project = projectFactory.fromDirectory(tempDir);

        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final discovery = ExtensionDevices(extensionManager: manager, logger: testLogger);

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
            ExtensionDevices(extensionManager: manager, logger: testLogger),
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

    testUsingContext(
      'LogsCommand streams log output from custom extension device when feature flag enabled',
      () async {
        final logger = _LogLineWaitingBufferLogger(targetLine: 'Custom device log line 2');
        final intSignal = _FakeProcessSignal();
        final termSignal = _FakeProcessSignal();
        final logsCommand = LogsCommand(
          applicationPackageFactory: _FakeApplicationPackageFactory(),
          sigint: intSignal,
          sigterm: termSignal,
          toolContext: FakeToolContext(logger: logger),
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(logsCommand);

        final Future<void> commandFuture = commandRunner.run(<String>[
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
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        DeviceManager: () {
          logsExtensionManager = ExtensionManager(
            entryPoints: <ExtensionEntryPoint>[_customLogStreamingExtensionEntryPoint],
            featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
            hostPlatform: HostPlatform.linux_x64,
            logger: testLogger,
          );
          return TestDeviceManager(
            discoverers: <DeviceDiscovery>[
              ExtensionDevices(extensionManager: logsExtensionManager!, logger: testLogger),
            ],
          );
        },
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
  TestDeviceManager({List<DeviceDiscovery>? discoverers, FileSystem? fileSystem})
    : deviceDiscoverers = discoverers ?? <DeviceDiscovery>[],
      super(logger: testLogger, fileSystem: fileSystem ?? MemoryFileSystem.test());

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
    if (platform == TargetPlatform.unsupported) {
      throw UnsupportedError('Unexpected target platform $platform');
    }
    return null;
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
