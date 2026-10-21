// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices and managing
/// application execution.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  static const String _getDevicesRpcMethod = 'getDevices';
  static const String _isSupportedForProjectRpcMethod = 'isSupportedForProject';
  static const String _launchAppRpcMethod = 'launchApp';
  static const String _getVmServiceUriRpcMethod = 'getVmServiceUri';
  static const String _stopAppRpcMethod = 'stopApp';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = '$serviceNamespace.$_getDevicesRpcMethod';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod =
      '$serviceNamespace.$_isSupportedForProjectRpcMethod';

  /// RPC method identifier to launch an application on a target device.
  static const String launchAppMethod = '$serviceNamespace.$_launchAppRpcMethod';

  /// RPC method identifier to retrieve the VM service URI for a running application.
  static const String getVmServiceUriMethod = '$serviceNamespace.$_getVmServiceUriRpcMethod';

  /// RPC method identifier to stop a running application on a target device.
  static const String stopAppMethod = '$serviceNamespace.$_stopAppRpcMethod';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the serialized [ExtensionFlutterProject].
  static const String projectParam = 'project';

  /// RPC parameter key for the executable URI to launch.
  static const String executableUriParam = 'executableUri';

  /// RPC parameter key for debugging options.
  static const String debuggingOptionsParam = 'debuggingOptions';

  /// RPC response key for the VM service URI.
  static const String vmServiceUriKey = 'vmServiceUri';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for [project].
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  });

  /// Launches the application at [executableUri] on the device with [deviceId]
  /// using the given [debuggingOptions].
  ///
  /// [executableUri] is guaranteed to be an absolute `file:` URI pointing to
  /// the built application binary or bundle. Returns `true` once the
  /// application process has been started, or `false` if launching failed.
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  });

  /// Returns the VM Service URI for a running application on [deviceId].
  ///
  /// Called by the host tool after [launchApp] succeeds when
  /// [ExtensionDebuggingOptions.debuggingEnabled] is `true`. Implementations
  /// may await VM Service discovery from the running process before returning,
  /// or return `null` if the process exits or VM Service discovery fails.
  Future<Uri?> getVmServiceUri({required String deviceId});

  /// Stops a running application on [deviceId].
  ///
  /// Returns `true` if a running application was stopped, or `false` if no
  /// application was running on [deviceId].
  Future<bool> stopApp({required String deviceId});

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      _getDevicesRpcMethod: _getDevicesRpc,
      _isSupportedForProjectRpcMethod: _isSupportedForProjectRpc,
      _launchAppRpcMethod: _launchAppRpc,
      _getVmServiceUriRpcMethod: _getVmServiceUriRpc,
      _stopAppRpcMethod: _stopAppRpc,
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

  Future<bool> _launchAppRpc(Map<String, Object?> params) async {
    final String deviceId;
    final String executableUriStr;
    final Map<String, Object?> optionsMap;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
      executableUriStr = params.requiredField<String>(executableUriParam);
      optionsMap = params.requiredField<Map<String, Object?>>(debuggingOptionsParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final Uri executableUri = _parseExecutableUri(executableUriStr);
    final ExtensionDebuggingOptions debuggingOptions = _parseDebuggingOptions(optionsMap);
    return launchApp(
      debuggingOptions: debuggingOptions,
      deviceId: deviceId,
      executableUri: executableUri,
    );
  }

  static Uri _parseExecutableUri(String executableUriStr) {
    final Uri? uri = Uri.tryParse(executableUriStr);
    if (uri == null || !uri.isValidFileUri) {
      throw RpcException.invalidParams(
        'Invalid "$executableUriParam" parameter for $launchAppMethod: must be an absolute "file:" URI.',
      );
    }
    return uri;
  }

  static ExtensionDebuggingOptions _parseDebuggingOptions(Map<String, Object?> options) {
    try {
      return ExtensionDebuggingOptions.fromJson(options);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(
        'Invalid "$debuggingOptionsParam" parameter for $launchAppMethod: ${e.message}',
      );
    }
  }

  Future<Map<String, Object?>> _getVmServiceUriRpc(Map<String, Object?> params) async {
    final String deviceId;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    final Uri? uri = await getVmServiceUri(deviceId: deviceId);
    return <String, Object?>{vmServiceUriKey: uri?.toString()};
  }

  Future<bool> _stopAppRpc(Map<String, Object?> params) async {
    final String deviceId;
    try {
      deviceId = params.requiredField<String>(deviceIdParam);
    } on FormatException catch (e) {
      throw RpcException.invalidParams(e.message);
    }
    return stopApp(deviceId: deviceId);
  }
}
