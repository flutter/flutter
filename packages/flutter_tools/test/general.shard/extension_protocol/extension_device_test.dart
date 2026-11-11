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
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_core/json.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

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

final class _TestDeviceService extends DeviceService {
  _TestDeviceService({
    this.onInstallApp,
    this.onIsAppInstalled,
    this.onStartScreenRecording,
    this.onStopScreenRecording,
    this.onTakeScreenshot,
    this.onUninstallApp,
  });

  final Future<bool> Function(String deviceId, Uri bundleUri)? onInstallApp;
  final Future<bool> Function(String deviceId, String? appId, ExtensionFlutterProject project)?
  onIsAppInstalled;
  final Future<void> Function(String deviceId, Uri outputFileUri, Duration? duration)?
  onStartScreenRecording;
  final Future<Uri> Function(String deviceId)? onStopScreenRecording;
  final Future<void> Function(String deviceId, Uri outputFileUri)? onTakeScreenshot;
  final Future<bool> Function(String deviceId, String? appId, ExtensionFlutterProject project)?
  onUninstallApp;

  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

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
  Future<bool> installApp({required Uri bundleUri, required String deviceId}) async {
    if (onInstallApp case final callback?) {
      return callback(deviceId, bundleUri);
    }
    return super.installApp(bundleUri: bundleUri, deviceId: deviceId);
  }

  @override
  Future<bool> uninstallApp({
    required String deviceId,
    required ExtensionFlutterProject project,
    String? appId,
  }) async {
    if (onUninstallApp case final callback?) {
      return callback(deviceId, appId, project);
    }
    return super.uninstallApp(appId: appId, deviceId: deviceId, project: project);
  }

  @override
  Future<bool> isAppInstalled({
    required String deviceId,
    required ExtensionFlutterProject project,
    String? appId,
  }) async {
    if (onIsAppInstalled case final callback?) {
      return callback(deviceId, appId, project);
    }
    return super.isAppInstalled(appId: appId, deviceId: deviceId, project: project);
  }

  @override
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    if (onTakeScreenshot case final callback?) {
      return callback(deviceId, outputFileUri);
    }
    return super.takeScreenshot(deviceId: deviceId, outputFileUri: outputFileUri);
  }

  @override
  Future<void> startScreenRecording({
    required String deviceId,
    required Uri outputFileUri,
    Duration? duration,
  }) async {
    if (onStartScreenRecording case final callback?) {
      return callback(deviceId, outputFileUri, duration);
    }
    return super.startScreenRecording(
      deviceId: deviceId,
      duration: duration,
      outputFileUri: outputFileUri,
    );
  }

  @override
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    if (onStopScreenRecording case final callback?) {
      return callback(deviceId);
    }
    return super.stopScreenRecording(deviceId: deviceId);
  }
}

final class _FakePrebuiltApplicationPackage extends ApplicationPackage
    implements PrebuiltApplicationPackage {
  _FakePrebuiltApplicationPackage({required super.id, required this.applicationPackage});

  @override
  final FileSystemEntity applicationPackage;

  @override
  String? get name => id;
}

final class _FakeNonPrebuiltApplicationPackage extends ApplicationPackage {
  _FakeNonPrebuiltApplicationPackage({required super.id});

