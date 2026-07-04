// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';

import '../../generic_extension_protocol.dart';

/// Abstract representation of a target device in the extensibility package.
abstract class Device {
  String get id;
  String get name;
  String get category;
  bool get isEmulator;
  String get platform;
  String get buildTarget;

  static List<Map<String, Object?>> listFromJson(Object? rpcResult) => <Map<String, Object?>>[
    if (rpcResult case final List<Object?> l)
      for (final item in l)
        if (item case final Map<Object?, Object?> m) m.cast<String, Object?>(),
  ];

  Future<bool> isSupported() async => true;
  bool isRunnable() => true;
  bool isSupportedForProject(Uri projectRoot) => true;

  Future<void> installApp(Uri appBundlePath);
  Future<void> launchApp(Uri appBundlePath, List<String> args);
  Stream<String> getLogReader();
  Future<Uri> getVmServiceUri();
  Future<void> stopApp();
}

/// Standard device category string constants.
abstract final class DeviceCategory {
  static const String desktop = 'desktop';
  static const String mobile = 'mobile';
  static const String web = 'web';
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

/// Helper utility for launching a local executable process and extracting its VM service URI.
abstract final class LocalDeviceLaunchHelper {
  static final RegExp _vmServiceRegExp = RegExp(
    r'The Dart VM service is listening on ((?:http|ws)://[a-zA-Z0-9.:\[\]]+/[^/]+/)',
  );

  /// Extracts the VM service URI from a log line, if present.
  static Uri? parseVmServiceUri(String line) {
    final Match? match = _vmServiceRegExp.firstMatch(line);
    if (match != null) {
      final String? uriString = match.group(1);
      if (uriString != null) {
        return Uri.tryParse(uriString);
      }
    }
    return null;
  }

  /// Launches [command] using [processManager], pipes stdout/stderr to [logController],
  /// and completes [vmServiceUriCompleter] when the VM service URI is printed or the process exits early.
  /// Returns the spawned [Process].
  static Future<Process> launchAndMonitorProcess({
    required List<String> command,
    required ProcessManager processManager,
    required StreamController<String> logController,
    required Completer<Uri> vmServiceUriCompleter,
  }) async {
    final Process process = await processManager.start(command);

    unawaited(
      process.exitCode.then((int exitCode) {
        if (!vmServiceUriCompleter.isCompleted) {
          vmServiceUriCompleter.completeError(
            StateError(
              'The process exited early with exit code $exitCode before VM Service URI was printed.',
            ),
          );
        }
      }),
    );

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      logController.add(line);
      final Uri? uri = parseVmServiceUri(line);
      if (uri != null && !vmServiceUriCompleter.isCompleted) {
        vmServiceUriCompleter.complete(uri);
      }
    });

    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      logController.add('ERROR: $line');
    });

    return process;
  }
}

/// Helper for extracting Dart VM Service URIs from an already started process.
class ProcessLaunchHelper {
  ProcessLaunchHelper({required this.onLogLine, required this.process});

  final void Function(String line) onLogLine;
  final Process process;

  /// Streams stdout and stderr logs from [process] and completes with the VM Service URI.
  Future<Uri> extractVmServiceUri() {
    final completer = Completer<Uri>();

    unawaited(
      process.exitCode.then((int exitCode) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(
              'The process exited early with exit code $exitCode before VM Service URI was printed.',
            ),
          );
        }
      }),
    );

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      onLogLine(line);
      final Uri? uri = LocalDeviceLaunchHelper.parseVmServiceUri(line);
      if (uri != null && !completer.isCompleted) {
        completer.complete(uri);
      }
    });

    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
      onLogLine('ERROR: $line');
    });

    return completer.future;
  }
}

/// Abstract representation of the Device Service in the extensibility package.
abstract base class DeviceService extends ToolExtensionService {
  DeviceService({required this.onNotification});

  static const String serviceNamespace = 'device';
  static const String discoverDevicesMethod = 'device.discoverDevices';
  static const String installAppMethod = 'device.installApp';
  static const String launchAppMethod = 'device.launchApp';
  static const String getVmServiceUriMethod = 'device.getVmServiceUri';
  static const String stopAppMethod = 'device.stopApp';
  static const String logNotificationMethod = 'device.log';

  /// Callback to forward notifications back to the host tool.
  final void Function(String method, Map<String, Object?> params) onNotification;

  @override
  String get namespace => serviceNamespace;

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

  Device _getDevice(Map<String, Object?> params) {
    final id = params['deviceId']! as String;
    final Device? device = _devices[id];
    if (device == null) {
      throw StateError('Device $id not found.');
    }
    return device;
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
        onNotification(logNotificationMethod, <String, Object?>{
          'deviceId': device.id,
          'message': line,
        });
      });
      result.add(<String, Object?>{
        'id': device.id,
        'name': device.name,
        'category': device.category,
        'isEmulator': device.isEmulator,
        'platform': device.platform,
        'buildTarget': device.buildTarget,
        'isSupported': await device.isSupported(),
        'isRunnable': device.isRunnable(),
      });
    }
    return result;
  }

  Future<void> _installAppRpc(Map<String, Object?> params) async {
    final Device device = _getDevice(params);
    final path = params['appBundlePath']! as String;
    await device.installApp(Uri.file(path));
  }

  Future<void> _launchAppRpc(Map<String, Object?> params) async {
    final Device device = _getDevice(params);
    final path = params['appBundlePath']! as String;
    final List<String> args = (params['args'] as List?)?.cast<String>() ?? const <String>[];
    await device.launchApp(Uri.file(path), args);
  }

  Future<String> _getVmServiceUriRpc(Map<String, Object?> params) async {
    final Device device = _getDevice(params);
    final Uri uri = await device.getVmServiceUri();
    return uri.toString();
  }

  Future<void> _stopAppRpc(Map<String, Object?> params) async {
    final Device device = _getDevice(params);
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
