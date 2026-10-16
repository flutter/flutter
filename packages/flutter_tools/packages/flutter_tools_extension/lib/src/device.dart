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

  /// RPC parameter key for the project root URI.
  static const String projectRootParam = 'projectRoot';

  /// RPC parameter key for the executable path to launch.
  static const String executablePathParam = 'executablePath';

  /// RPC parameter key for optional debugging options.
  static const String debuggingOptionsParam = 'debuggingOptions';

  /// RPC response key for the VM service URI.
  static const String vmServiceUriKey = 'vmServiceUri';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for the
  /// Flutter project at [projectRoot].
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot});

  /// Launches the application at [executablePath] on the device with [deviceId].
  Future<bool> launchApp(
    String deviceId,
    String executablePath, {
    Map<String, Object?>? debuggingOptions,
  });

  /// Returns the VM Service URI for a running application on [deviceId], if available.
  Future<String?> getVmServiceUri(String deviceId);

  /// Stops a running application on [deviceId].
  Future<bool> stopApp(String deviceId);

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
    final String deviceId = params[deviceIdParam] as String? ?? '';
    final String projectRootStr = params[projectRootParam] as String? ?? '';
    return isSupportedForProject(deviceId: deviceId, projectRoot: Uri.parse(projectRootStr));
  }

  Future<bool> _launchAppRpc(Map<String, Object?> params) async {
    if (params case {
      deviceIdParam: final String deviceId,
      executablePathParam: final String executablePath,
    }) {
      final Map<String, Object?>? debuggingOptions = switch (params[debuggingOptionsParam]) {
        final Map<String, Object?> options => options,
        null => null,
        _ => throw RpcException.invalidParams(
          'Invalid "$debuggingOptionsParam" parameter for $launchAppMethod.',
        ),
      };
      return launchApp(deviceId, executablePath, debuggingOptions: debuggingOptions);
    }
    throw RpcException.invalidParams('Invalid or missing parameters for $launchAppMethod.');
  }

  Future<Map<String, Object?>> _getVmServiceUriRpc(Map<String, Object?> params) async {
    if (params case {deviceIdParam: final String deviceId}) {
      final String? uri = await getVmServiceUri(deviceId);
      return <String, Object?>{vmServiceUriKey: uri};
    }
    throw RpcException.invalidParams('Invalid or missing parameters for $getVmServiceUriMethod.');
  }

  Future<bool> _stopAppRpc(Map<String, Object?> params) async {
    if (params case {deviceIdParam: final String deviceId}) {
      return stopApp(deviceId);
    }
    throw RpcException.invalidParams('Invalid or missing parameters for $stopAppMethod.');
  }
}