  @override
  String? get name => id;
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
          throwsA(_isInvalidParamsRpcException()),
        );

        await expectLater(
          conn.sendRequest(
            method,
            params: const <String, Object?>{DeviceService.deviceIdParam: ''},
          ),
          throwsA(_isInvalidParamsRpcException()),
        );

        await expectLater(
          conn.sendRequest(
            method,
            params: const <String, Object?>{DeviceService.deviceIdParam: 42},
          ),
          throwsA(_isInvalidParamsRpcException()),
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
  });

  group('TargetDevice install and capture capabilities', () {
    testWithoutContext('serializes and deserializes supportsInstall, supportsScreenshot, and supportsScreenRecording', () {
      const device = TargetDevice(
        category: Category.mobile,
        id: 'capture_device',
        name: 'Capture Device',
        supportsInstall: true,
        supportsScreenRecording: true,
        supportsScreenshot: true,
      );

      final Map<String, Object?> map = device.toMap();
      expect(map[TargetDevice.supportsInstallKey], isTrue);
      expect(map[TargetDevice.supportsScreenshotKey], isTrue);
      expect(map[TargetDevice.supportsScreenRecordingKey], isTrue);

      final parsed = TargetDevice.fromJson(map);
      expect(parsed, equals(device));
      expect(parsed.supportsInstall, isTrue);
      expect(parsed.supportsScreenshot, isTrue);
      expect(parsed.supportsScreenRecording, isTrue);
      expect(parsed.hashCode, equals(device.hashCode));
      expect(
        parsed.toString(),
        allOf(
          contains('supportsInstall: true'),
          contains('supportsScreenshot: true'),
          contains('supportsScreenRecording: true'),
        ),
      );
    });

    testWithoutContext('defaults supportsInstall, supportsScreenshot, and supportsScreenRecording to false when omitted', () {
      final parsed = TargetDevice.fromJson(const <String, Object?>{
        TargetDevice.categoryKey: 'desktop',
        TargetDevice.idKey: 'default_device',
        TargetDevice.nameKey: 'Default Device',
      });

      expect(parsed.supportsInstall, isFalse);
      expect(parsed.supportsScreenshot, isFalse);
      expect(parsed.supportsScreenRecording, isFalse);
    });

    testWithoutContext('throws FormatException when supportsInstall, supportsScreenshot, or supportsScreenRecording is not bool', () {
      expect(
        () =>
            TargetDevice.fromJson(const <String, Object?>{TargetDevice.supportsInstallKey: 'yes'}),
        throwsFormatException,
      );
      expect(
        () => TargetDevice.fromJson(const <String, Object?>{
          TargetDevice.supportsScreenshotKey: 'yes',
        }),
        throwsFormatException,
      );
      expect(
        () => TargetDevice.fromJson(const <String, Object?>{
          TargetDevice.supportsScreenRecordingKey: 1,
        }),
        throwsFormatException,
      );
    });
  });

  group('DeviceService RPC install and capture', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    testWithoutContext(
      'handles installApp, uninstallApp, and isAppInstalled over RPC with appId and project',
      () async {
        final events = <Map<String, Object?>>[];
        final eventsPort = ReceivePort();
        addTearDown(eventsPort.close);
        final StreamSubscription<Object?> sub = eventsPort.listen((Object? message) {
          if (message case final Map<String, Object?> map) {
            events.add(map);
          }
        });
        addTearDown(sub.cancel);
        final SendPort eventsSendPort = eventsPort.sendPort;

        void entryPoint(SendPort sendPort) {
          final installedApps = <String>{};
          unawaited(
            ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[
                _TestDeviceService(
                  onInstallApp: (String deviceId, Uri bundleUri) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'installApp',
                      'deviceId': deviceId,
                      'bundleUri': bundleUri.toString(),
                    });
                    installedApps.add('com.example.app');
                    installedApps.add('project_app');
                    return true;
                  },
                  onIsAppInstalled:
                      (String deviceId, String? appId, ExtensionFlutterProject project) async {
                        eventsSendPort.send(<String, Object?>{
                          'method': 'isAppInstalled',
                          'deviceId': deviceId,
                          'appId': appId,
                          'projectName': project.appName,
                        });
                        return (appId != null && installedApps.contains(appId)) ||
                            installedApps.contains(project.appName);
                      },
                  onUninstallApp:
                      (String deviceId, String? appId, ExtensionFlutterProject project) async {
                        eventsSendPort.send(<String, Object?>{
                          'method': 'uninstallApp',
                          'deviceId': deviceId,
                          'appId': appId,
                          'projectName': project.appName,
                        });
                        var removed = false;
                        if (appId != null) {
                          removed = installedApps.remove(appId) || removed;
                        }
                        removed = installedApps.remove(project.appName) || removed;
                        return removed;
                      },
                ),
              ],
              supportedPlatforms: const <String>{'linux'},
            ),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);
        final client = ExtensionDeviceClient(conn, logger: logger);

        const deviceId = 'device-1';
        const appId = 'com.example.app';
        final bundleUri = Uri.file('/tmp/build/app.bundle');
        final project = ExtensionFlutterProject(
          appName: 'project_app',
          buildDirectory: Uri.directory('/tmp/project/build/'),
          directory: Uri.directory('/tmp/project/'),
        );

        expect(
          await client.isAppInstalled(appId: appId, deviceId: deviceId, project: project),
          isFalse,
        );
        expect(await client.installApp(bundleUri: bundleUri, deviceId: deviceId), isTrue);

        expect(
          await client.isAppInstalled(appId: appId, deviceId: deviceId, project: project),
          isTrue,
        );
        expect(await client.isAppInstalled(deviceId: deviceId, project: project), isTrue);
        expect(
          await client.uninstallApp(appId: appId, deviceId: deviceId, project: project),
          isTrue,
        );
        expect(
          await client.isAppInstalled(appId: appId, deviceId: deviceId, project: project),
          isFalse,
        );
        expect(await client.isAppInstalled(deviceId: deviceId, project: project), isFalse);
        await pumpEventQueue();

        expect(
          events,
          contains(
            equals(<String, Object?>{
              'method': 'uninstallApp',
              'deviceId': deviceId,
              'appId': appId,
              'projectName': 'project_app',
            }),
          ),
        );
      },
    );

    testWithoutContext(
      'handles takeScreenshot, startScreenRecording, and stopScreenRecording over RPC',
      () async {
        final events = <Map<String, Object?>>[];
        final eventsPort = ReceivePort();
        addTearDown(eventsPort.close);
        final StreamSubscription<Object?> sub = eventsPort.listen((Object? message) {
          if (message case final Map<String, Object?> map) {
            events.add(map);
          }
        });
        addTearDown(sub.cancel);
        final SendPort eventsSendPort = eventsPort.sendPort;

        void entryPoint(SendPort sendPort) {
          Uri? activeRecordingUri;
          unawaited(
            ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[
                _TestDeviceService(
                  onTakeScreenshot: (String deviceId, Uri outputFileUri) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'takeScreenshot',
                      'deviceId': deviceId,
                      'outputFileUri': outputFileUri.toString(),
                    });
                  },
                  onStartScreenRecording:
                      (String deviceId, Uri outputFileUri, Duration? duration) async {
                        activeRecordingUri = outputFileUri;
                        eventsSendPort.send(<String, Object?>{
                          'method': 'startScreenRecording',
                          'deviceId': deviceId,
                          'outputFileUri': outputFileUri.toString(),
                          'durationMs': duration?.inMilliseconds,
                        });
                      },
                  onStopScreenRecording: (String deviceId) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'stopScreenRecording',
                      'deviceId': deviceId,
                    });
                    return activeRecordingUri ?? Uri.file('/tmp/fallback.mp4');
                  },
                ),
              ],
              supportedPlatforms: const <String>{'linux'},
            ),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);
        final client = ExtensionDeviceClient(conn, logger: logger);

        const deviceId = 'device-capture';
        final screenshotUri = Uri.file('/tmp/screenshot.png');
        final recordingUri = Uri.file('/tmp/recording.mp4');

        await client.takeScreenshot(deviceId: deviceId, outputFileUri: screenshotUri);
        await client.startScreenRecording(
          deviceId: deviceId,
          duration: const Duration(seconds: 10),
          outputFileUri: recordingUri,
        );
        final Uri stoppedUri = await client.stopScreenRecording(deviceId: deviceId);
        expect(stoppedUri, equals(recordingUri));

        expect(events, hasLength(3));
        expect(events[0], <String, Object?>{
          'method': 'takeScreenshot',
          'deviceId': deviceId,
          'outputFileUri': screenshotUri.toString(),
        });
        expect(events[1], <String, Object?>{
          'method': 'startScreenRecording',
          'deviceId': deviceId,
          'outputFileUri': recordingUri.toString(),
          'durationMs': 10000,
        });
        expect(events[2], <String, Object?>{'method': 'stopScreenRecording', 'deviceId': deviceId});
      },
    );

    testWithoutContext('default DeviceService implementations return false for install methods and throw for capture', () async {
      void entryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[_TestDeviceService()],
            supportedPlatforms: const <String>{'linux'},
          ),
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
        await client.installApp(bundleUri: Uri.file('/tmp/app.bundle'), deviceId: deviceId),
        isFalse,
      );
      expect(
        await client.uninstallApp(appId: 'com.example.app', deviceId: deviceId, project: project),
        isFalse,
      );
      expect(
        await client.isAppInstalled(appId: 'com.example.app', deviceId: deviceId, project: project),
        isFalse,
      );

      await expectLater(
        client.takeScreenshot(deviceId: deviceId, outputFileUri: Uri.file('/tmp/out.png')),
        throwsA(isA<json_rpc.RpcException>()),
      );
      await expectLater(
        client.startScreenRecording(deviceId: deviceId, outputFileUri: Uri.file('/tmp/out.mp4')),
        throwsA(isA<json_rpc.RpcException>()),
      );
      await expectLater(
        client.stopScreenRecording(deviceId: deviceId),
        throwsA(isA<json_rpc.RpcException>()),
      );
    });

    testWithoutContext(
      'returns INVALID_PARAMS (-32602) on missing or invalid RPC parameters',
      () async {
        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[_TestDeviceService()],
              supportedPlatforms: const <String>{'linux'},
            ),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);

        // installApp: empty deviceId, relative bundleUri, non-file bundleUri, trailing-slash directory bundleUri.
        await expectLater(
          conn.sendRequest(
            DeviceService.installAppMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: '',
              DeviceService.bundleUriParam: 'file:///tmp/app.bundle',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.installAppMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.bundleUriParam: 'relative/path/app.bundle',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.installAppMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.bundleUriParam: 'https://example.com/app.bundle',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.installAppMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.bundleUriParam: 'file:///tmp/app.bundle/',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );

        // uninstallApp & isAppInstalled: empty deviceId, empty appId, missing project, invalid project.
        const validProjectMap = <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
        };
        for (final method in const <String>[
          DeviceService.uninstallAppMethod,
          DeviceService.isAppInstalledMethod,
        ]) {
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: '',
                DeviceService.appIdParam: 'com.example.app',
                DeviceService.projectParam: validProjectMap,
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: 'device-1',
                DeviceService.appIdParam: '',
                DeviceService.projectParam: validProjectMap,
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: 'device-1',
                DeviceService.appIdParam: 'com.example.app',
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: 'device-1',
                DeviceService.projectParam: const <String, Object?>{},
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: 'device-1',
                DeviceService.projectParam: <String, Object?>{
                  ExtensionFlutterProject.appNameKey: 'my_app',
                  ExtensionFlutterProject.buildDirectoryKey: 'relative/build/',
                  ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
                },
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
        }

        // takeScreenshot: empty deviceId, invalid outputFileUri.
        await expectLater(
          conn.sendRequest(
            DeviceService.takeScreenshotMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: '',
              DeviceService.outputFileUriParam: 'file:///tmp/screenshot.png',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.takeScreenshotMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.outputFileUriParam: 'relative/screenshot.png',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );

        // startScreenRecording: empty deviceId, invalid outputFileUri, negative durationMs, wrong type durationMs.
        await expectLater(
          conn.sendRequest(
            DeviceService.startScreenRecordingMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: '',
              DeviceService.outputFileUriParam: 'file:///tmp/recording.mp4',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.startScreenRecordingMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.outputFileUriParam: 'http://example.com/recording.mp4',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.startScreenRecordingMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.outputFileUriParam: 'file:///tmp/recording.mp4',
              DeviceService.durationMsParam: -100,
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.startScreenRecordingMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.outputFileUriParam: 'file:///tmp/recording.mp4',
              DeviceService.durationMsParam: '5000',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );

        // stopScreenRecording: empty deviceId, missing deviceId.
        await expectLater(
          conn.sendRequest(
            DeviceService.stopScreenRecordingMethod,
            params: <String, Object?>{DeviceService.deviceIdParam: ''},
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.stopScreenRecordingMethod,
            params: const <String, Object?>{},
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
      },
    );
  });

  group('ExtensionBackedDevice delegation', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
    });

    testWithoutContext('delegates installApp (prebuilt and buildTarget), uninstallApp, isAppInstalled (with project forwarding), takeScreenshot, startScreenRecording, and stopScreenRecording', () async {
      final receivedInstallUris = <Uri>[];
      final receivedProjectNames = <String?>[];
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      final StreamSubscription<Object?> sub = eventsPort.listen((Object? message) {
        if (message case {'installUri': final String installUriStr}) {
          receivedInstallUris.add(Uri.parse(installUriStr));
        } else if (message case {'projectName': final String? projectName}) {
          receivedProjectNames.add(projectName);
        }
      });
      addTearDown(sub.cancel);
      final SendPort eventsSendPort = eventsPort.sendPort;

      void entryPoint(SendPort sendPort) {
        final installedApps = <String>{};
        Uri? recordedUri;
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestDeviceService(
                onInstallApp: (String deviceId, Uri bundleUri) async {
                  eventsSendPort.send(<String, Object?>{'installUri': bundleUri.toString()});
                  if (bundleUri.isValidFileUri) {
                    installedApps.add('com.example.prebuilt');
                    installedApps.add('test_project_app');
                    return true;
                  }
                  return false;
                },
                onIsAppInstalled:
                    (String deviceId, String? appId, ExtensionFlutterProject project) async {
                      eventsSendPort.send(<String, Object?>{'projectName': project.appName});
                      return (appId != null && installedApps.contains(appId)) ||
                          installedApps.contains(project.appName);
                    },
                onUninstallApp:
                    (String deviceId, String? appId, ExtensionFlutterProject project) async {
                      eventsSendPort.send(<String, Object?>{'projectName': project.appName});
                      var removed = false;
                      if (appId != null) {
                        removed = installedApps.remove(appId) || removed;
                      }
                      removed = installedApps.remove(project.appName) || removed;
                      return removed;
                    },
                onTakeScreenshot: (String deviceId, Uri outputFileUri) async {},
                onStartScreenRecording:
                    (String deviceId, Uri outputFileUri, Duration? duration) async {
                      recordedUri = outputFileUri;
                    },
                onStopScreenRecording: (String deviceId) async {
                  return recordedUri ?? Uri.file('/tmp/default.mp4');
                },
              ),
            ],
            supportedPlatforms: const <String>{'linux'},
          ),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      final builtBundleUri = Uri.file('/build/output/custom_bundle.bin');
      final _FakeExtensionBuildManager buildManager = _createBuildManager(
        buildResult: ExtensionBuildResult(executableUri: builtBundleUri, success: true),
        logger: logger,
      );

      const targetDevice = TargetDevice(
        buildTarget: 'custom-linux-build',
        category: Category.mobile,
        id: 'ext-device-1',
        name: 'Extension Device 1',
        supportsInstall: true,
        supportsScreenRecording: true,
        supportsScreenshot: true,
      );
      final device = ExtensionBackedDevice(
        buildManager: buildManager,
        connection: conn,
        deviceService: client,
        fileSystem: fs,
        logger: logger,
        targetDevice: targetDevice,
      );

      expect(device.supportsInstall, isTrue);
      expect(device.supportsScreenshot, isTrue);
      expect(device.supportsScreenRecording, isTrue);

      final File bundleFile = fs.file('/build/app.apk')..createSync(recursive: true);
      final app = _FakePrebuiltApplicationPackage(
        id: 'com.example.prebuilt',
        applicationPackage: bundleFile,
      );

      expect(await device.isAppInstalled(app), isFalse);
      expect(await device.installApp(app), isTrue);
      expect(await device.isAppInstalled(app), isTrue);
      expect(await device.uninstallApp(app), isTrue);
      expect(await device.isAppInstalled(app), isFalse);
      expect(receivedInstallUris.first, equals(bundleFile.absolute.uri));

      // Non-prebuilt install via ExtensionApplicationPackage triggers ExtensionBuildManager.build
      // and forwards ExtensionFlutterProject on isAppInstalled and uninstallApp.
      fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: test_project_app\n');
      final FlutterProject flutterProject = FlutterProjectFactory(
        fileSystem: fs,
        logger: logger,
      ).fromDirectory(fs.currentDirectory);
      final extensionApp = ExtensionApplicationPackage(
        id: 'test_project_app',
        buildInfo: BuildInfo.release,
        project: flutterProject,
      );

      expect(await device.installApp(extensionApp), isTrue);
      expect(buildManager.buildCalls, hasLength(1));
      expect(buildManager.buildCalls.single.buildMode, BuildMode.release);
      expect(buildManager.buildCalls.single.targetName, 'custom-linux-build');
      expect(receivedInstallUris.last, equals(builtBundleUri));

      expect(await device.isAppInstalled(extensionApp), isTrue);
      expect(await device.uninstallApp(extensionApp), isTrue);
      expect(await device.isAppInstalled(extensionApp), isFalse);
      expect(receivedProjectNames, contains('test_project_app'));

      final File screenshotFile = fs.file('/captures/screen.png');
      await device.takeScreenshot(screenshotFile);

      final File recordingFile = fs.file('/captures/video.mp4');
      await device.startScreenRecording(recordingFile, duration: const Duration(seconds: 5));
      final Uri savedRecordingUri = await device.stopScreenRecording();
      expect(savedRecordingUri, equals(recordingFile.absolute.uri));
    });

    testWithoutContext(
      'installApp without prebuilt binary fails when device has no buildTarget',
      () async {
        void entryPoint(SendPort sendPort) {
          unawaited(
            ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[_TestDeviceService()],
              supportedPlatforms: const <String>{'linux'},
            ),
          );
        }

        final ExtensionConnection conn = await ExtensionConnection.spawn(
          entryPoint,
          logger: logger,
        );
        addTearDown(conn.dispose);
        final client = ExtensionDeviceClient(conn, logger: logger);

        final device = ExtensionBackedDevice(
          buildManager: _createBuildManager(logger: logger),
          connection: conn,
          deviceService: client,
          fileSystem: fs,
          logger: logger,
          targetDevice: const TargetDevice(
            category: Category.mobile,
            id: 'ext-device-no-build-target',
            name: 'Extension Device No Build Target',
            supportsInstall: true,
          ),
        );

        final nonPrebuiltApp = _FakeNonPrebuiltApplicationPackage(id: 'com.example.nonprebuilt');
        expect(await device.installApp(nonPrebuiltApp), isFalse);
        expect(
          logger.errorText,
          contains(
            'Device Extension Device No Build Target does not specify a buildTarget for installing applications.',
          ),
        );
      },
    );

    testWithoutContext('isAppInstalled, installApp, and uninstallApp handle !supportsInstall, catch RPC and peer-exit exceptions, and propagate host errors', () async {
      void failingEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestDeviceService(
                onInstallApp: (String _, Uri _) async {
                  throw StateError('Simulated install failure');
                },
                onIsAppInstalled: (String _, String? _, ExtensionFlutterProject _) async {
                  throw StateError('Simulated isAppInstalled failure');
                },
                onUninstallApp: (String _, String? _, ExtensionFlutterProject _) async {
                  throw StateError('Simulated uninstall failure');
                },
              ),
            ],
            extensionName: 'failing_device_extension',
            supportedPlatforms: const <String>{'linux'},
          ),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(
        failingEntryPoint,
        logger: logger,
      );
      addTearDown(conn.dispose);
      final client = ExtensionDeviceClient(conn, logger: logger);

      final File bundleFile = fs.file('/build/app.apk')..createSync(recursive: true);
      final app = _FakePrebuiltApplicationPackage(
        id: 'com.example.app',
        applicationPackage: bundleFile,
      );

      // When supportsInstall is false, installApp and uninstallApp return true and
      // isAppInstalled returns false without calling the extension (matching DesktopDevice).
      final unsupportedInstallDevice = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: client,
        fileSystem: fs,
        logger: logger,
        targetDevice: const TargetDevice(
          category: Category.desktop,
          id: 'ext-device-no-install',
          name: 'No Install Extension Device',
        ),
      );
      expect(unsupportedInstallDevice.supportsInstall, isFalse);
      expect(unsupportedInstallDevice.supportsScreenshot, isFalse);
      expect(unsupportedInstallDevice.supportsScreenRecording, isFalse);
      expect(await unsupportedInstallDevice.isAppInstalled(app), isFalse);
      expect(await unsupportedInstallDevice.installApp(app), isTrue);
      expect(await unsupportedInstallDevice.uninstallApp(app), isTrue);
      expect(logger.warningText, isEmpty);

      const targetDevice = TargetDevice(
        category: Category.mobile,
        id: 'ext-device-fail',
        name: 'Failing Extension Device',
        supportsInstall: true,
      );
      final device = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: client,
        fileSystem: fs,
        logger: logger,
        targetDevice: targetDevice,
      );

      expect(await device.isAppInstalled(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to check if application "com.example.app" is installed on '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      expect(await device.installApp(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to install application "com.example.app" on '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      expect(await device.uninstallApp(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to uninstall application "com.example.app" from '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      // When the extension isolate exits unexpectedly during installApp, both installApp
      // and a subsequent isAppInstalled catch ExtensionConnectionException and log warnings.
      void exitingEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestDeviceService(
                onInstallApp: (String _, Uri _) async {
                  Isolate.exit();
                },
              ),
            ],
            extensionName: 'exiting_device_extension',
            supportedPlatforms: const <String>{'linux'},
          ),
        );
      }

      final ExtensionConnection exitingConn = await ExtensionConnection.spawn(
        exitingEntryPoint,
        logger: logger,
      );
      addTearDown(exitingConn.dispose);
      final exitingDevice = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: exitingConn,
        deviceService: ExtensionDeviceClient(exitingConn, logger: logger),
        fileSystem: fs,
        logger: logger,
        targetDevice: targetDevice,
      );

      logger.clear();
      expect(await exitingDevice.installApp(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to install application "com.example.app" on '
          '"ext-device-fail" ("exiting_device_extension")',
        ),
      );
      logger.clear();
      expect(await exitingDevice.isAppInstalled(app), isFalse);
      expect(
        logger.warningText,
        contains(
          'Failed to check if application "com.example.app" is installed on '
          '"ext-device-fail" ("exiting_device_extension")',
        ),
      );

      final directErrorDevice = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: _TestDeviceService(
          onInstallApp: (String _, Uri _) => Future<bool>.error(StateError('Host bug')),
          onIsAppInstalled: (String _, String? _, ExtensionFlutterProject _) =>
              Future<bool>.error(StateError('Host bug')),
          onUninstallApp: (String _, String? _, ExtensionFlutterProject _) =>
              Future<bool>.error(StateError('Host bug')),
        ),
        fileSystem: fs,
        logger: logger,
        targetDevice: targetDevice,
      );
      await expectLater(directErrorDevice.isAppInstalled(app), throwsStateError);
      await expectLater(directErrorDevice.installApp(app), throwsStateError);
      await expectLater(directErrorDevice.uninstallApp(app), throwsStateError);
    });
  });
}
