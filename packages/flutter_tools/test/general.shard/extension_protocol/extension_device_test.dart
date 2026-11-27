// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_build_manager.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../../src/common.dart';
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
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    if (throwOnStart) {
      throw StateError('Simulated startLogStream failure');
    }
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: _startEventType,
      DeviceService.appIdParam: appId,
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

final class _TestDeviceService extends DeviceService {
  _TestDeviceService({
    this.onInstallApp,
    this.onIsAppInstalled,
    this.onResolveApplication,
    this.onStartLogStream,
    this.onTakeScreenshot,
    this.onUninstallApp,
  });

  final Future<void> Function(String deviceId, Uri bundleUri, bool prebuiltApplication)?
  onInstallApp;
  final Future<bool> Function(String deviceId, String appId)? onIsAppInstalled;
  final Future<ExtensionApplicationPackage?> Function(
    ExtensionApplicationResolutionContext context,
  )?
  onResolveApplication;
  final Future<void> Function(String deviceId, String? appId)? onStartLogStream;
  final Future<void> Function(String deviceId, Uri outputFileUri)? onTakeScreenshot;
  final Future<void> Function(String deviceId, String appId)? onUninstallApp;

  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => true;

  @override
  Future<ExtensionApplicationPackage?> resolveApplication(
    ExtensionApplicationResolutionContext context,
  ) async {
    if (onResolveApplication case final callback?) {
      return callback(context);
    }
    return super.resolveApplication(context);
  }

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
  Future<void> installApp({
    required Uri bundleUri,
    required String deviceId,
    bool prebuiltApplication = false,
  }) async {
    if (onInstallApp case final callback?) {
      return callback(deviceId, bundleUri, prebuiltApplication);
    }
    return super.installApp(
      bundleUri: bundleUri,
      deviceId: deviceId,
      prebuiltApplication: prebuiltApplication,
    );
  }

  @override
  Future<void> uninstallApp({required String appId, required String deviceId}) async {
    if (onUninstallApp case final callback?) {
      return callback(deviceId, appId);
    }
    return super.uninstallApp(appId: appId, deviceId: deviceId);
  }

