// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import '../../generic_extension_protocol.dart';

/// Abstract representation of a target device in the extensibility package.
abstract class Device {
  String get id;
  String get name;
  String get category;
  bool get isEmulator;
  String get platform;
  String get buildTarget;

  Future<void> installApp(Uri appBundlePath);
  Future<void> launchApp(Uri appBundlePath, List<String> args);
  Stream<String> getLogReader();
  Future<Uri> getVmServiceUri();
  Future<void> stopApp();
}

/// Abstract interface for forwarding ports from the host to the device.
abstract class DevicePortForwarder {
  List<ForwardedPort> get forwardedPorts;
  Future<ForwardedPort> forward(int devicePort, {int? hostPort});
  Future<void> unforward(ForwardedPort forwardedPort);
  Future<void> dispose();
}

/// Abstract representation of a forwarded port.
abstract base class ForwardedPort {
  ForwardedPort(this.hostPort, this.devicePort);

  final int hostPort;
  final int devicePort;

  Future<void> dispose();
}

/// Abstract representation of the Device Service in the extensibility package.
abstract base class DeviceService extends ToolExtensionService {
  DeviceService({required this.onNotification});

  /// Callback to forward notifications back to the host tool.
  final void Function(String method, Map<String, Object?> params) onNotification;

  @override
  String get namespace => 'device';

  /// The active devices managed by this service.
  final Map<String, Device> _devices = <String, Device>{};
  final Map<String, StreamSubscription<String>> _logSubscriptions =
      <String, StreamSubscription<String>>{};

  /// Discovers and returns the list of available devices.
  Future<List<Device>> discoverDevices();

  /// Launches a specific device emulator.
  Future<void> launchEmulator(String emulatorId);

  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{
      'discoverDevices': _discoverDevicesRpc,
      'installApp': _installAppRpc,
      'launchApp': _launchAppRpc,
      'getVmServiceUri': _getVmServiceUriRpc,
      'stopApp': _stopAppRpc,
    };
  }

  Future<List<Map<String, Object?>>> _discoverDevicesRpc(Map<String, Object?> params) async {
    final List<Device> devices = await discoverDevices();
    for (final StreamSubscription<String> sub in _logSubscriptions.values) {
      await sub.cancel();
    }
    _logSubscriptions.clear();
    _devices.clear();
    final result = <Map<String, Object?>>[];
    for (final device in devices) {
      _devices[device.id] = device;
      _logSubscriptions[device.id] = device.getLogReader().listen((String line) {
        onNotification('device.log', <String, Object?>{'deviceId': device.id, 'message': line});
      });
      result.add(<String, Object?>{
        'id': device.id,
        'name': device.name,
        'category': device.category,
        'isEmulator': device.isEmulator,
        'platform': device.platform,
        'buildTarget': device.buildTarget,
      });
    }
    return result;
  }

  Future<void> _installAppRpc(Map<String, Object?> params) async {
    final id = params['deviceId']! as String;
    final path = params['appBundlePath']! as String;
    final Device? device = _devices[id];
    if (device == null) {
      throw StateError('Device $id not found.');
    }
    await device.installApp(Uri.file(path));
  }

  Future<void> _launchAppRpc(Map<String, Object?> params) async {
    final id = params['deviceId']! as String;
    final path = params['appBundlePath']! as String;
    final List<String> args = (params['args'] as List?)?.cast<String>() ?? const <String>[];
    final Device? device = _devices[id];
    if (device == null) {
      throw StateError('Device $id not found.');
    }

    await device.launchApp(Uri.file(path), args);
  }

  Future<String> _getVmServiceUriRpc(Map<String, Object?> params) async {
    final id = params['deviceId']! as String;
    final Device? device = _devices[id];
    if (device == null) {
      throw StateError('Device $id not found.');
    }
    final Uri uri = await device.getVmServiceUri();
    return uri.toString();
  }

  Future<void> _stopAppRpc(Map<String, Object?> params) async {
    final id = params['deviceId']! as String;
    final Device? device = _devices[id];
    if (device == null) {
      throw StateError('Device $id not found.');
    }
    await device.stopApp();
  }

  @override
  Future<void> shutdown() async {
    for (final StreamSubscription<String> sub in _logSubscriptions.values) {
      await sub.cancel();
    }
    _logSubscriptions.clear();
    _devices.clear();
  }
}
