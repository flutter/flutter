// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../src/common.dart';
import '../../src/fakes.dart';

const _primaryDeviceId = 'custom_device_1';
const _secondaryDeviceId = 'custom_device_2';
const _startEventType = 'start';
const _stopEventType = 'stop';
const _launchEventType = 'launch';
const _eventTypeKey = 'type';

final class _StreamingTestDeviceService extends DeviceService {
  _StreamingTestDeviceService({
    required this.eventSendPort,
    this.disconnectPrimaryAfterPolls,
    this.exitAfterEmitting = false,
    this.failGetDevicesOnPoll,
    this.launchResult = false,
    this.linesByDevice = const <String, List<String>>{},
    this.throwOnStart = false,
    this.vmServiceUri,
  });

  final SendPort eventSendPort;
  final int? disconnectPrimaryAfterPolls;
  final bool exitAfterEmitting;
  final int? failGetDevicesOnPoll;
  final bool launchResult;
  final Map<String, List<String>> linesByDevice;
  final bool throwOnStart;
  final Uri? vmServiceUri;
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
          targetPlatform: 'custom-arm64',
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
    bool prebuiltApplication = false,
  }) async {
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: _launchEventType,
      DeviceService.debuggingOptionsParam: debuggingOptions.toMap(),
      DeviceService.deviceIdParam: deviceId,
      DeviceService.executableUriParam: executableUri.toString(),
      DeviceService.prebuiltApplicationParam: prebuiltApplication,
    });
    return launchResult;
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => vmServiceUri;

  @override
  Future<bool> stopApp({required String deviceId}) async => false;

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    if (throwOnStart) {
      throw StateError('Simulated startLogStream failure');
    }
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: _startEventType,
      DeviceService.appIdParam: ?appId,
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

final class _FakeExtensionBuildManager extends ExtensionBuildManager {
  _FakeExtensionBuildManager({
    required super.extensionManager,
    required super.featureFlags,
    required super.logger,
    this.buildResult = const ExtensionBuildResult(success: true),
    List<ExtensionBuildTarget>? targets,
  }) : _targets =
           targets ??
           <ExtensionBuildTarget>[
             ExtensionBuildTarget(
               description: 'Custom Linux Build',
               name: 'custom-linux-build',
               outputDir: '{OUTPUT_DIR}/linux/{TARGET_PLATFORM}/{BUILD_MODE}',
               targetPlatform: 'linux-x64',
             ),
           ];

  ExtensionBuildResult buildResult;
  final List<ExtensionBuildTarget> _targets;
  final buildCalls = <Map<String, Object?>>[];

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
    Map<String, String> dartDefines = const <String, String>{},
    String? flavor,
    String? targetDeviceId,
    String? targetPlatform,
  }) async {
    buildCalls.add(<String, Object?>{
      'buildMode': buildMode,
      'dartDefines': dartDefines,
      'flavor': flavor,
      'flutterRoot': flutterRoot,
      'mainPath': mainPath,
      'outputDir': outputDir,
      'projectRoot': projectRoot,
      'resolvedArtifacts': resolvedArtifacts,
      'targetDeviceId': targetDeviceId,
      'targetName': targetName,
      'targetPlatform': targetPlatform,
    });
    return buildResult;
  }
}

