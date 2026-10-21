// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'protocol_base/service.dart';

/// Extension service interface for retrieving target devices and emulators.
abstract base class DeviceService extends ToolExtensionService {
  /// Service namespace identifier for device services.
  static const String serviceNamespace = 'device';

  /// RPC method identifier to query contributed target devices.
  static const String getDevicesMethod = 'device.getDevices';

  /// RPC method identifier to query whether a target device is supported for a project.
  static const String isSupportedForProjectMethod = 'device.isSupportedForProject';

  /// RPC method identifier to query contributed target emulators.
  static const String getEmulatorsMethod = 'device.getEmulators';

  /// RPC method identifier to launch a contributed target emulator.
  static const String launchEmulatorMethod = 'device.launchEmulator';

  /// RPC parameter key for the target device ID.
  static const String deviceIdParam = 'deviceId';

  /// RPC parameter key for the project root URI.
  static const String projectRootParam = 'projectRoot';

  /// RPC parameter key for the target emulator ID.
  static const String emulatorIdParam = 'emulatorId';

  /// RPC parameter key for whether to cold boot the target emulator.
  static const String coldBootParam = 'coldBoot';

  @override
  String get namespace => serviceNamespace;

  /// Returns the target devices contributed by this extension.
  Future<List<TargetDevice>> getDevices();

  /// Returns whether the target device with [deviceId] is supported for the
  /// Flutter project at [projectRoot].
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot});

  /// Returns the target emulators contributed by this extension.
  ///
  /// Defaults to returning an empty list for extensions that only provide
  /// physical or stationary target devices.
  Future<List<TargetEmulator>> getEmulators() async => const <TargetEmulator>[];

  /// Launches the target emulator with [emulatorId].
  ///
  /// When [coldBoot] is `true`, the emulator should boot from a clean state
  /// rather than restoring a snapshot. Returns `true` if the emulator launch
  /// succeeded, or `false` otherwise.
  Future<bool> launchEmulator({required String emulatorId, bool coldBoot = false}) async => false;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getDevices': _getDevicesRpc,
      'isSupportedForProject': _isSupportedForProjectRpc,
      'getEmulators': _getEmulatorsRpc,
      'launchEmulator': _launchEmulatorRpc,
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

  Future<List<Map<String, Object?>>> _getEmulatorsRpc(Map<String, Object?> _) async {
    final List<TargetEmulator> emulators = await getEmulators();
    return emulators.map((TargetEmulator e) => e.toMap()).toList();
  }

  Future<bool> _launchEmulatorRpc(Map<String, Object?> params) async {
    final String emulatorId;
    final bool coldBoot;
    try {
      emulatorId = params.requiredField<String>(emulatorIdParam);
      if (emulatorId.isEmpty) {
        throw const FormatException('Invalid "$emulatorIdParam": must not be empty.');
      }
      coldBoot = params.optionalField<bool>(coldBootParam, defaultValue: false);
    } on FormatException catch (e) {
      throw json_rpc.RpcException.invalidParams(e.message);
    }
    return launchEmulator(emulatorId: emulatorId, coldBoot: coldBoot);
  }
}
