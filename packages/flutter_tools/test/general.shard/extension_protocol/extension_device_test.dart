// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart' hide Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../src/common.dart';

const _primaryDeviceId = 'custom_device_1';
const _secondaryDeviceId = 'custom_device_2';
const _testAppId = 'com.example.custom_app';
const _startEventType = 'start';
const _stopEventType = 'stop';
const _eventTypeKey = 'type';

final class _StreamingTestDeviceService extends DeviceService {
  _StreamingTestDeviceService({
    required this.eventSendPort,
    this.linesByDevice = const <String, List<String>>{},
    this.throwOnStart = false,
  });

  final SendPort eventSendPort;
  final Map<String, List<String>> linesByDevice;
  final bool throwOnStart;

  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        id: _primaryDeviceId,
        name: 'Primary Extension Device',
        category: Category.desktop,
      ),
      TargetDevice(
        id: _secondaryDeviceId,
        name: 'Secondary Extension Device',
        category: Category.desktop,
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async => true;

  @override
  Future<void> startLogStream({required String deviceId, String? appId}) async {
    if (throwOnStart) {
      throw StateError('Simulated startLogStream failure');
    }
    eventSendPort.send(<String, Object?>{
      _eventTypeKey: _startEventType,
      DeviceService.deviceIdParam: deviceId,
      DeviceService.appIdParam: appId,
    });
    for (final MapEntry(key: String sourceDeviceId, value: List<String> lines)
        in linesByDevice.entries) {
      for (final line in lines) {
        emitLogLine(deviceId: sourceDeviceId, line: line);
      }
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

final class _ReservedLogEntryService extends ToolExtensionService {
  @override
  String get namespace => DeviceService.serviceNamespace;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{'logEntry': (Map<String, Object?> _) => null};
  }
}

final class _FakeApplicationPackage extends ApplicationPackage {
  _FakeApplicationPackage(String id) : super(id: id);

  @override
  String get name => id;
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
          .cast<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> map) => map.cast<String, Object?>())
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
        connection: conn,
        deviceService: client,
        logger: logger,
        targetDevice: targetDevices.first,
      );
      final app = _FakeApplicationPackage(_testAppId);

      final Future<Map<String, Object?>> startEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _startEventType,
      );
      final DeviceLogReader reader = await device.getLogReader(app: app);
      expect(identical(await device.getLogReader(app: app), reader), isTrue);

      final Future<List<String>> receivedLinesFuture = reader.logLines.take(2).toList();

      final List<String> receivedLines = await receivedLinesFuture;
      expect(
        receivedLines,
        equals(<String>['Booting application...', 'Flutter run key commands.']),
      );

      final Map<String, Object?> startEvent = await startEventFuture;
      expect(startEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
      expect(startEvent[DeviceService.appIdParam], equals(_testAppId));

      final Future<Map<String, Object?>> stopEventFuture = events.firstWhere(
        (Map<String, Object?> event) => event[_eventTypeKey] == _stopEventType,
      );
      await device.dispose();

      final Map<String, Object?> stopEvent = await stopEventFuture;
      expect(stopEvent[DeviceService.deviceIdParam], equals(_primaryDeviceId));
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
          connection: conn,
          deviceService: client,
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
            .cast<Map<Object?, Object?>>()
            .map((Map<Object?, Object?> map) => map.cast<String, Object?>())
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

    testWithoutContext('ExtensionDeviceLogReader logs warning when startLogStream fails', () async {
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

      expect(
        logger.warningText,
        contains('Failed to start log stream for extension device "$_primaryDeviceId"'),
      );
    });

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

      await expectLater(
        conn.sendRequest(
          DeviceService.startLogStreamMethod,
          params: const <String, Object?>{
            DeviceService.deviceIdParam: _primaryDeviceId,
            DeviceService.appIdParam: 123,
          },
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (json_rpc.RpcException e) => e.code,
            'code',
            error_code.INVALID_PARAMS,
          ),
        ),
      );
    });

    testWithoutContext('ToolExtensionEntryPoint.run rejects registering reserved device.logEntry notification method', () async {
      final receivePort = ReceivePort();
      addTearDown(receivePort.close);

      await expectLater(
        ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
          _ReservedLogEntryService(),
        ]),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Reserved RPC method registered: "device.logEntry"'),
          ),
        ),
      );
    });
  });
}