_FakeExtensionBuildManager _createBuildManager({
  required Logger logger,
  ExtensionBuildResult buildResult = const ExtensionBuildResult(success: true),
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
    buildResult: buildResult,
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

    testWithoutContext('ExtensionBackedDevice.getLogReader forwards non-empty app.id to DeviceService.startLogStream', () async {
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

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      final client = ExtensionDeviceClient(conn, logger: logger);
      final List<TargetDevice> targetDevices = await client.getDevices();
      final fileSystem = MemoryFileSystem.test();
      final device = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: client,
        fileSystem: fileSystem,
        logger: logger,
        targetDevice: targetDevices.first,
      );
      addTearDown(device.dispose);

      // First call without app starts log stream with null appId.
      final Future<Map<String, Object?>> initialStartFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _startEventType,
      );
      final DeviceLogReader initialReader = await device.getLogReader();
      final Map<String, Object?> initialStart = await initialStartFuture;
      expect(initialStart[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      expect(initialStart.containsKey(DeviceService.appIdParam), isFalse);

      // Calling with PrebuiltApplicationPackage (whose id is a binary path) reuses null appId.
      final DeviceLogReader prebuiltReader = await device.getLogReader(
        app: PrebuiltLinuxApp(
          applicationPackage: fileSystem.file('/path/to/binary'),
          executable: '/path/to/binary',
        ),
      );
      expect(prebuiltReader, same(initialReader));

      // Calling with a buildable package with non-empty appId stops the previous stream and starts a new one.
      final Future<Map<String, Object?>> stopEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _stopEventType,
      );
      final Future<Map<String, Object?>> startEventFuture = events.firstWhere(
        (Map<String, Object?> event) =>
            event[_eventTypeKey] == _startEventType && event.containsKey(DeviceService.appIdParam),
      );
      final DeviceLogReader appReader = await device.getLogReader(
        app: ExtensionApplicationPackage(id: 'com.example.custom_app'),
      );
      expect(appReader, isNot(same(initialReader)));

      final Map<String, Object?> stopEvent = await stopEventFuture;
      expect(stopEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      final Map<String, Object?> startEvent = await startEventFuture;
      expect(startEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      expect(startEvent[DeviceService.appIdParam], equals('com.example.custom_app'));
    });

    testWithoutContext('ExtensionBackedDevice.startApp forwards expanded ExtensionDebuggingOptions, build defines/flavor/targetPlatform, and supports prebuilt launch and retry reuse', () async {
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
              launchResult: true,
              vmServiceUri: Uri.parse('http://127.0.0.1:9191/ws=/'),
            ),
          ]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      final fileSystem = MemoryFileSystem.test();
      final client = ExtensionDeviceClient(conn, logger: logger);
      final List<TargetDevice> targetDevices = await client.getDevices();
      final _FakeExtensionBuildManager buildManager = _createBuildManager(
        buildResult: ExtensionBuildResult(
          executableUri: Uri.file('/build/custom/app_bundle'),
          success: true,
        ),
        logger: logger,
      );
      final device = ExtensionBackedDevice(
        buildManager: buildManager,
        connection: conn,
        deviceService: client,
        fileSystem: fileSystem,
        logger: logger,
        targetDevice: targetDevices.first,
      );
      addTearDown(device.dispose);

      final launchEvents = <Map<String, Object?>>[];
      final StreamSubscription<Map<String, Object?>> launchSub = events
          .where((Map<String, Object?> event) => event[_eventTypeKey] == _launchEventType)
          .listen(launchEvents.add);
      addTearDown(launchSub.cancel);

      final debuggingOptions = DebuggingOptions.enabled(
        const BuildInfo(
          BuildMode.debug,
          'prod',
          dartDefines: <String>['API_URL=https://example.com', 'ENABLE_FEATURE=true'],
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        dartEntrypointArgs: <String>['--arg1', 'val1'],
        deviceVmServicePort: 8181,
        hostVmServicePort: 8282,
        startPaused: true,
        uninstallFirst: true,
        verboseSystemLogs: true,
      );

      final LaunchResult buildLaunchResult = await device.startApp(
        ExtensionApplicationPackage(id: 'test_app'),
        debuggingOptions: debuggingOptions,
        mainPath: 'lib/custom_main.dart',
        platformArgs: <String, Object?>{'trace-startup': true},
        route: '/initial',
      );
      expect(buildLaunchResult.started, isTrue);
      expect(buildLaunchResult.vmServiceUri, Uri.parse('http://127.0.0.1:9191/ws=/'));

      expect(buildManager.buildCalls, hasLength(1));
      final Map<String, Object?> buildCall = buildManager.buildCalls.single;
      expect(
        buildCall['dartDefines'],
        equals(<String, String>{'API_URL': 'https://example.com', 'ENABLE_FEATURE': 'true'}),
      );
      expect(buildCall['flavor'], equals('prod'));
      expect(buildCall['targetDeviceId'], equals(_primaryDeviceId));
      expect(buildCall['targetPlatform'], equals('custom-arm64'));
      expect((buildCall['outputDir']! as Uri).path, endsWith('/build/linux/custom-arm64/debug/'));

      expect(launchEvents, hasLength(1));
      final Map<String, Object?> firstLaunch = launchEvents.first;
      expect(firstLaunch[DeviceService.prebuiltApplicationParam], isFalse);
      expect(firstLaunch[DeviceService.executableUriParam], 'file:///build/custom/app_bundle');
      final parsedOptions = ExtensionDebuggingOptions.fromJson(
        firstLaunch[DeviceService.debuggingOptionsParam]! as Map<String, Object?>,
      );
      expect(parsedOptions.buildMode, equals(BuildMode.debug));
      expect(parsedOptions.debuggingEnabled, isTrue);
      expect(parsedOptions.dartEntrypointArgs, equals(<String>['--arg1', 'val1']));
      expect(parsedOptions.deviceVmServicePort, 8181);
      expect(parsedOptions.hostVmServicePort, 8282);
      expect(parsedOptions.route, '/initial');
      expect(parsedOptions.uninstallFirst, isTrue);
      expect(
        parsedOptions.engineSwitches,
        containsAll(<String>[
          'enable-dart-profiling=true',
          'trace-startup=true',
          'route=/initial',
          'vm-service-port=8181',
          'enable-checked-mode=true',
          'verify-entry-points=true',
          'start-paused=true',
          'verbose-logging=true',
        ]),
      );

      // Retry with prebuiltApplication: true on a non-prebuilt package reuses the built executableUri
      // without rebuilding and without mislabeling the launch as prebuiltApplication: true.
      final LaunchResult retryLaunchResult = await device.startApp(
        ExtensionApplicationPackage(id: 'test_app'),
        debuggingOptions: debuggingOptions,
        prebuiltApplication: true,
      );
      expect(retryLaunchResult.started, isTrue);
      expect(buildManager.buildCalls, hasLength(1));
      expect(launchEvents, hasLength(2));
      expect(launchEvents[1][DeviceService.prebuiltApplicationParam], isFalse);
      expect(launchEvents[1][DeviceService.executableUriParam], 'file:///build/custom/app_bundle');

      // Launching a PrebuiltExtensionApplicationPackage skips build and sets prebuiltApplication: true.
      final File prebuiltFile = fileSystem.file('/prebuilt/app.bundle')
        ..createSync(recursive: true);
      final LaunchResult prebuiltLaunchResult = await device.startApp(
        PrebuiltExtensionApplicationPackage(applicationPackage: prebuiltFile, id: 'test_app'),
        debuggingOptions: debuggingOptions,
        prebuiltApplication: true,
      );
      expect(prebuiltLaunchResult.started, isTrue);
      expect(buildManager.buildCalls, hasLength(1));
      expect(launchEvents, hasLength(3));
      expect(launchEvents[2][DeviceService.prebuiltApplicationParam], isTrue);
      expect(launchEvents[2][DeviceService.executableUriParam], 'file:///prebuilt/app.bundle');

      // A subsequent failed build clears _lastBuiltExecutableUri so a retry with
      // prebuiltApplication: true does not launch the stale binary from the earlier build.
      buildManager.buildResult = const ExtensionBuildResult(
        errorMessage: 'Simulated build failure',
        success: false,
      );
      final LaunchResult failedBuildResult = await device.startApp(
        ExtensionApplicationPackage(id: 'test_app'),
        debuggingOptions: debuggingOptions,
      );
      expect(failedBuildResult.started, isFalse);
      expect(buildManager.buildCalls, hasLength(2));

      final LaunchResult retryAfterFailedBuildResult = await device.startApp(
        ExtensionApplicationPackage(id: 'test_app'),
        debuggingOptions: debuggingOptions,
        prebuiltApplication: true,
      );
      expect(retryAfterFailedBuildResult.started, isFalse);
      expect(launchEvents, hasLength(3));
    });
  });
}
