// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices and streaming
/// device logs.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = 'device.getDevices';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod = 'device.isSupportedForProject';

  /// RPC method identifier to start streaming log output for a target device.
  static const startLogStreamMethod = 'device.startLogStream';

  /// RPC method identifier to stop streaming log output for a target device.
  static const stopLogStreamMethod = 'device.stopLogStream';

  /// JSON-RPC 2.0 notification method emitted by the extension for each device
  /// log line.
  static const logEntryNotificationMethod = 'device.logEntry';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the project root URI.
  static const String projectRootParam = 'projectRoot';

  /// RPC parameter key for the optional application identifier when starting a
  /// device log stream.
  static const appIdParam = 'appId';

  /// JSON key for the log line text in [logEntryNotificationMethod]
  /// notifications.
  static const lineKey = 'line';

  static const _getDevicesRpcMethod = 'getDevices';
  static const _isSupportedForProjectRpcMethod = 'isSupportedForProject';
  static const _startLogStreamRpcMethod = 'startLogStream';
  static const _stopLogStreamRpcMethod = 'stopLogStream';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for the
  /// Flutter project at [projectRoot].
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot});

  /// Starts streaming log output for the device identified by [deviceId].
  ///
  /// If [appId] is provided, the extension may filter log output to the
  /// specified application. Extension implementations should forward each log
  /// line to the host by calling [emitLogLine].
  Future<void> startLogStream({required String deviceId, String? appId}) async {}

  /// Stops streaming log output for the device identified by [deviceId].
  Future<void> stopLogStream({required String deviceId}) async {}

  /// Sends a [logEntryNotificationMethod] JSON-RPC notification containing a
  /// single log [line] from [deviceId] to the host tool.
  void emitLogLine({required String deviceId, required String line}) {
    sendNotification(logEntryNotificationMethod, <String, Object?>{
      deviceIdParam: deviceId,
      lineKey: line,
    });
  }

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getDevicesRpcMethod: _getDevicesRpc,
      _isSupportedForProjectRpcMethod: _isSupportedForProjectRpc,
      _startLogStreamRpcMethod: _startLogStreamRpc,
      _stopLogStreamRpcMethod: _stopLogStreamRpc,
    };
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getDevicesRpc(Map<String, Object?> _) async {
    final List<TargetDevice> devices = await getDevices();
    return devices.map((TargetDevice device) => device.toMap()).toList();
  }

  Future<bool> _isSupportedForProjectRpc(Map<String, Object?> params) async {
    final String deviceId = params[deviceIdParam] as String? ?? '';
    final String projectRootStr = params[projectRootParam] as String? ?? '';
    return isSupportedForProject(deviceId: deviceId, projectRoot: Uri.parse(projectRootStr));
  }

  Future<Object?> _startLogStreamRpc(Map<String, Object?> params) async {
    final String deviceId;
    final String? appId;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
      appId = params.nullableField<String>(appIdParam);
    } on FormatException catch (e) {
      throw json_rpc.RpcException.invalidParams(e.message);
    }
    if (deviceId.isEmpty) {
      throw json_rpc.RpcException.invalidParams('Parameter "$deviceIdParam" must not be empty.');
    }
    await startLogStream(deviceId: deviceId, appId: appId);
    return null;
  }

  Future<Object?> _stopLogStreamRpc(Map<String, Object?> params) async {
    final String deviceId;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
    } on FormatException catch (e) {
      throw json_rpc.RpcException.invalidParams(e.message);
    }
    if (deviceId.isEmpty) {
      throw json_rpc.RpcException.invalidParams('Parameter "$deviceIdParam" must not be empty.');
    }
    await stopLogStream(deviceId: deviceId);
    return null;
  }
}
