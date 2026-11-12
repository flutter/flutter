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
  Future<bool> stopApp({required String deviceId, String? appId}) async {
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: 'stopApp',
      DeviceService.appIdParam: appId,
      DeviceService.deviceIdParam: deviceId,
    });
    return true;
  }

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
    this.onStartScreenRecording,
    this.onStopApp,
    this.onStopScreenRecording,
    this.onTakeScreenshot,
    this.onUninstallApp,
    this.onWaitForScreenRecording,
  });

  final Future<void> Function(String deviceId, Uri bundleUri, bool prebuiltApplication)?
  onInstallApp;
  final Future<bool> Function(String deviceId, String appId)? onIsAppInstalled;
  final Future<ExtensionApplicationPackage?> Function(
    ExtensionApplicationResolutionContext context,
  )?
  onResolveApplication;
  final Future<void> Function(String deviceId, String? appId)? onStartLogStream;
  final Future<void> Function(String deviceId, Uri outputFileUri, Duration? duration)?
  onStartScreenRecording;
  final Future<bool> Function(String deviceId, String? appId)? onStopApp;
  final Future<Uri> Function(String deviceId)? onStopScreenRecording;
  final Future<void> Function(String deviceId, Uri outputFileUri)? onTakeScreenshot;
  final Future<void> Function(String deviceId, String appId)? onUninstallApp;
  final Future<Uri> Function(String deviceId)? onWaitForScreenRecording;

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
  Future<bool> stopApp({required String deviceId, String? appId}) async {
    if (onStopApp case final callback?) {
      return callback(deviceId, appId);
    }
    return false;
  }

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
  Future<Uri> waitForScreenRecording({required String deviceId}) async {
    if (onWaitForScreenRecording case final callback?) {
      return callback(deviceId);
    }
    return super.waitForScreenRecording(deviceId: deviceId);
  }

  @override
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    if (onStopScreenRecording case final callback?) {
      return callback(deviceId);
    }
    return super.stopScreenRecording(deviceId: deviceId);
  }

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    if (onStartLogStream case final callback?) {
      return callback(deviceId, appId);
    }
    return super.startLogStream(deviceId: deviceId, appId: appId);
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

