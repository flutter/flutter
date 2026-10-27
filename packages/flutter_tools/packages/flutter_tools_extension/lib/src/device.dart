// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices and streaming
/// device logs.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  static const String _getDevicesRpcMethod = 'getDevices';
  static const String _isSupportedForProjectRpcMethod = 'isSupportedForProject';
  static const String _startLogStreamRpcMethod = 'startLogStream';
  static const String _stopLogStreamRpcMethod = 'stopLogStream';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = '$serviceNamespace.$_getDevicesRpcMethod';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod =
      '$serviceNamespace.$_isSupportedForProjectRpcMethod';

  /// RPC method identifier to start streaming log output for a target device.
  static const String startLogStreamMethod = '$serviceNamespace.$_startLogStreamRpcMethod';

  /// RPC method identifier to stop streaming log output for a target device.
  static const String stopLogStreamMethod = '$serviceNamespace.$_stopLogStreamRpcMethod';

  /// JSON-RPC 2.0 notification method emitted by the extension for each device
  /// log line.
  static const String logEntryNotificationMethod = '$serviceNamespace.logEntry';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the serialized [ExtensionFlutterProject].
  static const String projectParam = 'project';

  /// JSON key for the log line text in [logEntryNotificationMethod]
  /// notifications.
  static const String lineKey = 'line';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for [project].
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  });

  /// Starts streaming log output for the device identified by [deviceId].
  ///
  /// Invoked by the host tool when a log consumer (such as `flutter logs` or
  /// `flutter run`) begins reading logs from [deviceId]. Implementations should
  /// return once log streaming has been initiated rather than awaiting the
  /// lifetime of the stream, and forward each log line (without a trailing
  /// newline) to the host by calling [emitLogLine].
  Future<void> startLogStream({required String deviceId}) async {}

  /// Stops streaming log output for the device identified by [deviceId].
  ///
  /// Invoked by the host tool when the device log reader is disposed.
  Future<void> stopLogStream({required String deviceId}) async {}

  /// Sends a [logEntryNotificationMethod] JSON-RPC notification containing a
  /// single log [line] (excluding any trailing newline) from [deviceId] to the
  /// host tool.
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
    final String deviceId;
    final ExtensionFlutterProject project;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
      final Map<String, Object?> projectMap = params.requiredField<Map<String, Object?>>(
        projectParam,
      );
      project = ExtensionFlutterProject.fromJson(projectMap);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return isSupportedForProject(deviceId: deviceId, project: project);
  }

  String _parseDeviceId(Map<String, Object?> params) {
    final String deviceId;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    if (deviceId.isEmpty) {
      throw RpcException.invalidParams('Parameter "$deviceIdParam" must not be empty.');
    }
    return deviceId;
  }

  Future<Object?> _startLogStreamRpc(Map<String, Object?> params) async {
    await startLogStream(deviceId: _parseDeviceId(params));
    return null;
  }

  Future<Object?> _stopLogStreamRpc(Map<String, Object?> params) async {
    await stopLogStream(deviceId: _parseDeviceId(params));
    return null;
  }
}
