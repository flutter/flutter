// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = 'device.getDevices';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod = 'device.isSupportedForProject';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the project root URI.
  static const String projectRootParam = 'projectRoot';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for the
  /// Flutter project at [projectRoot].
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot});

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getDevices': _getDevicesRpc,
      'isSupportedForProject': _isSupportedForProjectRpc,
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
}
