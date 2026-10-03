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

  /// RPC parameter key for the serialized [ExtensionFlutterProject].
  static const String projectParam = 'project';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for [project].
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  });

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
    if (params case {
      deviceIdParam: final String deviceId,
      projectParam: final Map<String, Object?> projectMap,
    }) {
      return isSupportedForProject(
        deviceId: deviceId,
        project: ExtensionFlutterProject.fromJson(projectMap),
      );
    }
    return false;
  }
}
