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

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{'getDevices': _getDevicesRpc};
  }

  @override
  Future<void> shutdown() async {}

  Future<List<Map<String, Object?>>> _getDevicesRpc(Map<String, Object?> params) async {
    final List<TargetDevice> devices = await getDevices();
    return devices.map((TargetDevice device) => device.toMap()).toList();
  }
}