FakeToolContext _createToolContext({required Logger logger, FileSystem? fs}) {
  final FileSystem resolvedFs = fs ?? MemoryFileSystem.test();
  return FakeToolContext(fs: resolvedFs, logger: logger);
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

    testWithoutContext('streams log lines end-to-end, forwards appId, and recreates log reader after dispose or appId change', () async {
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
        targetDevice: targetDevices.first,
        toolContext: _createToolContext(logger: logger),
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

      // stopApp forwards appId when an ApplicationPackage is supplied.
      final Future<Map<String, Object?>> stopAppEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == 'stopApp',
      );
      expect(await device.stopApp(appPkg), isTrue);
      final Map<String, Object?> stopAppEvent = await stopAppEventFuture;
      expect(stopAppEvent[DeviceService.appIdParam], 'com.example.custom_app');

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
          targetDevice: targetDevices.firstWhere((TargetDevice d) => d.id == _primaryDeviceId),
          toolContext: _createToolContext(logger: logger),
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

    testWithoutContext('startLogStream, stopLogStream, and stopApp throw INVALID_PARAMS on missing, empty, or invalid parameters', () async {
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
        DeviceService.stopAppMethod,
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

      for (final method in <String>[
        DeviceService.startLogStreamMethod,
        DeviceService.stopAppMethod,
      ]) {
        await expectLater(
          conn.sendRequest(
            method,
            params: const <String, Object?>{
              DeviceService.deviceIdParam: _primaryDeviceId,
              DeviceService.appIdParam: '',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            method,
            params: const <String, Object?>{
              DeviceService.deviceIdParam: _primaryDeviceId,
              DeviceService.appIdParam: 123,
            },
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
        targetDevice: targetDevices.first,
        toolContext: _createToolContext(logger: logger),
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
        toolContext: _createToolContext(logger: logger),
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
          targetDevice: const TargetDevice(
            buildTarget: 'custom-linux-build',
            category: Category.desktop,
            id: 'test_device',
            name: 'Test Device',
          ),
          toolContext: _createToolContext(logger: logger),
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

  group('DeviceService RPC resolveApplication, install, and capture', () {
    late BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
    });

    testWithoutContext(
      'handles resolveApplication, installApp, uninstallApp, and isAppInstalled over RPC',
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
                  onResolveApplication: (ExtensionApplicationResolutionContext context) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'resolveApplication',
                      'deviceId': context.deviceId,
                      'buildMode': context.buildMode.cliName,
                      'flavor': context.flavor,
                      'projectName': context.project.appName,
                      'applicationBinaryUri': context.applicationBinaryUri?.toString(),
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
                      'deviceId': deviceId,
                      'bundleUri': bundleUri.toString(),
                      'prebuiltApplication': prebuiltApplication,
                    });
                    installedApps.add('com.example.project_app');
                  },
                  onIsAppInstalled: (String deviceId, String appId) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'isAppInstalled',
                      'deviceId': deviceId,
                      'appId': appId,
                    });
                    return installedApps.contains(appId);
                  },
                  onUninstallApp: (String deviceId, String appId) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'uninstallApp',
                      'deviceId': deviceId,
                      'appId': appId,
                    });
                    installedApps.remove(appId);
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
        expect(resolved, isNotNull);
        expect(resolved!.appId, 'com.example.project_app');
        expect(
          resolved.bundleUri,
          Uri.parse('file:///tmp/project/build/custom_os/release/app.pkg'),
        );

        expect(await client.isAppInstalled(appId: resolved.appId, deviceId: deviceId), isFalse);
        await client.installApp(
          bundleUri: resolved.bundleUri!,
          deviceId: deviceId,
          prebuiltApplication: true,
        );
        expect(await client.isAppInstalled(appId: resolved.appId, deviceId: deviceId), isTrue);
        await client.uninstallApp(appId: resolved.appId, deviceId: deviceId);
        expect(await client.isAppInstalled(appId: resolved.appId, deviceId: deviceId), isFalse);
        await pumpEventQueue();

        expect(
          events,
          containsAll(<Object>[
            <String, Object?>{
              'method': 'resolveApplication',
              'deviceId': deviceId,
              'buildMode': 'release',
              'flavor': 'staging',
              'projectName': 'project_app',
              'applicationBinaryUri': null,
            },
            <String, Object?>{
              'method': 'installApp',
              'deviceId': deviceId,
              'bundleUri': 'file:///tmp/project/build/custom_os/release/app.pkg',
              'prebuiltApplication': true,
            },
            <String, Object?>{
              'method': 'uninstallApp',
              'deviceId': deviceId,
              'appId': 'com.example.project_app',
            },
          ]),
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
                  onWaitForScreenRecording: (String deviceId) async {
                    eventsSendPort.send(<String, Object?>{
                      'method': 'waitForScreenRecording',
                      'deviceId': deviceId,
                    });
                    return activeRecordingUri ?? Uri.file('/tmp/fallback.mp4');
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
        final Uri waitedUri = await client.waitForScreenRecording(deviceId: deviceId);
        expect(waitedUri, equals(recordingUri));
        final Uri stoppedUri = await client.stopScreenRecording(deviceId: deviceId);
        expect(stoppedUri, equals(recordingUri));

        expect(events, hasLength(4));
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
        expect(events[2], <String, Object?>{
          'method': 'waitForScreenRecording',
          'deviceId': deviceId,
        });
        expect(events[3], <String, Object?>{'method': 'stopScreenRecording', 'deviceId': deviceId});
      },
    );

    testWithoutContext('default DeviceService returns null from resolveApplication and throws UnsupportedError for install and capture', () async {
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
        await client.resolveApplication(
          ExtensionApplicationResolutionContext(
            buildMode: BuildMode.debug,
            deviceId: deviceId,
            project: project,
          ),
        ),
        isNull,
      );

      await expectLater(
        client.installApp(bundleUri: Uri.file('/tmp/app.bundle'), deviceId: deviceId),
        throwsA(isA<json_rpc.RpcException>()),
      );
      await expectLater(
        client.uninstallApp(appId: 'com.example.app', deviceId: deviceId),
        throwsA(isA<json_rpc.RpcException>()),
      );
      await expectLater(
        client.isAppInstalled(appId: 'com.example.app', deviceId: deviceId),
        throwsA(isA<json_rpc.RpcException>()),
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
        client.waitForScreenRecording(deviceId: deviceId),
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

        const validProjectMap = <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
        };

        // resolveApplication: missing deviceId, empty deviceId, invalid buildMode, invalid applicationBinaryUri, empty flavor.
        await expectLater(
          conn.sendRequest(
            DeviceService.resolveApplicationMethod,
            params: <String, Object?>{
              ExtensionApplicationResolutionContext.buildModeKey: 'debug',
              ExtensionApplicationResolutionContext.projectKey: validProjectMap,
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.resolveApplicationMethod,
            params: <String, Object?>{
              ExtensionApplicationResolutionContext.buildModeKey: 'debug',
              ExtensionApplicationResolutionContext.deviceIdKey: '',
              ExtensionApplicationResolutionContext.projectKey: validProjectMap,
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.resolveApplicationMethod,
            params: <String, Object?>{
              ExtensionApplicationResolutionContext.buildModeKey: 'invalid_mode',
              ExtensionApplicationResolutionContext.deviceIdKey: 'device-1',
              ExtensionApplicationResolutionContext.projectKey: validProjectMap,
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.resolveApplicationMethod,
            params: <String, Object?>{
              ExtensionApplicationResolutionContext.applicationBinaryUriKey: 'relative/app.pkg',
              ExtensionApplicationResolutionContext.buildModeKey: 'debug',
              ExtensionApplicationResolutionContext.deviceIdKey: 'device-1',
              ExtensionApplicationResolutionContext.projectKey: validProjectMap,
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.resolveApplicationMethod,
            params: <String, Object?>{
              ExtensionApplicationResolutionContext.buildModeKey: 'debug',
              ExtensionApplicationResolutionContext.deviceIdKey: 'device-1',
              ExtensionApplicationResolutionContext.flavorKey: '',
              ExtensionApplicationResolutionContext.projectKey: validProjectMap,
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );

        // installApp: empty deviceId, relative bundleUri, non-file bundleUri, trailing-slash directory bundleUri, non-bool prebuiltApplication.
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
              DeviceService.bundleUriParam: 'file:///',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
        await expectLater(
          conn.sendRequest(
            DeviceService.installAppMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.bundleUriParam: 'file:///tmp/app.bundle',
              DeviceService.prebuiltApplicationParam: 'yes',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );

        // uninstallApp & isAppInstalled: empty deviceId, missing appId, empty appId, non-String appId.
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
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{DeviceService.deviceIdParam: 'device-1'},
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: 'device-1',
                DeviceService.appIdParam: '',
              },
            ),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(
              method,
              params: <String, Object?>{
                DeviceService.deviceIdParam: 'device-1',
                DeviceService.appIdParam: 42,
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

        // waitForScreenRecording & stopScreenRecording: empty deviceId, missing deviceId.
        for (final method in const <String>[
          DeviceService.waitForScreenRecordingMethod,
          DeviceService.stopScreenRecordingMethod,
        ]) {
          await expectLater(
            conn.sendRequest(method, params: <String, Object?>{DeviceService.deviceIdParam: ''}),
            throwsA(_isInvalidParamsRpcException()),
          );
          await expectLater(
            conn.sendRequest(method, params: const <String, Object?>{}),
            throwsA(_isInvalidParamsRpcException()),
          );
        }

        // stopApp: empty appId is rejected with INVALID_PARAMS.
        await expectLater(
          conn.sendRequest(
            DeviceService.stopAppMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: 'device-1',
              DeviceService.appIdParam: '',
            },
          ),
          throwsA(_isInvalidParamsRpcException()),
        );
      },
    );
  });

  group('ExtensionBackedDevice resolveApplicationPackage and delegation', () {
    late MemoryFileSystem fs;
    late BufferLogger logger;

    setUp(() {
      fs = MemoryFileSystem.test();
      fs.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: test_project_app\n');
      logger = BufferLogger.test();
    });

    testWithoutContext('resolves application via resolveApplication, falls back on null and METHOD_NOT_FOUND (-32601), and delegates install/uninstall/capture without building during install', () async {
      final receivedInstalls = <({Uri bundleUri, bool prebuiltApplication})>[];
      final receivedStops = <String?>[];
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      final StreamSubscription<Object?> sub = eventsPort.listen((Object? message) {
        if (message case {
          'installUri': final String installUriStr,
          'prebuilt': final bool prebuilt,
        }) {
          receivedInstalls.add((
            bundleUri: Uri.parse(installUriStr),
            prebuiltApplication: prebuilt,
          ));
        } else if (message case {'stopAppId': final String? stopAppId}) {
          receivedStops.add(stopAppId);
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
                onResolveApplication: (ExtensionApplicationResolutionContext context) async {
                  if (context.flavor == 'fallback_null') {
                    return null;
                  }
                  return ExtensionApplicationPackage(
                    appId: 'com.custom.${context.project.appName}',
                    bundleUri:
                        context.applicationBinaryUri ??
                        context.project.buildDirectory.resolve(
                          'custom_os/${context.buildMode.cliName}/app.pkg',
                        ),
                  );
                },
                onInstallApp: (String deviceId, Uri bundleUri, bool prebuiltApplication) async {
                  eventsSendPort.send(<String, Object?>{
                    'installUri': bundleUri.toString(),
                    'prebuilt': prebuiltApplication,
                  });
                  installedApps.add('com.custom.test_project_app');
                },
                onIsAppInstalled: (String deviceId, String appId) async {
                  return installedApps.contains(appId);
                },
                onStopApp: (String deviceId, String? appId) async {
                  eventsSendPort.send(<String, Object?>{'stopAppId': appId});
                  return true;
                },
                onUninstallApp: (String deviceId, String appId) async {
                  installedApps.remove(appId);
                },
                onTakeScreenshot: (String deviceId, Uri outputFileUri) async {},
                onStartScreenRecording:
                    (String deviceId, Uri outputFileUri, Duration? duration) async {
                      recordedUri = outputFileUri;
                    },
                onWaitForScreenRecording: (String deviceId) async {
                  return recordedUri ?? Uri.file('/tmp/default.mp4');
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
      final _FakeExtensionBuildManager buildManager = _createBuildManager(logger: logger);

      const targetDevice = TargetDevice(
        buildTarget: 'custom-linux-build',
        category: Category.mobile,
        id: 'ext-device-1',
        name: 'Extension Device 1',
        supportsInstall: true,
        supportsScreenRecording: true,
        supportsScreenshot: true,
        targetPlatform: 'custom-embedder-arm64',
      );
      final device = ExtensionBackedDevice(
        buildManager: buildManager,
        connection: conn,
        deviceService: client,
        targetDevice: targetDevice,
        toolContext: _createToolContext(fs: fs, logger: logger),
      );

      expect(await device.targetPlatform, TargetPlatform.unsupported);
      expect(device.supportsInstall, isTrue);
      expect(device.supportsScreenshot, isTrue);

      // Prebuilt package resolution wraps in PrebuiltExtensionBackedApplicationPackage for both files and directory bundles.
      final File prebuiltFile = fs.file('/prebuilt/custom_archive.pkg')
        ..createSync(recursive: true);
      final ApplicationPackage? prebuiltPkg = await device.resolveApplicationPackage(
        applicationBinary: prebuiltFile,
        buildInfo: BuildInfo.release,
      );
      expect(prebuiltPkg, isA<PrebuiltExtensionBackedApplicationPackage>());
      expect(prebuiltPkg, isA<PrebuiltApplicationPackage>());
      expect(prebuiltPkg!.id, 'com.custom.test_project_app');
      expect(prebuiltPkg.name, 'custom_archive.pkg');

      final Directory prebuiltBundleDir = fs.directory('/prebuilt/MyApp.app')
        ..createSync(recursive: true);
      final ApplicationPackage? prebuiltDirPkg = await device.resolveApplicationPackage(
        applicationBinary: fs.file(prebuiltBundleDir.path),
        buildInfo: BuildInfo.release,
      );
      expect(prebuiltDirPkg, isA<PrebuiltExtensionBackedApplicationPackage>());
      expect(
        (prebuiltDirPkg! as PrebuiltExtensionBackedApplicationPackage).applicationPackage,
        isA<Directory>(),
      );
      expect(await device.installApp(prebuiltDirPkg), isTrue);
      expect(await device.uninstallApp(prebuiltDirPkg), isTrue);

      expect(await device.isAppInstalled(prebuiltPkg), isFalse);
      expect(await device.installApp(prebuiltPkg), isTrue);
      expect(await device.isAppInstalled(prebuiltPkg), isTrue);
      expect(await device.uninstallApp(prebuiltPkg), isTrue);
      expect(await device.isAppInstalled(prebuiltPkg), isFalse);

      // Non-prebuilt package resolution does NOT build on install; fails when missing on disk.
      final ApplicationPackage? builtPkg = await device.resolveApplicationPackage(
        buildInfo: BuildInfo.release,
      );
      expect(builtPkg, isA<ExtensionBackedApplicationPackage>());
      expect(builtPkg, isNot(isA<PrebuiltApplicationPackage>()));
      expect(builtPkg!.id, 'com.custom.test_project_app');

      expect(await device.installApp(builtPkg), isFalse);
      expect(buildManager.buildCalls, isEmpty);
      expect(
        logger.errorText,
        contains(
          'Run "flutter build custom-linux-build" first, or pass "--use-application-binary".',
        ),
      );

      // Once the built bundle exists on disk, installApp installs it with prebuiltApplication: false.
      logger.clear();
      final Uri expectedBuiltUri = (builtPkg as ExtensionBackedApplicationPackage).bundleUri!;
      fs.file(expectedBuiltUri).createSync(recursive: true);
      expect(await device.installApp(builtPkg), isTrue);
      expect(buildManager.buildCalls, isEmpty);
      await pumpEventQueue();
      expect(receivedInstalls, <({Uri bundleUri, bool prebuiltApplication})>[
        (bundleUri: prebuiltBundleDir.absolute.uri, prebuiltApplication: true),
        (bundleUri: prebuiltFile.absolute.uri, prebuiltApplication: true),
        (bundleUri: expectedBuiltUri, prebuiltApplication: false),
      ]);

      expect(await device.stopApp(builtPkg), isTrue);
      expect(await device.stopApp(null), isTrue);
      await pumpEventQueue();
      expect(receivedStops, <String?>['com.custom.test_project_app', null]);

      // Fallback when resolveApplication returns null uses pubspec name and applicationBinaryUri.
      final ApplicationPackage? fallbackPkg = await device.resolveApplicationPackage(
        buildInfo: const BuildInfo(
          BuildMode.debug,
          'fallback_null',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      );
      expect(fallbackPkg, isA<ExtensionBackedApplicationPackage>());
      expect(fallbackPkg!.id, 'test_project_app');
      expect((fallbackPkg as ExtensionBackedApplicationPackage).bundleUri, isNull);

      // Fallback when an older extension returns -32601 (METHOD_NOT_FOUND).
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

      final ExtensionConnection legacyConn = await ExtensionConnection.spawn(
        legacyEntryPoint,
        logger: logger,
      );
      addTearDown(legacyConn.dispose);
      final legacyDevice = ExtensionBackedDevice(
        buildManager: buildManager,
        connection: legacyConn,
        deviceService: ExtensionDeviceClient(legacyConn, logger: logger),
        targetDevice: targetDevice,
        toolContext: _createToolContext(fs: fs, logger: logger),
      );
      logger.clear();
      final ApplicationPackage? legacyFallback = await legacyDevice.resolveApplicationPackage(
        applicationBinary: prebuiltFile,
        buildInfo: BuildInfo.debug,
      );
      expect(legacyFallback, isA<PrebuiltExtensionBackedApplicationPackage>());
      expect(legacyFallback!.id, 'test_project_app');
      expect(logger.errorText, isEmpty);

      final File screenshotFile = fs.file('/captures/screen.png');
      await device.takeScreenshot(screenshotFile);

      final File recordingFile = fs.file('/captures/video.mp4');
      await client.startScreenRecording(
        deviceId: device.id,
        duration: const Duration(seconds: 5),
        outputFileUri: recordingFile.absolute.uri,
      );
      final Uri waitedRecordingUri = await client.waitForScreenRecording(deviceId: device.id);
      expect(waitedRecordingUri, equals(recordingFile.absolute.uri));
      final Uri savedRecordingUri = await client.stopScreenRecording(deviceId: device.id);
      expect(savedRecordingUri, equals(recordingFile.absolute.uri));
    });

    testWithoutContext('getLogReader preserves active subscribers across scope changes and deduplicates concurrent callers after dispose', () async {
      final startedLogAppIds = <String?>[];
      final eventsPort = ReceivePort();
      addTearDown(eventsPort.close);
      final StreamSubscription<Object?> sub = eventsPort.listen((Object? message) {
        if (message case {'startLogAppId': final String? appId}) {
          startedLogAppIds.add(appId);
        }
      });
      addTearDown(sub.cancel);
      final SendPort eventsSendPort = eventsPort.sendPort;

      void entryPoint(SendPort sendPort) {
        late final _TestDeviceService service;
        service = _TestDeviceService(
          onStartLogStream: (String deviceId, String? appId) async {
            eventsSendPort.send(<String, Object?>{'startLogAppId': appId});
            service.emitLogLine(deviceId: deviceId, line: 'log:${appId ?? '*'}');
          },
        );
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[service],
            supportedPlatforms: const <String>{'linux'},
          ),
        );
      }

      final ExtensionConnection conn = await ExtensionConnection.spawn(entryPoint, logger: logger);
      addTearDown(conn.dispose);
      final device = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: ExtensionDeviceClient(conn, logger: logger),
        targetDevice: const TargetDevice(
          category: Category.mobile,
          id: 'ext-log-device',
          name: 'Log Extension Device',
        ),
        toolContext: _createToolContext(fs: fs, logger: logger),
      );
      final appPkg = ExtensionBackedApplicationPackage(id: 'com.example.app');

      // Scenario A: Active device-wide subscriber (e.g. flutter daemon) is NOT closed when getLogReader(app: pkg) runs.
      final DeviceLogReader daemonReader = await device.getLogReader();
      var daemonClosed = false;
      final daemonLines = <String>[];
      final StreamSubscription<String> daemonSub = daemonReader.logLines.listen(
        daemonLines.add,
        onDone: () => daemonClosed = true,
      );
      addTearDown(daemonSub.cancel);
      await pumpEventQueue();

      final DeviceLogReader runReader = await device.getLogReader(app: appPkg);
      expect(identical(daemonReader, runReader), isTrue);
      expect(daemonClosed, isFalse);

      await daemonReader.dispose();
      expect(daemonClosed, isTrue);

      // Scenario B: After dispose(), concurrent getLogReader(app: appPkg) callers share a single live reader.
      final List<DeviceLogReader> concurrent = await Future.wait(<Future<DeviceLogReader>>[
        device.getLogReader(app: appPkg),
        device.getLogReader(app: appPkg),
      ]);
      expect(identical(concurrent[0], concurrent[1]), isTrue);
      var r1Closed = false;
      final StreamSubscription<String> r1Sub = concurrent[0].logLines.listen(
        (_) {},
        onDone: () => r1Closed = true,
      );
      addTearDown(r1Sub.cancel);
      await pumpEventQueue();
      expect(r1Closed, isFalse);

      // Scenario C: Active app-scoped subscriber widens to device-wide (app: null) in place when a second app is requested.
      final secondAppPkg = ExtensionBackedApplicationPackage(id: 'com.example.other_app');
      final DeviceLogReader widened = await device.getLogReader(app: secondAppPkg);
      expect(identical(widened, concurrent[0]), isTrue);
      expect(r1Closed, isFalse);
      await pumpEventQueue();
      expect(startedLogAppIds, <String?>[null, 'com.example.app', null]);

      // Scenario D: Calling getLogReader after connection is already disposed handles synchronous failure without LateInitializationError.
      await widened.dispose();
      await conn.dispose();
      logger.clear();
      final DeviceLogReader postCloseReader = await device.getLogReader(app: appPkg);
      expect((postCloseReader as ExtensionDeviceLogReader).isDisposed, isTrue);
      expect(
        logger.warningText,
        contains('Failed to start log stream for extension device "ext-log-device"'),
      );
    });

    testWithoutContext('handles !supportsInstall no-op semantics, catches RPC and peer-exit exceptions with printError, and propagates host errors', () async {
      void failingEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestDeviceService(
                onResolveApplication: (ExtensionApplicationResolutionContext _) async {
                  throw StateError('Simulated resolve failure');
                },
                onInstallApp: (String _, Uri _, bool _) async {
                  throw StateError('Simulated install failure');
                },
                onIsAppInstalled: (String _, String _) async {
                  throw StateError('Simulated isAppInstalled failure');
                },
                onUninstallApp: (String _, String _) async {
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

      final File bundleFile = fs.file('/build/app.pkg')..createSync(recursive: true);
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
        targetDevice: const TargetDevice(
          category: Category.desktop,
          id: 'ext-device-no-install',
          name: 'No Install Extension Device',
        ),
        toolContext: _createToolContext(fs: fs, logger: logger),
      );
      expect(unsupportedInstallDevice.supportsInstall, isFalse);
      expect(unsupportedInstallDevice.supportsScreenshot, isFalse);
      expect(await unsupportedInstallDevice.isAppInstalled(app), isFalse);
      expect(await unsupportedInstallDevice.installApp(app), isTrue);
      expect(await unsupportedInstallDevice.uninstallApp(app), isTrue);
      expect(logger.errorText, isEmpty);

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
        targetDevice: targetDevice,
        toolContext: _createToolContext(fs: fs, logger: logger),
      );

      expect(await device.resolveApplicationPackage(buildInfo: BuildInfo.debug), isNull);
      expect(
        logger.errorText,
        contains(
          'Failed to resolve application for "ext-device-fail" ("failing_device_extension")',
        ),
      );

      logger.clear();
      expect(await device.isAppInstalled(app), isFalse);
      expect(
        logger.errorText,
        contains(
          'Failed to check if application "com.example.app" is installed on '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      logger.clear();
      expect(await device.installApp(app), isFalse);
      expect(
        logger.errorText,
        contains(
          'Failed to install application "com.example.app" on '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      logger.clear();
      expect(await device.uninstallApp(app), isFalse);
      expect(
        logger.errorText,
        contains(
          'Failed to uninstall application "com.example.app" from '
          '"ext-device-fail" ("failing_device_extension")',
        ),
      );

      // When the extension isolate exits mid-RPC during installApp, both installApp
      // and a subsequent isAppInstalled catch ExtensionConnectionException and log errors.
      void exitingEntryPoint(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestDeviceService(
                onInstallApp: (String _, Uri _, bool _) async {
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
        targetDevice: targetDevice,
        toolContext: _createToolContext(fs: fs, logger: logger),
      );

      logger.clear();
      expect(await exitingDevice.installApp(app), isFalse);
      expect(
        logger.errorText,
        contains(
          'Failed to install application "com.example.app" on '
          '"ext-device-fail" ("exiting_device_extension")',
        ),
      );
      logger.clear();
      expect(await exitingDevice.isAppInstalled(app), isFalse);
      expect(
        logger.errorText,
        contains(
          'Failed to check if application "com.example.app" is installed on '
          '"ext-device-fail" ("exiting_device_extension")',
        ),
      );

      final directErrorDevice = ExtensionBackedDevice(
        buildManager: _createBuildManager(logger: logger),
        connection: conn,
        deviceService: _TestDeviceService(
          onInstallApp: (String _, Uri _, bool _) => Future<void>.error(StateError('Host bug')),
          onIsAppInstalled: (String _, String _) => Future<bool>.error(StateError('Host bug')),
          onUninstallApp: (String _, String _) => Future<void>.error(StateError('Host bug')),
        ),
        targetDevice: targetDevice,
        toolContext: _createToolContext(fs: fs, logger: logger),
      );
      await expectLater(directErrorDevice.isAppInstalled(app), throwsStateError);
      await expectLater(directErrorDevice.installApp(app), throwsStateError);
      await expectLater(directErrorDevice.uninstallApp(app), throwsStateError);
    });
  });
}
