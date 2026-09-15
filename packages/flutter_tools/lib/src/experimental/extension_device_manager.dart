// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../application_package.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../project.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// A host-side [DeviceService] client adapter delegating RPC queries to an [ExtensionConnection].
final class ExtensionDeviceClient extends DeviceService {
  /// Creates an [ExtensionDeviceClient] wrapping the host [connection].
  ExtensionDeviceClient(this.connection, {required Logger logger}) : _logger = logger;

  /// The active extension isolate connection.
  final ExtensionConnection connection;
  final Logger _logger;

  @override
  Future<List<TargetDevice>> getDevices() async {
    _logger.printTrace(
      'ExtensionDeviceClient fetching devices via RPC ("${DeviceService.getDevicesMethod}")...',
    );
    try {
      final Object? rawResult = await connection
          .sendRequest(DeviceService.getDevicesMethod)
          .timeout(const Duration(seconds: 5));
      final List<TargetDevice> devices = TargetDevice.listFromJson(rawResult);
      _logger.printTrace('ExtensionDeviceClient received ${devices.length} device(s) via RPC.');
      return devices;
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to get devices: $err\n$stack');
    }
    return const <TargetDevice>[];
  }
}

/// A host-side [DeviceDiscovery] mechanism that discovers devices registered by active extensions.
class ExtensionDeviceDiscovery extends PollingDeviceDiscovery {
  /// Creates an [ExtensionDeviceDiscovery] instance.
  ExtensionDeviceDiscovery({required ExtensionManager extensionManager, required Logger logger})
    : _extensionManager = extensionManager,
      _logger = logger,
      super('tool_extension');

  final ExtensionManager _extensionManager;
  final Logger _logger;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  List<String> get wellKnownIds => const <String>[];

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    _logger.printTrace('ExtensionDeviceDiscovery polling active tool extension devices...');
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      _logger.printTrace('ExtensionDeviceDiscovery found 0 active device extensions.');
      return <Device>[];
    }

    final List<List<Device>> devicesPerService = await Future.wait(
      deviceServices.map((DeviceService service) async {
        try {
          final List<TargetDevice> devices = await service.getDevices();
          final ExtensionConnection? connection = switch (service) {
            ExtensionDeviceClient(:final ExtensionConnection connection) => connection,
            _ => null,
          };
          return devices
              .map(
                (TargetDevice targetDevice) => ExtensionBackedDevice(
                  logger: _logger,
                  targetDevice: targetDevice,
                  connection: connection,
                ),
              )
              .toList();
        } on Object catch (e, st) {
          _logger.printTrace('Error querying device extension service: $e\n$st');
          return <Device>[];
        }
      }),
    );

    final targetDevices = <Device>[for (final deviceList in devicesPerService) ...deviceList];

    _logger.printTrace(
      'ExtensionDeviceDiscovery retrieved ${targetDevices.length} target device(s).',
    );
    return targetDevices;
  }

  @override
  Future<List<String>> getDiagnostics() async => <String>[];
}

/// A host-side [Device] wrapper representing a target device backed by a tool extension.
class ExtensionBackedDevice extends Device {
  /// Creates an [ExtensionBackedDevice] wrapping a [TargetDevice].
  ExtensionBackedDevice({
    required super.logger,
    required TargetDevice targetDevice,
    this.connection,
  }) : _targetDevice = targetDevice,
       super(
         targetDevice.id,
         category: Category.fromString(targetDevice.category) ?? Category.desktop,
         platformType: PlatformType.fromString(targetDevice.platformType) ?? PlatformType.custom,
         ephemeral: targetDevice.ephemeral,
       );

  final TargetDevice _targetDevice;
  final ExtensionConnection? connection;

  @override
  String get name => _targetDevice.name;

  @override
  Future<bool> isSupported() async => _targetDevice.isSupported;

  @override
  bool isSupportedForProject(FlutterProject project) => _targetDevice.isSupportedForProject;

  @override
  Future<CpuArch> get cpuArch async => CpuArch.unknown;

  @override
  Future<String> get sdkNameAndVersion async =>
      _targetDevice.sdkNameAndVersion ?? 'Tool Extension Device';

  @override
  Future<String> get targetPlatformDisplayName async => _targetDevice.platformType;

  @override
  Future<TargetPlatform> get targetPlatform async {
    final String? platformName = _targetDevice.targetPlatform;
    if (platformName != null) {
      try {
        return TargetPlatform.fromName(platformName);
      } on Object catch (_) {
        // Fall through if unrecognized target platform name supplied.
      }
    }
    try {
      return TargetPlatform.fromName(_targetDevice.platformType);
    } on Object catch (_) {
      return TargetPlatform.unsupported;
    }
  }

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  DevicePortForwarder? get portForwarder => null;

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) =>
      NoOpDeviceLogReader(name);

  @override
  void clearLogs() {}

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    DebuggingOptions? debuggingOptions,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async => true;

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;
}
