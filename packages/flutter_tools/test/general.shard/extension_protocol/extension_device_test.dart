// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/emulator.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

const _primaryDeviceId = 'custom_device_1';
const _secondaryDeviceId = 'custom_device_2';
const _startEventType = 'start';
const _stopEventType = 'stop';
const _eventTypeKey = 'type';

final class _StreamingTestDeviceService extends DeviceService {
  _StreamingTestDeviceService({
    required this.eventSendPort,
    this.disconnectPrimaryAfterPolls,
    this.exitAfterEmitting = false,
    this.failGetDevicesOnPoll,
    this.linesByDevice = const <String, List<String>>{},
    this.throwOnStart = false,
  });

  final SendPort eventSendPort;
  final int? disconnectPrimaryAfterPolls;
  final bool exitAfterEmitting;
  final int? failGetDevicesOnPoll;
  final Map<String, List<String>> linesByDevice;
  final bool throwOnStart;
  int _getDevicesCallCount = 0;

  @override
  Future<List<TargetDevice>> getDevices() async {
    _getDevicesCallCount++;
    if (_getDevicesCallCount == failGetDevicesOnPoll) {
      throw StateError('Simulated transient getDevices failure');
    }
    final int? maxPolls = disconnectPrimaryAfterPolls;
    return <TargetDevice>[
      if (maxPolls == null || _getDevicesCallCount <= maxPolls)
        const TargetDevice(
          buildTarget: 'custom-linux-build',
          category: Category.desktop,
          id: _primaryDeviceId,
          name: 'Primary Extension Device',
        ),
      const TargetDevice(
        buildTarget: 'custom-linux-build',
        category: Category.desktop,
        id: _secondaryDeviceId,
        name: 'Secondary Extension Device',
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
  Future<bool> stopApp({required String deviceId}) async => false;

  @override
  Future<void> startLogStream({required String deviceId}) async {
    if (throwOnStart) {
      throw StateError('Simulated startLogStream failure');
    }
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: _startEventType,
      DeviceService.deviceIdParam: deviceId,
    });
    for (final MapEntry(key: String sourceDeviceId, value: List<String> lines)
        in linesByDevice.entries) {
      for (final line in lines) {
        emitLogLine(deviceId: sourceDeviceId, line: line);
      }
    }
    if (exitAfterEmitting) {
      Timer.run(Isolate.exit);
    }
  }

  @override
  Future<void> stopLogStream({required String deviceId}) async {
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: _stopEventType,
      DeviceService.deviceIdParam: deviceId,
    });
  }
}

final class _TestEmulatorDeviceService extends DeviceService {
  _TestEmulatorDeviceService({
    this.emulatorPlatform,
    this.emulators = const <TargetEmulator>[],
    this.onCreateEmulator,
    this.onGetEmulatorPlatform,
    this.onGetEmulators,
    this.onLaunchEmulator,
  });

  final String? emulatorPlatform;
  final List<TargetEmulator> emulators;
  final FutureOr<TargetEmulator> Function(String? name)? onCreateEmulator;
  final FutureOr<String?> Function()? onGetEmulatorPlatform;
  final FutureOr<List<TargetEmulator>> Function()? onGetEmulators;
  final FutureOr<void> Function(String emulatorId, bool coldBoot)? onLaunchEmulator;

  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => false;

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async => false;

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => null;

  @override
  Future<bool> stopApp({required String deviceId}) async => false;

  @override
  Future<String?> getEmulatorPlatform() async =>
      onGetEmulatorPlatform != null ? await onGetEmulatorPlatform!() : emulatorPlatform;

  @override
  Future<List<TargetEmulator>> getEmulators() async =>
      onGetEmulators != null ? await onGetEmulators!() : emulators;

  @override
  Future<void> launchEmulator({required String emulatorId, bool coldBoot = false}) async =>
      onLaunchEmulator != null
      ? await onLaunchEmulator!(emulatorId, coldBoot)
      : super.launchEmulator(emulatorId: emulatorId, coldBoot: coldBoot);

  @override
  Future<TargetEmulator> createEmulator({String? name}) async =>
      onCreateEmulator != null ? await onCreateEmulator!(name) : super.createEmulator(name: name);
}

ExtensionEntryPoint _deviceEntryPoint(DeviceService service, {String extensionName = 'test_ext'}) {
  return (SendPort sendPort) {
    unawaited(
      ToolExtensionEntryPoint.run(
        sendPort,
        <ToolExtensionService>[service],
        extensionName: extensionName,
        supportedPlatforms: const <String>{'linux'},
      ),
    );
  };
}

ExtensionManager _createExtensionManager({
  required List<ExtensionEntryPoint> entryPoints,
  required Logger logger,
  FeatureFlags? featureFlags,
}) {
  final manager = ExtensionManager(
    entryPoints: entryPoints,
    featureFlags: featureFlags ?? TestFeatureFlags(isToolExtensionsEnabled: true),
    hostPlatform: HostPlatform.linux_x64,
    logger: logger,
  );
  addTearDown(manager.dispose);
  return manager;
}