  @override
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    if (onIsAppInstalled case final callback?) {
      return callback(deviceId, appId);
    }
    return super.isAppInstalled(appId: appId, deviceId: deviceId);
  }

  @override
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    if (onTakeScreenshot case final callback?) {
      return callback(deviceId, outputFileUri);
    }
    return super.takeScreenshot(deviceId: deviceId, outputFileUri: outputFileUri);
  }

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    if (onStartLogStream case final callback?) {
      return callback(deviceId, appId);
    }
    return super.startLogStream(deviceId: deviceId, appId: appId);
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
               outputDir: '{OUTPUT_DIR}/linux',
               targetPlatform: 'linux-x64',
             ),
           ];

  final ExtensionBuildResult buildResult;
  final List<ExtensionBuildTarget> _targets;
  final buildCalls = <({BuildMode buildMode, String targetName, Uri projectRoot})>[];

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
  }) async {
    buildCalls.add((buildMode: buildMode, targetName: targetName, projectRoot: projectRoot));
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

Matcher _isInvalidParamsRpcException() => isA<json_rpc.RpcException>().having(
  (json_rpc.RpcException e) => e.code,
  'code',
  error_code.INVALID_PARAMS,
);

void main() {
  group('DeviceService & ExtensionDeviceLogReader', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test(
      'streams log lines end-to-end, forwards appId, and recreates log reader after dispose',
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
              _StreamingTestDeviceService(
                eventSendPort: eventSendPort,
                linesByDevice: const <String, List<String>>{
                  _primaryDeviceId: <String>['Booting application...', 'Flutter run key commands.'],
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

        final List<String> receivedLines = await reader.logLines.take(2).toList();
        expect(
          receivedLines,
          equals(<String>['Booting application...', 'Flutter run key commands.']),
        );

        final Map<String, Object?> startEvent = await startEventFuture;
        expect(startEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
        expect(startEvent[DeviceService.appIdParam], isNull);

        // Disposing the reader allows getLogReader to create a fresh reader, and passing app forwards appId.
        await reader.dispose();
        final Future<Map<String, Object?>> scopedStartEventFuture = events.firstWhere(
          (Map<String, Object?> event) => event[_eventTypeKey] == _startEventType,
        );
        final appPkg = ExtensionBackedApplicationPackage(id: 'com.example.custom_app');
        final DeviceLogReader scopedReader = await device.getLogReader(app: appPkg);
        expect(scopedReader, isNot(same(reader)));
        final Map<String, Object?> scopedStartEvent = await scopedStartEventFuture;
        expect(scopedStartEvent[DeviceService.appIdParam], 'com.example.custom_app');

        final Future<Map<String, Object?>> stopEventFuture = events.firstWhere(
          (Map<String, Object?> event) => event[_eventTypeKey] == _stopEventType,
        );
        await device.dispose();

        final Map<String, Object?> stopEvent = await stopEventFuture;
        expect(stopEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
        expect(await device.getLogReader(), isA<NoOpDeviceLogReader>());
      },
    );

    test(
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

    test(
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

    test(
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

    test('ExtensionDeviceLogReader closes logLines when extension isolate exits', () async {
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

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
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
    });

    test('startLogStream and stopLogStream throw INVALID_PARAMS on missing, empty, or invalid parameters', () async {
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

      for (final (String method, Map<String, Object?> params) in <(String, Map<String, Object?>)>[
        for (final method in const <String>[
          DeviceService.startLogStreamMethod,
          DeviceService.stopLogStreamMethod,
        ]) ...<(String, Map<String, Object?>)>[
          (method, const <String, Object?>{}),
          (method, const <String, Object?>{DeviceService.deviceIdParam: ''}),
          (method, const <String, Object?>{DeviceService.deviceIdParam: 42}),
        ],
        (
          DeviceService.startLogStreamMethod,
          const <String, Object?>{
            DeviceService.deviceIdParam: _primaryDeviceId,
            DeviceService.appIdParam: '',
          },
        ),
        (
          DeviceService.startLogStreamMethod,
          const <String, Object?>{
            DeviceService.deviceIdParam: _primaryDeviceId,
            DeviceService.appIdParam: 123,
          },
        ),
      ]) {
        await expectLater(
          conn.sendRequest(method, params: params),
          throwsA(_isInvalidParamsRpcException()),
        );
      }
    });

    test('multiple concurrent subscribers to logLines across getLogReader calls all receive full log output and startLogStream is called once', () async {
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

    test('ExtensionDevices.pollingGetDevices reuses cached ExtensionBackedDevice across polls and disposes removed devices', () async {
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

    test('ExtensionBackedDevice.startApp fails when no extension provides buildTarget', () async {
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

      final client = ExtensionDeviceClient(conn, logger: logger);
      final device = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger, targets: const <ExtensionBuildTarget>[]),
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
    });

    test('ExtensionDeviceClient.launchApp and stopApp log error and return false on ToolExtensionException', () async {
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

    test('ExtensionDevices.pollingGetDevices reports ToolExtensionException via getDiagnostics without warning on every poll', () async {
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

  group('DeviceService RPC resolveApplication, install, and screenshot', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    test('handles resolveApplication, installApp, uninstallApp, isAppInstalled, and takeScreenshot over RPC', () async {
      final events = <Map<String, Object?>>[];
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      eventsPort.listen((Object? message) {
        if (message case final Map<String, Object?> map) {
          events.add(map);
        }
      });
      final SendPort eventsSendPort = eventsPort.sendPort;

      void entryPoint(SendPort sendPort) {
        final installedApps = <String>{};
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestDeviceService(
              onResolveApplication: (ExtensionApplicationResolutionContext context) async {
                eventsSendPort.send(<String, Object?>{
                  'method': 'resolveApplication',
                  'deviceId': context.deviceId,
                  'buildMode': context.buildMode.cliName,
                  'flavor': context.flavor,
                });
                return ExtensionApplicationPackage(
                  appId: 'com.example.${context.project.appName}',
                  bundleUri:
                      context.applicationBinaryUri ??
                      context.project.buildDirectory.resolve(
                        'custom_os/${context.buildMode.cliName}/app.pkg',
                      ),
                );
              },
              onInstallApp: (String deviceId, Uri bundleUri, bool prebuiltApplication) async {
                eventsSendPort.send(<String, Object?>{
                  'method': 'installApp',
                  'bundleUri': bundleUri.toString(),
                  'prebuiltApplication': prebuiltApplication,
                });
                installedApps.add('com.example.project_app');
              },
              onIsAppInstalled: (String deviceId, String appId) async =>
                  installedApps.contains(appId),
              onUninstallApp: (String deviceId, String appId) async {
                eventsSendPort.send(<String, Object?>{'method': 'uninstallApp', 'appId': appId});
                installedApps.remove(appId);
              },
              onTakeScreenshot: (String deviceId, Uri outputFileUri) async {
                eventsSendPort.send(<String, Object?>{
                  'method': 'takeScreenshot',
                  'outputFileUri': outputFileUri.toString(),
                });
              },
            ),
          ]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      const deviceId = 'device-1';
      final project = ExtensionFlutterProject(
        appName: 'project_app',
        buildDirectory: Uri.directory('/tmp/project/build/'),
        directory: Uri.directory('/tmp/project/'),
      );

      final ExtensionApplicationPackage? resolved = await client.resolveApplication(
        ExtensionApplicationResolutionContext(
          buildMode: BuildMode.release,
          deviceId: deviceId,
          flavor: 'staging',
          project: project,
        ),
      );
      expect(
        resolved,
        ExtensionApplicationPackage(
          appId: 'com.example.project_app',
          bundleUri: Uri.parse('file:///tmp/project/build/custom_os/release/app.pkg'),
        ),
      );

      expect(await client.isAppInstalled(appId: resolved!.appId, deviceId: deviceId), isFalse);
      await client.installApp(
        bundleUri: resolved.bundleUri!,
        deviceId: deviceId,
        prebuiltApplication: true,
      );
      expect(await client.isAppInstalled(appId: resolved.appId, deviceId: deviceId), isTrue);
      await client.uninstallApp(appId: resolved.appId, deviceId: deviceId);
      expect(await client.isAppInstalled(appId: resolved.appId, deviceId: deviceId), isFalse);

      final screenshotUri = Uri.file('/tmp/screenshot.png');
      await client.takeScreenshot(deviceId: deviceId, outputFileUri: screenshotUri);
      await pumpEventQueue();

      expect(
        events,
        containsAll(<Object>[
          <String, Object?>{
            'method': 'resolveApplication',
            'deviceId': deviceId,
            'buildMode': 'release',
            'flavor': 'staging',
          },
          <String, Object?>{
            'method': 'installApp',
            'bundleUri': 'file:///tmp/project/build/custom_os/release/app.pkg',
            'prebuiltApplication': true,
          },
          <String, Object?>{'method': 'uninstallApp', 'appId': 'com.example.project_app'},
          <String, Object?>{'method': 'takeScreenshot', 'outputFileUri': screenshotUri.toString()},
        ]),
      );
    });

    test('default DeviceService returns null from resolveApplication and rejects install and screenshot', () async {
      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TestDeviceService()]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      const deviceId = 'default-device';
      final project = ExtensionFlutterProject(
        appName: 'default_app',
        buildDirectory: Uri.directory('/tmp/project/build/'),
        directory: Uri.directory('/tmp/project/'),
      );
      expect(
        await client.resolveApplication(
          ExtensionApplicationResolutionContext(
            buildMode: BuildMode.debug,
            deviceId: deviceId,
            project: project,
          ),
        ),
        isNull,
      );

      for (final call in <Future<Object?> Function()>[
        () => client.installApp(bundleUri: Uri.file('/tmp/app.bundle'), deviceId: deviceId),
        () => client.uninstallApp(appId: 'com.example.app', deviceId: deviceId),
        () => client.isAppInstalled(appId: 'com.example.app', deviceId: deviceId),
        () => client.takeScreenshot(deviceId: deviceId, outputFileUri: Uri.file('/tmp/out.png')),
      ]) {
        await expectLater(call(), throwsA(isA<json_rpc.RpcException>()));
      }
    });

    test('surfaces ToolExtensionException (-32001) across resolveApplication, install, and screenshot RPCs', () async {
      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestDeviceService(
              onResolveApplication: (ExtensionApplicationResolutionContext _) async =>
                  throw const ToolExtensionException('Invalid platform manifest.'),
              onInstallApp: (String _, Uri _, bool _) async =>
                  throw const ToolExtensionException('Insufficient device storage.'),
              onUninstallApp: (String _, String _) async =>
                  throw const ToolExtensionException('Package manager locked.'),
              onIsAppInstalled: (String _, String _) async =>
                  throw const ToolExtensionException('Cannot query installed packages.'),
              onTakeScreenshot: (String _, Uri _) async =>
                  throw const ToolExtensionException('Display output is disabled.'),
            ),
          ]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);
      const deviceId = 'device-errors';
      final resolutionContext = ExtensionApplicationResolutionContext(
        buildMode: .debug,
        deviceId: deviceId,
        project: ExtensionFlutterProject(
          appName: 'error_app',
          buildDirectory: Uri.directory('/tmp/project/build/'),
          directory: Uri.directory('/tmp/project/'),
        ),
      );

      for (final (call, expectedMessage) in <(Future<Object?> Function(), String)>[
        (() => client.resolveApplication(resolutionContext), 'Invalid platform manifest.'),
        (
          () => client.installApp(bundleUri: Uri.file('/tmp/app.pkg'), deviceId: deviceId),
          'Insufficient device storage.',
        ),
        (
          () => client.uninstallApp(appId: 'com.example.app', deviceId: deviceId),
          'Package manager locked.',
        ),
        (
          () => client.isAppInstalled(appId: 'com.example.app', deviceId: deviceId),
          'Cannot query installed packages.',
        ),
        (
          () => client.takeScreenshot(deviceId: deviceId, outputFileUri: Uri.file('/tmp/out.png')),
          'Display output is disabled.',
        ),
      ]) {
        await expectLater(
          call(),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              expectedMessage,
            ),
          ),
        );
      }
    });

    test('returns INVALID_PARAMS (-32602) on missing or invalid RPC parameters', () async {
      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TestDeviceService()]),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);

      const validProjectMap = <String, Object?>{
        ExtensionFlutterProject.appNameKey: 'my_app',
        ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
        ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
      };

      final invalidRequests = <(String, Map<String, Object?>)>[
        (
          DeviceService.resolveApplicationMethod,
          <String, Object?>{
            ExtensionApplicationResolutionContext.buildModeKey: 'debug',
            ExtensionApplicationResolutionContext.projectKey: validProjectMap,
          },
        ),
        (
          DeviceService.resolveApplicationMethod,
          <String, Object?>{
            ExtensionApplicationResolutionContext.buildModeKey: 'invalid_mode',
            ExtensionApplicationResolutionContext.deviceIdKey: 'device-1',
            ExtensionApplicationResolutionContext.projectKey: validProjectMap,
          },
        ),
        (
          DeviceService.resolveApplicationMethod,
          <String, Object?>{
            ExtensionApplicationResolutionContext.applicationBinaryUriKey: 'relative/app.pkg',
            ExtensionApplicationResolutionContext.buildModeKey: 'debug',
            ExtensionApplicationResolutionContext.deviceIdKey: 'device-1',
            ExtensionApplicationResolutionContext.projectKey: validProjectMap,
          },
        ),
        (
          DeviceService.resolveApplicationMethod,
          <String, Object?>{
            ExtensionApplicationResolutionContext.buildModeKey: 'debug',
            ExtensionApplicationResolutionContext.deviceIdKey: 'device-1',
            ExtensionApplicationResolutionContext.flavorKey: '',
            ExtensionApplicationResolutionContext.projectKey: validProjectMap,
          },
        ),
        (
          DeviceService.installAppMethod,
          const <String, Object?>{
            DeviceService.deviceIdParam: '',
            DeviceService.bundleUriParam: 'file:///tmp/app.bundle',
          },
        ),
        (
          DeviceService.installAppMethod,
          const <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.bundleUriParam: 'file:///',
          },
        ),
        (
          DeviceService.installAppMethod,
          const <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.bundleUriParam: 'file:///tmp/app.bundle',
            DeviceService.prebuiltApplicationParam: 'yes',
          },
        ),
        for (final method in const <String>[
          DeviceService.uninstallAppMethod,
          DeviceService.isAppInstalledMethod,
        ]) ...<(String, Map<String, Object?>)>[
          (method, const <String, Object?>{DeviceService.deviceIdParam: 'device-1'}),
          (
            method,
            const <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.appIdParam: '',
            },
          ),
          (
            method,
            const <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.appIdParam: 42,
            },
          ),
        ],
        (
          DeviceService.takeScreenshotMethod,
          const <String, Object?>{
            DeviceService.deviceIdParam: 'device-1',
            DeviceService.outputFileUriParam: 'relative/screenshot.png',
          },
        ),
      ];

      for (final (String method, Map<String, Object?> params) in invalidRequests) {
        await expectLater(
          conn.sendRequest(method, params: params),
          throwsA(_isInvalidParamsRpcException()),
        );
      }
    });
  });

  group('ExtensionBackedDevice resolveApplicationPackage and delegation', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    const targetDevice = TargetDevice(
      buildTarget: 'custom-linux-build',
      category: Category.mobile,
      id: 'ext-device-1',
      name: 'Extension Device 1',
      supportsInstall: true,
      supportsScreenshot: true,
      targetPlatform: 'custom-embedder-arm64',
    );

    setUp(() {
      fs = MemoryFileSystem.test();
      fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: test_project_app\n');
      logger = BufferLogger.test();
    });

    Future<(ExtensionConnection, ExtensionBackedDevice, _FakeExtensionBuildManager)> spawnDevice(
      ExtensionEntryPoint entryPoint, {
      TargetDevice target = targetDevice,
    }) async {
      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final _FakeExtensionBuildManager buildManager = _createBuildManager(logger: logger);
      final device = ExtensionBackedDevice(
        buildManager: buildManager,
        connection: conn,
        deviceService: ExtensionDeviceClient(conn, logger: logger),
        fileSystem: fs,
        logger: logger,
        targetDevice: target,
      );
      addTearDown(device.dispose);
      return (conn, device, buildManager);
    }

    test('resolves prebuilt file and directory packages and delegates install/uninstall/isAppInstalled', () async {
      final receivedInstalls = <({Uri bundleUri, bool prebuiltApplication})>[];
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      eventsPort.listen((Object? message) {
        if (message case {
          'installUri': final String installUriStr,
          'prebuilt': final bool prebuilt,
        }) {
          receivedInstalls.add((
            bundleUri: Uri.parse(installUriStr),
            prebuiltApplication: prebuilt,
          ));
        }
      });
      final SendPort eventsSendPort = eventsPort.sendPort;

      void entryPoint(SendPort sendPort) {
        final installedApps = <String>{};
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestDeviceService(
              onResolveApplication: (ExtensionApplicationResolutionContext context) async =>
                  ExtensionApplicationPackage(
                    appId: 'com.custom.${context.project.appName}',
                    bundleUri: context.applicationBinaryUri,
                  ),
              onInstallApp: (String deviceId, Uri bundleUri, bool prebuiltApplication) async {
                eventsSendPort.send(<String, Object?>{
                  'installUri': bundleUri.toString(),
                  'prebuilt': prebuiltApplication,
                });
                installedApps.add('com.custom.test_project_app');
              },
              onIsAppInstalled: (String deviceId, String appId) async =>
                  installedApps.contains(appId),
              onUninstallApp: (String deviceId, String appId) async => installedApps.remove(appId),
            ),
          ]),
        );
      }

      final (_, ExtensionBackedDevice device, _) = await spawnDevice(entryPoint);
      expect(await device.targetPlatform, TargetPlatform.unsupported);
      expect(device.supportsInstall, isTrue);
      expect(device.supportsScreenshot, isTrue);

      final File prebuiltFile = fs.file('/prebuilt/custom_archive.pkg')
        ..createSync(recursive: true);
      final ApplicationPackage? prebuiltPkg = await device.resolveApplicationPackage(
        applicationBinary: prebuiltFile,
        buildInfo: BuildInfo.release,
      );
      expect(prebuiltPkg, isA<PrebuiltExtensionBackedApplicationPackage>());
      expect(prebuiltPkg!.id, 'com.custom.test_project_app');
      expect(prebuiltPkg.name, 'custom_archive.pkg');

      final Directory prebuiltBundleDir = fs.directory('/prebuilt/MyApp.app')
        ..createSync(recursive: true);
      final ApplicationPackage? prebuiltDirPkg = await device.resolveApplicationPackage(
        applicationBinary: fs.file(prebuiltBundleDir.path),
        buildInfo: BuildInfo.release,
      );
      expect(
        (prebuiltDirPkg! as PrebuiltExtensionBackedApplicationPackage).applicationPackage,
        isA<Directory>(),
      );

      expect(await device.isAppInstalled(prebuiltPkg), isFalse);
      expect(await device.installApp(prebuiltDirPkg), isTrue);
      expect(await device.uninstallApp(prebuiltDirPkg), isTrue);
      expect(await device.installApp(prebuiltPkg), isTrue);
      expect(await device.isAppInstalled(prebuiltPkg), isTrue);
      expect(await device.uninstallApp(prebuiltPkg), isTrue);
      expect(await device.isAppInstalled(prebuiltPkg), isFalse);

      await pumpEventQueue();
      expect(receivedInstalls, <({Uri bundleUri, bool prebuiltApplication})>[
        (bundleUri: prebuiltBundleDir.absolute.uri, prebuiltApplication: true),
        (bundleUri: prebuiltFile.absolute.uri, prebuiltApplication: true),
      ]);
    });

    test(
      'fails installApp without building when built bundle is missing, then installs once present',
      () async {
        final receivedInstalls = <({Uri bundleUri, bool prebuiltApplication})>[];
        final eventsPort = ReceivePort();
        addTearDown(eventsPort.close);
        eventsPort.listen((Object? message) {
          if (message case {
            'installUri': final String installUriStr,
            'prebuilt': final bool prebuilt,
          }) {
            receivedInstalls.add((
              bundleUri: Uri.parse(installUriStr),
              prebuiltApplication: prebuilt,
            ));
          }
        });
        final SendPort eventsSendPort = eventsPort.sendPort;

        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _TestDeviceService(
                onResolveApplication: (ExtensionApplicationResolutionContext context) async =>
                    ExtensionApplicationPackage(
                      appId: 'com.custom.${context.project.appName}',
                      bundleUri: context.project.buildDirectory.resolve(
                        'custom_os/${context.buildMode.cliName}/app.pkg',
                      ),
                    ),
                onInstallApp: (String deviceId, Uri bundleUri, bool prebuiltApplication) async {
                  eventsSendPort.send(<String, Object?>{
                    'installUri': bundleUri.toString(),
                    'prebuilt': prebuiltApplication,
                  });
                },
              ),
            ]),
          );
        }

        final (_, ExtensionBackedDevice device, _FakeExtensionBuildManager buildManager) =
            await spawnDevice(entryPoint);
        final ApplicationPackage? builtPkg = await device.resolveApplicationPackage(
          buildInfo: BuildInfo.release,
        );
        expect(builtPkg, isA<ExtensionBackedApplicationPackage>());
        expect(builtPkg, isNot(isA<PrebuiltApplicationPackage>()));

        expect(await device.installApp(builtPkg!), isFalse);
        expect(buildManager.buildCalls, isEmpty);
        expect(
          logger.errorText,
          contains(
            'Run "flutter build custom-linux-build" first, or pass "--use-application-binary".',
          ),
        );

        logger.clear();
        final Uri expectedBuiltUri = (builtPkg as ExtensionBackedApplicationPackage).bundleUri!;
        fs.file(expectedBuiltUri).createSync(recursive: true);
        expect(await device.installApp(builtPkg), isTrue);
        expect(buildManager.buildCalls, isEmpty);
        await pumpEventQueue();
        expect(receivedInstalls, <({Uri bundleUri, bool prebuiltApplication})>[
          (bundleUri: expectedBuiltUri, prebuiltApplication: false),
        ]);
      },
    );

    test('falls back to pubspec appName when resolveApplication returns null or -32601 (METHOD_NOT_FOUND)', () async {
      void nullEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TestDeviceService()]),
        );
      }

      final (_, ExtensionBackedDevice nullDevice, _) = await spawnDevice(nullEntryPoint);
      final ApplicationPackage? fallbackPkg = await nullDevice.resolveApplicationPackage(
        buildInfo: BuildInfo.debug,
      );
      expect(fallbackPkg!.id, 'test_project_app');
      expect((fallbackPkg as ExtensionBackedApplicationPackage).bundleUri, isNull);

      void legacyEntryPoint(SendPort sendPort) {
        final channel = IsolateChannel<Object?>.connectSend(sendPort);
        final peer = json_rpc.Peer.withoutJson(channel)
          ..registerMethod(ToolExtensionEntryPoint.getCapabilitiesMethod, () {
            return const ToolExtensionCapabilities(
              extensionName: 'legacy_device_ext',
              services: <String>[DeviceService.serviceNamespace],
              supportedPlatforms: <String>{'linux'},
            ).toMap();
          });
        unawaited(peer.listen());
      }

      final File prebuiltFile = fs.file('/prebuilt/legacy.pkg')..createSync(recursive: true);
      final (_, ExtensionBackedDevice legacyDevice, _) = await spawnDevice(legacyEntryPoint);
      logger.clear();
      final ApplicationPackage? legacyFallback = await legacyDevice.resolveApplicationPackage(
        applicationBinary: prebuiltFile,
        buildInfo: BuildInfo.debug,
      );
      expect(legacyFallback, isA<PrebuiltExtensionBackedApplicationPackage>());
      expect(legacyFallback!.id, 'test_project_app');
      expect(logger.errorText, isEmpty);
    });

    test('delegates takeScreenshot and treats !supportsInstall as no-op', () async {
      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestDeviceService(onTakeScreenshot: (String _, Uri _) async {}),
          ]),
        );
      }

      final (_, ExtensionBackedDevice screenshotDevice, _) = await spawnDevice(entryPoint);
      await screenshotDevice.takeScreenshot(fs.file('/captures/screen.png'));

      final (_, ExtensionBackedDevice noInstallDevice, _) = await spawnDevice(
        entryPoint,
        target: const TargetDevice(
          category: Category.desktop,
          id: 'ext-device-no-install',
          name: 'No Install Extension Device',
        ),
      );
      final File bundleFile = fs.file('/build/app.pkg')..createSync(recursive: true);
      final app = PrebuiltExtensionBackedApplicationPackage(
        applicationPackage: bundleFile,
        bundleUri: bundleFile.absolute.uri,
        id: 'com.example.app',
        name: 'app.pkg',
      );
      expect(noInstallDevice.supportsInstall, isFalse);
      expect(noInstallDevice.supportsScreenshot, isFalse);
      expect(await noInstallDevice.isAppInstalled(app), isFalse);
      expect(await noInstallDevice.installApp(app), isTrue);
      expect(await noInstallDevice.uninstallApp(app), isTrue);
      expect(logger.errorText, isEmpty);
    });

    test('getLogReader recreates idle reader on appId change and preserves active subscribers', () async {
      final startedLogAppIds = <String?>[];
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      eventsPort.listen((Object? message) {
        if (message case {'startLogAppId': final String? appId}) {
          startedLogAppIds.add(appId);
        }
      });
      final SendPort eventsSendPort = eventsPort.sendPort;

      void entryPoint(SendPort sendPort) {
        late final _TestDeviceService service;
        service = _TestDeviceService(
          onStartLogStream: (String deviceId, String? appId) async {
            eventsSendPort.send(<String, Object?>{'startLogAppId': appId});
            service.emitLogLine(deviceId: deviceId, line: 'log:${appId ?? '*'}');
          },
        );
        unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[service]));
      }

      final (_, ExtensionBackedDevice device, _) = await spawnDevice(entryPoint);
      final appPkg = ExtensionBackedApplicationPackage(id: 'com.example.app');

      // Idle reader is recreated when appId scope changes.
      final DeviceLogReader idleReader = await device.getLogReader();
      final DeviceLogReader appReader = await device.getLogReader(app: appPkg);
      expect(identical(idleReader, appReader), isFalse);
      expect((idleReader as ExtensionDeviceLogReader).isDisposed, isTrue);

      // Active subscriber keeps its fixed stream without silent widening or double startLogStream.
      var appClosed = false;
      final StreamSubscription<String> appSub = appReader.logLines.listen(
        (_) {},
        onDone: () => appClosed = true,
      );
      addTearDown(appSub.cancel);
      await pumpEventQueue();

      final DeviceLogReader sameReader = await device.getLogReader(
        app: ExtensionBackedApplicationPackage(id: 'com.example.other_app'),
      );
      expect(identical(sameReader, appReader), isTrue);
      expect(appClosed, isFalse);
      await appReader.dispose();
      expect(appClosed, isTrue);
      await pumpEventQueue();
      expect(startedLogAppIds, <String?>[null, 'com.example.app']);
    });

    test(
      'getLogReader deduplicates concurrent callers after dispose and handles disposed connection',
      () async {
        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TestDeviceService()]),
          );
        }

        final (ExtensionConnection conn, ExtensionBackedDevice device, _) = await spawnDevice(
          entryPoint,
        );
        final appPkg = ExtensionBackedApplicationPackage(id: 'com.example.app');

        final List<DeviceLogReader> concurrent = await Future.wait(<Future<DeviceLogReader>>[
          device.getLogReader(app: appPkg),
          device.getLogReader(app: appPkg),
        ]);
        expect(identical(concurrent[0], concurrent[1]), isTrue);
        await concurrent[0].dispose();

        // Calling getLogReader after connection.dispose() handles synchronous StateError cleanly.
        await conn.dispose();
        logger.clear();
        final DeviceLogReader postCloseReader = await device.getLogReader(app: appPkg);
        expect((postCloseReader as ExtensionDeviceLogReader).isDisposed, isTrue);
        expect(
          logger.warningText,
          contains('Failed to start log stream for extension device "ext-device-1"'),
        );
      },
    );

    test('formats ToolExtensionException (-32001) and default DeviceService UnsupportedError over real RPC', () async {
      void domainErrorEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestDeviceService(
              onResolveApplication: (ExtensionApplicationResolutionContext _) async =>
                  throw const ToolExtensionException('Manifest missing appId.'),
              onInstallApp: (String _, Uri _, bool _) async =>
                  throw const ToolExtensionException('Device storage full.'),
              onIsAppInstalled: (String _, String _) async =>
                  throw const ToolExtensionException('Device offline.'),
              onUninstallApp: (String _, String _) async =>
                  throw const ToolExtensionException('App is system-protected.'),
              onTakeScreenshot: (String _, Uri _) async =>
                  throw const ToolExtensionException('Screen is locked.'),
            ),
          ], extensionName: 'domain_error_extension'),
        );
      }

      final File bundleFile = fs.file('/build/app.pkg')..createSync(recursive: true);
      final app = PrebuiltExtensionBackedApplicationPackage(
        applicationPackage: bundleFile,
        bundleUri: bundleFile.absolute.uri,
        id: 'com.example.app',
        name: 'app.pkg',
      );

      final (_, ExtensionBackedDevice domainDevice, _) = await spawnDevice(domainErrorEntryPoint);
      expect(await domainDevice.resolveApplicationPackage(buildInfo: BuildInfo.debug), isNull);
      expect(
        logger.errorText.trim(),
        'Failed to resolve application for "ext-device-1" '
        '("domain_error_extension"): Manifest missing appId.',
      );
      logger.clear();
      expect(await domainDevice.isAppInstalled(app), isFalse);
      expect(
        logger.errorText.trim(),
        'Failed to check if application "com.example.app" is installed on '
        '"ext-device-1" ("domain_error_extension"): Device offline.',
      );
      logger.clear();
      expect(await domainDevice.installApp(app), isFalse);
      expect(
        logger.errorText.trim(),
        'Failed to install application "com.example.app" on '
        '"ext-device-1" ("domain_error_extension"): Device storage full.',
      );
      logger.clear();
      expect(await domainDevice.uninstallApp(app), isFalse);
      expect(
        logger.errorText.trim(),
        'Failed to uninstall application "com.example.app" from '
        '"ext-device-1" ("domain_error_extension"): App is system-protected.',
      );
      await expectLater(
        domainDevice.takeScreenshot(fs.file('/captures/domain_fail.png')),
        throwsToolExit(
          message:
              'Failed to take screenshot on "ext-device-1" '
              '("domain_error_extension"): Screen is locked.',
        ),
      );

      // Default DeviceService throws UnsupportedError across the real isolate RPC boundary.
      void defaultEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _TestDeviceService(),
          ], extensionName: 'default_device_extension'),
        );
      }

      final (_, ExtensionBackedDevice defaultDevice, _) = await spawnDevice(defaultEntryPoint);
      logger.clear();
      expect(await defaultDevice.installApp(app), isFalse);
      expect(logger.errorText, contains('App installation is not supported on ext-device-1.'));
      logger.clear();
      expect(await defaultDevice.uninstallApp(app), isFalse);
      expect(logger.errorText, contains('App uninstallation is not supported on ext-device-1.'));
      logger.clear();
      expect(await defaultDevice.isAppInstalled(app), isFalse);
      expect(
        logger.errorText,
        contains('Checking app installation status is not supported on ext-device-1.'),
      );
      await expectLater(
        defaultDevice.takeScreenshot(fs.file('/captures/default_unsupported.png')),
        throwsToolExit(message: 'Screenshots are not supported on ext-device-1.'),
      );
    });

    test(
      'catches raw UnsupportedError and disposed ExtensionConnection StateError via on Object',
      () async {
        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_TestDeviceService()]),
          );
        }

        final File bundleFile = fs.file('/build/app.pkg')..createSync(recursive: true);
        final app = PrebuiltExtensionBackedApplicationPackage(
          applicationPackage: bundleFile,
          bundleUri: bundleFile.absolute.uri,
          id: 'com.example.app',
          name: 'app.pkg',
        );

        final (ExtensionConnection conn, ExtensionBackedDevice device, _) = await spawnDevice(
          entryPoint,
        );
        await conn.dispose();
        logger.clear();
        expect(await device.isAppInstalled(app), isFalse);
        expect(
          logger.errorText,
          contains('Failed to check if application "com.example.app" is installed'),
        );

        final unsupportedDevice = ExtensionBackedDevice(
          buildManager: _createBuildManager(logger: logger),
          connection: conn,
          deviceService: _TestDeviceService(
            onResolveApplication: (ExtensionApplicationResolutionContext _) async =>
                throw UnsupportedError('Not supported'),
          ),
          fileSystem: fs,
          logger: logger,
          targetDevice: targetDevice,
        );
        logger.clear();
        expect(
          await unsupportedDevice.resolveApplicationPackage(buildInfo: BuildInfo.debug),
          isNull,
        );
        expect(logger.errorText, contains('Unsupported operation: Not supported'));
        logger.clear();
        expect(await unsupportedDevice.installApp(app), isFalse);
        expect(logger.errorText, contains('App installation is not supported'));
        logger.clear();
        expect(await unsupportedDevice.uninstallApp(app), isFalse);
        expect(logger.errorText, contains('App uninstallation is not supported'));
        logger.clear();
        expect(await unsupportedDevice.isAppInstalled(app), isFalse);
        expect(logger.errorText, contains('Checking app installation status is not supported'));
        await expectLater(
          unsupportedDevice.takeScreenshot(fs.file('/captures/unsupported.png')),
          throwsToolExit(message: 'Screenshots are not supported on ext-device-1.'),
        );
      },
    );
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
  Future<void> startLogStream({required String deviceId, String? appId}) async {}

  @override
  Future<void> stopLogStream({required String deviceId}) async {}
}