EmulatorManager _createEmulatorManager({
  required Logger logger,
  AndroidSdk? androidSdk,
  ExtensionManager? extensionManager,
  FeatureFlags? featureFlags,
  ProcessManager? processManager,
}) {
  final FeatureFlags flags = featureFlags ?? TestFeatureFlags(isToolExtensionsEnabled: true);
  return EmulatorManager(
    androidSdkBuilder: androidSdk != null ? () => androidSdk : null,
    androidWorkflow: AndroidWorkflow(androidSdkBuilder: () => androidSdk, featureFlags: flags),
    extensionManager: extensionManager,
    iosWorkflow: null,
    javaBuilder: androidSdk != null ? FakeJava.new : () => null,
    toolContext: FakeToolContext(
      fs: MemoryFileSystem.test(),
      logger: logger,
      processManager: processManager ?? FakeProcessManager.empty(),
    ),
    xcode: null,
  );
}

final class _FakeExtensionBuildManager extends ExtensionBuildManager {
  _FakeExtensionBuildManager({
    required super.extensionManager,
    required super.featureFlags,
    required super.logger,
    List<ExtensionBuildTarget>? targets,
  }) : _targets =
           targets ??
           <ExtensionBuildTarget>[
             ExtensionBuildTarget(
               description: 'Custom Linux Build',
               name: 'custom-linux-build',
               outputDir: '{OUTPUT_DIR}/linux',
               targetPlatform: 'linux-x64',
             ),
           ];

  final List<ExtensionBuildTarget> _targets;

  @override
  Future<List<ExtensionBuildTarget>> getBuildTargets() async => _targets;

  @override
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required Map<String, String> resolvedArtifacts,
    required String targetName,
  }) async => const ExtensionBuildResult(success: true);
}

ExtensionBuildManager _createBuildManager({
  required Logger logger,
  ExtensionManager? extensionManager,
  List<ExtensionBuildTarget>? targets,
}) {
  final ExtensionManager manager =
      extensionManager ??
      ExtensionManager(
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
  if (extensionManager == null) {
    addTearDown(manager.dispose);
  }
  return _FakeExtensionBuildManager(
    extensionManager: manager,
    featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
    logger: logger,
    targets: targets,
  );
}

void main() {
  group('DeviceService & ExtensionDeviceLogReader', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    testWithoutContext('streams log lines end-to-end from extension isolate to ExtensionBackedDevice.getLogReader().logLines', () async {
      final eventPort = ReceivePort();
      addTearDown(eventPort.close);
      final Stream<Map<String, Object?>> events = eventPort
          .cast<Map<String, Object?>>()
          .asBroadcastStream();
      final SendPort eventSendPort = eventPort.sendPort;

      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _StreamingTestDeviceService(
              eventSendPort: eventSendPort,
              linesByDevice: const <String, List<String>>{
                _primaryDeviceId: <String>['Booting application...', 'Flutter run key commands.'],
              },
            ),
          ]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      final client = ExtensionDeviceClient(conn, logger: logger);
      final List<TargetDevice> targetDevices = await client.getDevices();
      expect(targetDevices, hasLength(2));

      final device = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: client,
        fileSystem: MemoryFileSystem.test(),
        logger: logger,
        targetDevice: targetDevices.first,
      );

      final Future<Map<String, Object?>> startEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _startEventType,
      );
      final DeviceLogReader reader = await device.getLogReader();
      expect(await device.getLogReader(), same(reader));

      final Future<List<String>> receivedLinesFuture = reader.logLines.take(2).toList();

      final List<String> receivedLines = await receivedLinesFuture;
      expect(
        receivedLines,
        equals(<String>['Booting application...', 'Flutter run key commands.']),
      );

      final Map<String, Object?> startEvent = await startEventFuture;
      expect(startEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));

      final Future<Map<String, Object?>> stopEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _stopEventType,
      );
      await device.dispose();

      final Map<String, Object?> stopEvent = await stopEventFuture;
      expect(stopEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      expect(await device.getLogReader(), isA<NoOpDeviceLogReader>());
    });

    testWithoutContext(
      'filters device.logEntry notifications by deviceId so logs from other devices are ignored',
      () async {
        final eventPort = ReceivePort();
        addTearDown(eventPort.close);
        final SendPort eventSendPort = eventPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _StreamingTestDeviceService(
                eventSendPort: eventSendPort,
                linesByDevice: const <String, List<String>>{
                  _secondaryDeviceId: <String>['other-device-line-1', 'other-device-line-2'],
                  _primaryDeviceId: <String>['primary-line-1', 'primary-line-2'],
                },
              ),
            ]),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        final client = ExtensionDeviceClient(conn, logger: logger);
        final List<TargetDevice> targetDevices = await client.getDevices();
        final device = ExtensionBackedDevice(
          buildManager: _createBuildManager(logger: logger),
          connection: conn,
          deviceService: client,
          fileSystem: MemoryFileSystem.test(),
          logger: logger,
          targetDevice: targetDevices.firstWhere((TargetDevice d) => d.id == _primaryDeviceId),
        );
        addTearDown(device.dispose);

        final DeviceLogReader reader = await device.getLogReader();
        final List<String> lines = await reader.logLines.take(2).toList();
        expect(lines, equals(<String>['primary-line-1', 'primary-line-2']));
      },
    );

    testWithoutContext(
      'calling dispose() on ExtensionDeviceLogReader triggers stopLogStream on the extension',
      () async {
        final eventPort = ReceivePort();
        addTearDown(eventPort.close);
        final Stream<Map<String, Object?>> events = eventPort
            .cast<Map<String, Object?>>()
            .asBroadcastStream();
        final SendPort eventSendPort = eventPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _StreamingTestDeviceService(eventSendPort: eventSendPort),
            ]),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        final client = ExtensionDeviceClient(conn, logger: logger);
        final Future<Map<String, Object?>> startEventFuture = events.firstWhere(
          (Map<String, Object?> event) => event[_eventTypeKey] == _startEventType,
        );
        final ExtensionDeviceLogReader reader = await ExtensionDeviceLogReader.create(
          connection: conn,
          deviceId: _primaryDeviceId,
          deviceService: client,
          logger: logger,
          name: 'Primary Extension Device',
        );

        final Map<String, Object?> startEvent = await startEventFuture;
        expect(startEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));

        final Future<Map<String, Object?>> stopEventFuture = events.firstWhere(
          (Map<String, Object?> event) => event[_eventTypeKey] == _stopEventType,
        );
        await reader.dispose();

        final Map<String, Object?> stopEvent = await stopEventFuture;
        expect(stopEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      },
    );

    testWithoutContext(
      'ExtensionDeviceLogReader logs warning and closes stream when startLogStream fails',
      () async {
        final eventPort = ReceivePort();
        addTearDown(eventPort.close);
        final SendPort eventSendPort = eventPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _StreamingTestDeviceService(eventSendPort: eventSendPort, throwOnStart: true),
            ]),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        final client = ExtensionDeviceClient(conn, logger: logger);
        final ExtensionDeviceLogReader reader = await ExtensionDeviceLogReader.create(
          connection: conn,
          deviceId: _primaryDeviceId,
          deviceService: client,
          logger: logger,
          name: 'Primary Extension Device',
        );
        addTearDown(reader.dispose);

        expect(
          logger.warningText,
          contains('Failed to start log stream for extension device "$_primaryDeviceId"'),
        );
        await expectLater(reader.logLines, emitsDone);
      },
    );

    testWithoutContext(
      'ExtensionDeviceLogReader closes logLines when extension isolate exits',
      () async {
        final eventPort = ReceivePort();
        addTearDown(eventPort.close);
        final SendPort eventSendPort = eventPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _StreamingTestDeviceService(
                eventSendPort: eventSendPort,
                exitAfterEmitting: true,
                linesByDevice: const <String, List<String>>{
                  _primaryDeviceId: <String>['line before exit'],
                },
              ),
            ]),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        final client = ExtensionDeviceClient(conn, logger: logger);
        final ExtensionDeviceLogReader reader = await ExtensionDeviceLogReader.create(
          connection: conn,
          deviceId: _primaryDeviceId,
          deviceService: client,
          logger: logger,
          name: 'Primary Extension Device',
        );
        addTearDown(reader.dispose);

        await expectLater(reader.logLines, emitsInOrder(<Object>['line before exit', emitsDone]));
      },
    );

    testWithoutContext('startLogStream and stopLogStream throw INVALID_PARAMS on missing, empty, or invalid parameters', () async {
      final eventPort = ReceivePort();
      addTearDown(eventPort.close);
      final SendPort eventSendPort = eventPort.sendPort;

      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _StreamingTestDeviceService(eventSendPort: eventSendPort),
          ]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      for (final method in <String>[
        DeviceService.startLogStreamMethod,
        DeviceService.stopLogStreamMethod,
      ]) {
        await expectLater(
          conn.sendRequest(method, params: const <String, Object?>{}),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );

        await expectLater(
          conn.sendRequest(
            method,
            params: const <String, Object?>{DeviceService.deviceIdParam: ''},
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );

        await expectLater(
          conn.sendRequest(
            method,
            params: const <String, Object?>{DeviceService.deviceIdParam: 42},
          ),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );
      }
    });

    testWithoutContext('multiple concurrent subscribers to logLines across getLogReader calls all receive full log output and startLogStream is called once', () async {
      final eventPort = ReceivePort();
      addTearDown(eventPort.close);
      final Stream<Map<String, Object?>> events = eventPort
          .cast<Map<String, Object?>>()
          .asBroadcastStream();
      final SendPort eventSendPort = eventPort.sendPort;

      final startEvents = <Map<String, Object?>>[];
      final StreamSubscription<Map<String, Object?>> startSub = events
          .where((Map<String, Object?> event) => event[_eventTypeKey] == _startEventType)
          .listen(startEvents.add);
      addTearDown(startSub.cancel);

      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _StreamingTestDeviceService(
              eventSendPort: eventSendPort,
              linesByDevice: const <String, List<String>>{
                _primaryDeviceId: <String>['Booting application...', 'Flutter run key commands.'],
              },
            ),
          ]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      final client = ExtensionDeviceClient(conn, logger: logger);
      final List<TargetDevice> targetDevices = await client.getDevices();
      final device = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: client,
        fileSystem: MemoryFileSystem.test(),
        logger: logger,
        targetDevice: targetDevices.first,
      );
      addTearDown(device.dispose);

      final DeviceLogReader firstReader = await device.getLogReader();
      final DeviceLogReader secondReader = await device.getLogReader();
      expect(secondReader, same(firstReader));

      final Future<List<String>> firstSubscriberLines = firstReader.logLines.take(2).toList();
      final Future<List<String>> secondSubscriberLines = secondReader.logLines.take(2).toList();

      expect(
        await firstSubscriberLines,
        equals(<String>['Booting application...', 'Flutter run key commands.']),
      );
      expect(
        await secondSubscriberLines,
        equals(<String>['Booting application...', 'Flutter run key commands.']),
      );
      expect(startEvents, hasLength(1));
      expect(startEvents.single[DeviceService.deviceIdParam], equals(_primaryDeviceId));
    });

    testWithoutContext('ExtensionDevices.pollingGetDevices reuses cached ExtensionBackedDevice across polls and disposes removed devices', () async {
      final eventPort = ReceivePort();
      addTearDown(eventPort.close);
      final Stream<Map<String, Object?>> events = eventPort
          .cast<Map<String, Object?>>()
          .asBroadcastStream();
      final SendPort eventSendPort = eventPort.sendPort;

      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _StreamingTestDeviceService(
              eventSendPort: eventSendPort,
              disconnectPrimaryAfterPolls: 3,
              failGetDevicesOnPoll: 2,
            ),
          ]),
        );
      }

      final manager = ExtensionManager(
        entryPoints: <ExtensionEntryPoint>[entryPoint],
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);

      final discovery = ExtensionDevices(
        extensionBuildManager: _createBuildManager(extensionManager: manager, logger: logger),
        extensionManager: manager,
        fileSystem: MemoryFileSystem.test(),
        logger: logger,
      );
      addTearDown(discovery.dispose);

      final List<Device> firstPoll = await discovery.pollingGetDevices();
      expect(firstPoll, hasLength(2));
      final Device primaryFirst = firstPoll.firstWhere(
        (Device device) => device.id == _primaryDeviceId,
      );

      final Future<Map<String, Object?>> startEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _startEventType,
      );
      final DeviceLogReader readerFirst = await primaryFirst.getLogReader();
      expect((await startEventFuture)[DeviceService.deviceIdParam], equals(_primaryDeviceId));

      final List<Device> transientFailurePoll = await discovery.pollingGetDevices();
      expect(transientFailurePoll, isEmpty);
      expect(await primaryFirst.getLogReader(), same(readerFirst));

      final List<Device> thirdPoll = await discovery.pollingGetDevices();
      expect(thirdPoll, hasLength(2));
      final Device primaryThird = thirdPoll.firstWhere(
        (Device device) => device.id == _primaryDeviceId,
      );
      expect(primaryThird, same(primaryFirst));
      expect(await primaryThird.getLogReader(), same(readerFirst));

      final Future<Map<String, Object?>> stopEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _stopEventType,
      );
      final List<Device> fourthPoll = await discovery.pollingGetDevices();
      expect(fourthPoll.map((Device device) => device.id), equals(<String>[_secondaryDeviceId]));

      final Map<String, Object?> stopEvent = await stopEventFuture;
      expect(stopEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      expect(await primaryFirst.getLogReader(), isA<NoOpDeviceLogReader>());
    });

    testWithoutContext(
      'ExtensionBackedDevice.startApp fails when no extension provides buildTarget',
      () async {
        final eventPort = ReceivePort();
        addTearDown(eventPort.close);
        final SendPort eventSendPort = eventPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _StreamingTestDeviceService(eventSendPort: eventSendPort),
            ]),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        final client = ExtensionDeviceClient(conn, logger: logger);
        final device = ExtensionBackedDevice(
          buildManager: _createBuildManager(
            logger: logger,
            targets: const <ExtensionBuildTarget>[],
          ),
          connection: conn,
          deviceService: client,
          fileSystem: MemoryFileSystem.test(),
          logger: logger,
          targetDevice: const TargetDevice(
            buildTarget: 'custom-linux-build',
            category: Category.desktop,
            id: 'test_device',
            name: 'Test Device',
          ),
        );
        addTearDown(device.dispose);

        final LaunchResult result = await device.startApp(
          null,
          debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        );
        expect(result.started, isFalse);
        expect(
          logger.errorText,
          contains('No tool extension provides build target "custom-linux-build" for Test Device.'),
        );
      },
    );

    testWithoutContext('ExtensionDeviceClient.launchApp and stopApp log error and return false on ToolExtensionException', () async {
      void domainErrorEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _DomainErrorDeviceService(),
          ], extensionName: 'custom_device_ext'),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(
        domainErrorEntryPoint,
        logger: logger,
      );
      addTearDown(conn.dispose);

      final client = ExtensionDeviceClient(conn, logger: logger);
      final bool launched = await client.launchApp(
        debuggingOptions: const ExtensionDebuggingOptions(
          buildMode: .debug,
          debuggingEnabled: true,
        ),
        deviceId: _primaryDeviceId,
        executableUri: Uri.file('/project/build/app'),
      );
      expect(launched, isFalse);
      expect(
        logger.errorText,
        contains('Extension "custom_device_ext": Launch failed: device disconnected.'),
      );

      logger.clear();
      final bool stopped = await client.stopApp(deviceId: _primaryDeviceId);
      expect(stopped, isFalse);
      expect(
        logger.errorText,
        contains('Extension "custom_device_ext": Stop failed: app not running.'),
      );
    });

    testWithoutContext('ExtensionDevices.pollingGetDevices reports ToolExtensionException via getDiagnostics without warning on every poll', () async {
      void domainErrorEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _DomainErrorDeviceService(),
          ], extensionName: 'custom_device_ext'),
        );
      }

      final manager = ExtensionManager(
        entryPoints: <ExtensionEntryPoint>[domainErrorEntryPoint],
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
      );
      addTearDown(manager.dispose);

      final discovery = ExtensionDevices(
        extensionBuildManager: _createBuildManager(extensionManager: manager, logger: logger),
        extensionManager: manager,
        fileSystem: MemoryFileSystem.test(),
        logger: logger,
      );
      addTearDown(discovery.dispose);

      expect(await discovery.pollingGetDevices(), isEmpty);
      expect(logger.warningText, isEmpty);
      expect(await discovery.getDiagnostics(), const <String>[
        'Extension "custom_device_ext": Device discovery failed: daemon not running.',
      ]);
    });
  });

  group('DeviceService emulator RPCs', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    testWithoutContext('DeviceService.isValidPlatformName validates CLI platform identifiers', () {
      for (final valid in const <String>['custom_os', 'custom-embedder-2', 'android']) {
        expect(DeviceService.isValidPlatformName(valid), isTrue, reason: valid);
      }
      for (final invalid in const <String>['', 'CustomOs', '1custom', 'custom os']) {
        expect(DeviceService.isValidPlatformName(invalid), isFalse, reason: invalid);
      }
    });

    testWithoutContext('default DeviceService returns null platform, empty emulators, and SERVER_ERROR or INVALID_PARAMS', () async {
      final ExtensionConnection conn = await ExtensionConnection.spawn(
        _deviceEntryPoint(_TestEmulatorDeviceService()),
        logger: logger,
      );
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      expect(await client.getEmulatorPlatform(), isNull);
      expect(await client.getEmulators(), isEmpty);
      await expectLater(
        client.launchEmulator(emulatorId: 'any_id', coldBoot: true),
        throwsA(
          isA<json_rpc.RpcException>()
              .having((json_rpc.RpcException e) => e.code, 'code', error_code.SERVER_ERROR)
              .having(
                (json_rpc.RpcException e) => e.message,
                'message',
                contains('Launching emulator any_id is not supported.'),
              ),
        ),
      );
      await expectLater(
        client.createEmulator(name: 'any_name'),
        throwsA(
          isA<json_rpc.RpcException>()
              .having((json_rpc.RpcException e) => e.code, 'code', error_code.SERVER_ERROR)
              .having(
                (json_rpc.RpcException e) => e.message,
                'message',
                contains('Creating emulators is not supported.'),
              ),
        ),
      );

      const invalidRequests = <(String, Map<String, Object?>)>[
        (DeviceService.launchEmulatorMethod, <String, Object?>{}),
        (DeviceService.launchEmulatorMethod, <String, Object?>{DeviceService.emulatorIdParam: ''}),
        (DeviceService.launchEmulatorMethod, <String, Object?>{DeviceService.emulatorIdParam: 42}),
        (
          DeviceService.launchEmulatorMethod,
          <String, Object?>{
            DeviceService.emulatorIdParam: 'ext_emu_1',
            DeviceService.coldBootParam: 'true',
          },
        ),
        (
          DeviceService.createEmulatorMethod,
          <String, Object?>{DeviceService.emulatorNameParam: ''},
        ),
        (
          DeviceService.createEmulatorMethod,
          <String, Object?>{DeviceService.emulatorNameParam: 42},
        ),
      ];
      for (final (String method, Map<String, Object?> params) in invalidRequests) {
        await expectLater(
          conn.sendRequest(method, params: params),
          throwsA(
            isA<json_rpc.RpcException>().having(
              (json_rpc.RpcException e) => e.code,
              'code',
              error_code.INVALID_PARAMS,
            ),
          ),
        );
      }
    });

    testWithoutContext(
      'getEmulatorPlatform, getEmulators, launchEmulator, and createEmulator round-trip over RPC',
      () async {
        final verifyPort = ReceivePort();
        addTearDown(verifyPort.close);
        final Stream<Map<String, Object?>> events = verifyPort
            .cast<Map<String, Object?>>()
            .asBroadcastStream();
        final SendPort verifySendPort = verifyPort.sendPort;

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          _deviceEntryPoint(
            _TestEmulatorDeviceService(
              emulatorPlatform: 'custom_sim',
              emulators: const <TargetEmulator>[
                TargetEmulator(
                  id: 'ext_emu_1',
                  name: 'Extension Emulator 1',
                  category: Category.mobile,
                  manufacturer: 'Custom Vendor',
                ),
              ],
              onLaunchEmulator: (String emulatorId, bool coldBoot) {
                verifySendPort.send(<String, Object?>{
                  _eventTypeKey: 'launch',
                  DeviceService.emulatorIdParam: emulatorId,
                  DeviceService.coldBootParam: coldBoot,
                });
              },
              onCreateEmulator: (String? name) {
                verifySendPort.send(<String, Object?>{
                  _eventTypeKey: 'create',
                  DeviceService.emulatorNameParam: name,
                });
                final String resolvedId = name ?? 'auto_custom_sim';
                return TargetEmulator(
                  id: resolvedId,
                  name: 'Created $resolvedId',
                  category: Category.desktop,
                );
              },
            ),
          ),
          logger: logger,
        );
        addTearDown(conn.dispose);
        final client = ExtensionDeviceClient(conn, logger: logger);

        expect(await client.getEmulatorPlatform(), 'custom_sim');
        expect(await client.getEmulators(), const <TargetEmulator>[
          TargetEmulator(
            id: 'ext_emu_1',
            name: 'Extension Emulator 1',
            category: Category.mobile,
            manufacturer: 'Custom Vendor',
          ),
        ]);

        final Future<Map<String, Object?>> launchEvent = events.firstWhere(
          (Map<String, Object?> e) => e[_eventTypeKey] == 'launch',
        );
        await client.launchEmulator(emulatorId: 'ext_emu_1', coldBoot: true);
        expect(await launchEvent, <String, Object?>{
          _eventTypeKey: 'launch',
          DeviceService.emulatorIdParam: 'ext_emu_1',
          DeviceService.coldBootParam: true,
        });

        final Future<Map<String, Object?>> autoCreateEvent = events.firstWhere(
          (Map<String, Object?> e) => e[_eventTypeKey] == 'create',
        );
        expect(
          await client.createEmulator(name: ''),
          const TargetEmulator(
            id: 'auto_custom_sim',
            name: 'Created auto_custom_sim',
            category: Category.desktop,
          ),
        );
        expect(await autoCreateEvent, <String, Object?>{
          _eventTypeKey: 'create',
          DeviceService.emulatorNameParam: null,
        });

        final Future<Map<String, Object?>> namedCreateEvent = events.firstWhere(
          (Map<String, Object?> e) => e[_eventTypeKey] == 'create',
        );
        expect(
          await client.createEmulator(name: 'custom_sim_2'),
          const TargetEmulator(
            id: 'custom_sim_2',
            name: 'Created custom_sim_2',
            category: Category.desktop,
          ),
        );
        expect(await namedCreateEvent, <String, Object?>{
          _eventTypeKey: 'create',
          DeviceService.emulatorNameParam: 'custom_sim_2',
        });
      },
    );
  });

  group('ExtensionEmulators and ExtensionEmulator', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    testWithoutContext(
      'isolates faults across extensions and queries live emulators on each read',
      () async {
        final queryPort = ReceivePort();
        addTearDown(queryPort.close);
        final SendPort querySendPort = queryPort.sendPort;
        var queryCount = 0;
        final StreamSubscription<Object?> sub = queryPort.listen((_) => queryCount++);
        addTearDown(sub.cancel);

        final ExtensionManager manager = _createExtensionManager(
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[
            _deviceEntryPoint(
              _TestEmulatorDeviceService(
                onGetEmulatorPlatform: () => throw StateError('Platform query failed'),
                onGetEmulators: () => throw StateError('Discovery failed'),
              ),
              extensionName: 'failing_device_ext',
            ),
            _deviceEntryPoint(
              _TestEmulatorDeviceService(
                onGetEmulators: () {
                  querySendPort.send(null);
                  return const <TargetEmulator>[
                    TargetEmulator(
                      id: 'healthy_emu',
                      name: 'Healthy Emulator',
                      category: Category.desktop,
                      manufacturer: 'Acme',
                    ),
                  ];
                },
              ),
              extensionName: 'healthy_device_ext',
            ),
          ],
        );

        final discovery = ExtensionEmulators(extensionManager: manager, logger: logger);
        expect(discovery.supportsPlatform, isTrue);
        expect(discovery.canListAnything, isTrue);
        expect(discovery.canLaunchAnything, isTrue);

        expect(await discovery.hasEmulatorSources(), isTrue);
        expect(queryCount, 1);
        final List<Emulator> emulators = await discovery.emulators;
        expect(queryCount, 2);
        expect(emulators, hasLength(1));
        expect(emulators.single.id, 'healthy_emu');
        expect(emulators.single.name, 'Healthy Emulator');
        expect(emulators.single.manufacturer, 'Acme');
        expect(emulators.single.category, Category.desktop);
        expect(emulators.single.platformType, PlatformType.custom);
        expect(logger.warningText, contains('failing_device_ext'));

        await discovery.emulators;
        expect(queryCount, 3);
      },
    );

    testWithoutContext(
      'ExtensionEmulator.launch forwards coldBoot and formats RPC, domain, and local errors',
      () async {
        final launchedCalls = <(String, bool)>[];
        final service = _TestEmulatorDeviceService(
          onLaunchEmulator: (String emulatorId, bool coldBoot) {
            launchedCalls.add((emulatorId, coldBoot));
            if (emulatorId == 'empty_err_emu') {
              throw json_rpc.RpcException(-32000, '');
            }
            if (emulatorId != 'ok_emu') {
              throw StateError('Simulator binary missing');
            }
          },
        );

        final okEmulator = ExtensionEmulator(
          deviceService: service,
          logger: logger,
          targetEmulator: const TargetEmulator(id: 'ok_emu', name: 'OK Emulator'),
        );
        expect(okEmulator.category, Category.other);
        expect(okEmulator.platformType, PlatformType.custom);
        await okEmulator.launch(coldBoot: true);
        expect(launchedCalls, <(String, bool)>[('ok_emu', true)]);

        await expectLater(
          () => ExtensionEmulator(
            deviceService: service,
            logger: logger,
            targetEmulator: const TargetEmulator(id: 'bad_emu', name: 'Bad Emulator'),
          ).launch(),
          throwsToolExit(
            message: 'Failed to launch emulator "bad_emu": Bad state: Simulator binary missing',
          ),
        );
        expect(launchedCalls, <(String, bool)>[('ok_emu', true), ('bad_emu', false)]);

        await expectLater(
          () => ExtensionEmulator(
            deviceService: service,
            logger: logger,
            targetEmulator: const TargetEmulator(id: 'empty_err_emu', name: 'Empty Error Emulator'),
          ).launch(),
          throwsToolExit(message: 'Failed to launch emulator "empty_err_emu".'),
        );

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          _deviceEntryPoint(_TestEmulatorDeviceService(), extensionName: 'readonly_emu_ext'),
          logger: logger,
        );
        addTearDown(conn.dispose);
        await expectLater(
          () => ExtensionEmulator(
            deviceService: ExtensionDeviceClient(conn, logger: logger),
            logger: logger,
            targetEmulator: const TargetEmulator(
              id: 'unsupported_emu',
              name: 'Unsupported Emulator',
            ),
          ).launch(coldBoot: true),
          throwsToolExit(
            message:
                'Extension "readonly_emu_ext": Failed to launch emulator "unsupported_emu": '
                'Unsupported operation: Launching emulator unsupported_emu is not supported.',
          ),
        );
      },
    );

    testWithoutContext('getCreatePlatforms validates, deduplicates, memoizes warnings, and surfaces ToolExtensionException cleanly', () async {
      final ExtensionManager manager = _createExtensionManager(
        logger: logger,
        entryPoints: <ExtensionEntryPoint>[
          _deviceEntryPoint(_TestEmulatorDeviceService(), extensionName: 'default_device_ext'),
          _deviceEntryPoint(
            _TestEmulatorDeviceService(emulatorPlatform: 'android'),
            extensionName: 'android_collision_ext',
          ),
          _deviceEntryPoint(
            _TestEmulatorDeviceService(emulatorPlatform: 'Invalid Name!'),
            extensionName: 'invalid_name_ext',
          ),
          _deviceEntryPoint(
            _TestEmulatorDeviceService(
              onGetEmulatorPlatform: () =>
                  throw const ToolExtensionException('Emulator SDK is not configured.'),
              onGetEmulators: () =>
                  throw const ToolExtensionException('Emulator list command failed.'),
            ),
            extensionName: 'domain_error_ext',
          ),
          _deviceEntryPoint(
            _TestEmulatorDeviceService(
              emulatorPlatform: 'custom_os',
              emulators: const <TargetEmulator>[
                TargetEmulator(id: 'domain_emu', name: 'Domain Error Emulator'),
              ],
              onLaunchEmulator: (String _, bool _) =>
                  throw const ToolExtensionException('Simulator binary not found.'),
              onCreateEmulator: (String? name) {
                if (name == 'fail_create') {
                  throw const ToolExtensionException('No system image installed.');
                }
                return TargetEmulator(id: name ?? 'first_ext_sim', name: 'First Ext Sim');
              },
            ),
            extensionName: 'first_custom_ext',
          ),
          _deviceEntryPoint(
            _TestEmulatorDeviceService(emulatorPlatform: 'custom_os'),
            extensionName: 'duplicate_custom_ext',
          ),
        ],
      );

      final discovery = ExtensionEmulators(extensionManager: manager, logger: logger);
      expect(await discovery.hasEmulatorSources(), isTrue);
      expect(await discovery.getCreatePlatforms(), equals(<String>['custom_os']));
      final String warningsAfterFirstLoad = logger.warningText;
      expect(warningsAfterFirstLoad, isNot(contains('default_device_ext')));
      expect(warningsAfterFirstLoad, isNot(contains('ToolExtensionException:')));
      expect(
        warningsAfterFirstLoad,
        contains(
          'Ignoring emulator platform "android" from tool extension "android_collision_ext": '
          '"android" is reserved for built-in Android emulators.',
        ),
      );
      expect(
        warningsAfterFirstLoad,
        contains(
          'Ignoring invalid emulator platform "Invalid Name!" from tool extension '
          '"invalid_name_ext": platform identifiers must match lowercase ASCII letters, digits, '
          'underscores, or hyphens.',
        ),
      );
      expect(
        warningsAfterFirstLoad,
        contains('Extension "domain_error_ext": Emulator SDK is not configured.'),
      );
      expect(
        warningsAfterFirstLoad,
        contains(
          'Duplicate emulator platform "custom_os" registered by tool extension '
          '"duplicate_custom_ext" and tool extension "first_custom_ext"',
        ),
      );

      // Memoized across hasEmulatorSources, getCreatePlatforms, and createEmulator.
      final CreateEmulatorResult? created = await discovery.createEmulator(platform: 'custom_os');
      expect(created?.success, isTrue);
      expect(created?.emulatorName, 'first_ext_sim');
      expect(logger.warningText, equals(warningsAfterFirstLoad));

      final CreateEmulatorResult? failed = await discovery.createEmulator(
        platform: 'custom_os',
        name: 'fail_create',
      );
      expect(failed?.success, isFalse);
      expect(failed?.error, 'Extension "first_custom_ext": No system image installed.');

      logger.clear();
      final List<Emulator> emulators = await discovery.emulators;
      expect(emulators, hasLength(1));
      expect(
        logger.warningText,
        contains('Extension "domain_error_ext": Emulator list command failed.'),
      );
      expect(logger.warningText, isNot(contains('ToolExtensionException:')));
      await expectLater(
        () => emulators.single.launch(),
        throwsToolExit(
          message:
              'Extension "first_custom_ext": Failed to launch emulator "domain_emu": '
              'Simulator binary not found.',
        ),
      );
    });

    testWithoutContext(
      'EmulatorManager does not spawn extensions when disabled, in safe mode, or omitted',
      () async {
        void shouldNotSpawnEntryPoint(SendPort sendPort) {
          fail('Extension isolate should not spawn when extensions are disabled or in safe mode.');
        }

        final disabledFlags = TestFeatureFlags();
        final ExtensionManager disabledExtManager = _createExtensionManager(
          entryPoints: <ExtensionEntryPoint>[shouldNotSpawnEntryPoint],
          featureFlags: disabledFlags,
          logger: logger,
        );
        final ExtensionManager safeModeExtManager = _createExtensionManager(
          entryPoints: <ExtensionEntryPoint>[shouldNotSpawnEntryPoint],
          logger: logger,
        )..disable();

        for (final extManager in <ExtensionManager?>[
          disabledExtManager,
          safeModeExtManager,
          null,
        ]) {
          final EmulatorManager emulatorManager = _createEmulatorManager(
            extensionManager: extManager,
            featureFlags: disabledFlags,
            logger: logger,
          );
          expect(await emulatorManager.hasExtensionEmulatorSources(), isFalse);
          expect(await emulatorManager.getAvailableCreatePlatforms(), isEmpty);
          expect(await emulatorManager.getAllAvailableEmulators(), isEmpty);
          expect((await emulatorManager.createEmulator(platform: 'custom_os')).success, isFalse);
          expect(extManager?.connections ?? const <ExtensionConnection>[], isEmpty);
        }
      },
    );

    testWithoutContext(
      'EmulatorManager discovers emulators and routes createEmulator across Android and extensions',
      () async {
        final ExtensionManager extManager = _createExtensionManager(
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[
            _deviceEntryPoint(
              _TestEmulatorDeviceService(
                emulatorPlatform: 'custom_os',
                emulators: const <TargetEmulator>[
                  TargetEmulator(id: 'ext_emu', name: 'Extension Emulator'),
                ],
                onCreateEmulator: (String? name) {
                  if (name == 'fail_me') {
                    throw StateError('Disk full while creating image');
                  }
                  final String id = name ?? 'custom_os_default';
                  return TargetEmulator(id: id, name: 'Custom $id');
                },
              ),
              extensionName: 'custom_os_ext',
            ),
          ],
        );
        final EmulatorManager emulatorManager = _createEmulatorManager(
          extensionManager: extManager,
          logger: logger,
        );

        expect(await emulatorManager.hasExtensionEmulatorSources(), isTrue);
        expect(await emulatorManager.getAvailableCreatePlatforms(), <String>['custom_os']);

        final List<Emulator> matching = await emulatorManager.getEmulatorsMatching('ext_emu');
        expect(matching.single.id, 'ext_emu');
        expect(matching.single.name, 'Extension Emulator');

        expect(
          (await emulatorManager.createEmulator(platform: 'custom_os')).emulatorName,
          'custom_os_default',
        );
        expect(
          (await emulatorManager.createEmulator(
            name: 'sim_alpha',
            platform: 'custom_os',
          )).emulatorName,
          'sim_alpha',
        );

        final CreateEmulatorResult failedResult = await emulatorManager.createEmulator(
          name: 'fail_me',
          platform: 'custom_os',
        );
        expect(failedResult.success, isFalse);
        expect(failedResult.error, startsWith('Extension "custom_os_ext": '));
        expect(failedResult.error, contains('Disk full while creating image'));

        final CreateEmulatorResult unknownResult = await emulatorManager.createEmulator(
          platform: 'unknown_os',
        );
        expect(unknownResult.success, isFalse);
        expect(
          unknownResult.error,
          'Unknown emulator creation platform "unknown_os". Available platforms: custom_os.',
        );

        final EmulatorManager androidAndExtManager = _createEmulatorManager(
          androidSdk: _FakeAndroidSdk(),
          extensionManager: extManager,
          logger: logger,
          processManager: FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(
              command: <String>['avdmanager', 'list', 'device', '-c'],
              stdout: 'pixel\n',
            ),
            const FakeCommand(
              command: <String>['avdmanager', 'create', 'avd', '-n', 'temp'],
              stderr: 'system-images;android-27;google_apis_playstore;x86\n',
              exitCode: 1,
            ),
            const FakeCommand(
              command: <String>[
                'avdmanager',
                'create',
                'avd',
                '-n',
                'default_android_avd',
                '-k',
                'system-images;android-27;google_apis_playstore;x86',
                '-d',
                'pixel',
              ],
            ),
          ]),
        );
        expect(await androidAndExtManager.getAvailableCreatePlatforms(), <String>[
          'android',
          'custom_os',
        ]);
        final CreateEmulatorResult androidResult = await androidAndExtManager.createEmulator(
          name: 'default_android_avd',
        );
        expect(androidResult.success, isTrue);
        expect(androidResult.emulatorName, 'default_android_avd');
      },
    );

    testWithoutContext('linuxExtensionEntryPoint does not advertise emulator sources or create platforms in production', () async {
      final EmulatorManager emulatorManager = _createEmulatorManager(
        extensionManager: _createExtensionManager(
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          logger: logger,
        ),
        logger: logger,
      );

      expect(await emulatorManager.hasExtensionEmulatorSources(), isFalse);
      expect(await emulatorManager.getAvailableCreatePlatforms(), isEmpty);
      expect(await emulatorManager.getAllAvailableEmulators(), isEmpty);
      expect(logger.warningText, isEmpty);
      expect(logger.errorText, isEmpty);
    });
  });
}

final class _DomainErrorDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async {
    throw const ToolExtensionException('Device discovery failed: daemon not running.');
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
  }) async {
    throw const ToolExtensionException('Launch failed: device disconnected.');
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => null;

  @override
  Future<bool> stopApp({required String deviceId}) async {
    throw const ToolExtensionException('Stop failed: app not running.');
  }

  @override
  Future<void> startLogStream({required String deviceId}) async {}

  @override
  Future<void> stopLogStream({required String deviceId}) async {}
}

final class _FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String? get avdManagerPath => 'avdmanager';

  @override
  String? get emulatorPath => 'emulator';

  @override
  String? get adbPath => 'adb';

  @override
  String? getAvdManagerPath() => avdManagerPath;

  @override
  String getAvdPath() => 'avd';
}
