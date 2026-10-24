// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart' hide Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../emulator.dart';
import '../project.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// A host-side [DeviceService] client adapter delegating RPC queries to an [ExtensionConnection].
final class ExtensionDeviceClient extends DeviceService {
  /// Creates an [ExtensionDeviceClient] wrapping the host [connection].
  ExtensionDeviceClient(this.connection, {required this._logger});

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

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient checking project support for "$deviceId" via RPC '
      '("${DeviceService.isSupportedForProjectMethod}")...',
    );
    try {
      final Object? rawResult = await connection
          .sendRequest(
            DeviceService.isSupportedForProjectMethod,
            params: <String, Object?>{
              DeviceService.deviceIdParam: deviceId,
              DeviceService.projectParam: project.toMap(),
            },
          )
          .timeout(const Duration(seconds: 5));
      if (rawResult case final bool supported) {
        return supported;
      }
    } on Object catch (err, stack) {
      _logger.printTrace(
        'ExtensionDeviceClient failed to check project support for "$deviceId": $err\n$stack',
      );
    }
    return false;
  }

  @override
  Future<List<TargetEmulator>> getEmulators() async {
    _logger.printTrace(
      'ExtensionDeviceClient fetching emulators via RPC ("${DeviceService.getEmulatorsMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(DeviceService.getEmulatorsMethod);
    final List<TargetEmulator> emulators = TargetEmulator.listFromJson(rawResult);
    _logger.printTrace('ExtensionDeviceClient received ${emulators.length} emulator(s) via RPC.');
    return emulators;
  }

  @override
  Future<bool> launchEmulator({required String emulatorId, bool coldBoot = false}) async {
    _logger.printTrace(
      'ExtensionDeviceClient launching emulator "$emulatorId" (coldBoot: $coldBoot) via RPC '
      '("${DeviceService.launchEmulatorMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.launchEmulatorMethod,
        params: <String, Object?>{
          DeviceService.emulatorIdParam: emulatorId,
          DeviceService.coldBootParam: coldBoot,
        },
      );
      if (rawResult case final bool launched) {
        return launched;
      }
    } on Object catch (err, stack) {
      _logger.printTrace(
        'ExtensionDeviceClient failed to launch emulator "$emulatorId": $err\n$stack',
      );
    }
    return false;
  }
}

/// A host-side [DeviceDiscovery] mechanism that discovers devices registered by active extensions.
class ExtensionDevices extends PollingDeviceDiscovery {
  /// Creates an [ExtensionDevices] instance.
  ExtensionDevices({required this._extensionManager, required this._logger})
    : super('tool_extension');

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
    _logger.printTrace('ExtensionDevices polling active tool extension devices...');
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      _logger.printTrace('ExtensionDevices found 0 active device extensions.');
      return <Device>[];
    }

    final List<List<Device>> devicesPerService = await Future.wait(
      deviceServices.whereType<ExtensionDeviceClient>().map((ExtensionDeviceClient service) async {
        try {
          final List<TargetDevice> devices = await service.getDevices();
          return devices
              .map(
                (TargetDevice targetDevice) => ExtensionBackedDevice(
                  connection: service.connection,
                  deviceService: service,
                  logger: _logger,
                  targetDevice: targetDevice,
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

    _logger.printTrace('ExtensionDevices retrieved ${targetDevices.length} target device(s).');
    return targetDevices;
  }

  @override
  Future<List<String>> getDiagnostics() async => <String>[];
}

/// A host-side [Device] wrapper representing a target device backed by a tool extension.
class ExtensionBackedDevice extends Device {
  /// Creates an [ExtensionBackedDevice] wrapping a [TargetDevice].
  ExtensionBackedDevice({
    required this.connection,
    required this._deviceService,
    required super.logger,
    required TargetDevice targetDevice,
  }) : _targetDevice = targetDevice,
       super(
         targetDevice.id,
         category: targetDevice.category,
         platformType: PlatformType.custom,
         ephemeral: targetDevice.ephemeral,
       );

  final DeviceService _deviceService;
  final TargetDevice _targetDevice;
  final ExtensionConnection connection;

  @override
  String get name => _targetDevice.name;

  @override
  Future<bool> isSupported() async => _targetDevice.isSupported;

  @override
  Future<bool> isSupportedForProject(FlutterProject flutterProject) => _deviceService
      .isSupportedForProject(deviceId: id, project: flutterProject.toExtensionProject());

  @override
  Future<CpuArch> get cpuArch async => CpuArch.unknown;

  @override
  Future<String> get sdkNameAndVersion async =>
      _targetDevice.sdkNameAndVersion ?? 'Tool Extension Device';

  @override
  Future<String> get targetPlatformDisplayName async => _targetDevice.targetPlatform ?? 'custom';

  @override
  Future<TargetPlatform> get targetPlatform async {
    final String? platformName = _targetDevice.targetPlatform;
    if (platformName != null) {
      try {
        return TargetPlatform.fromName(platformName);
      } on Object {
        // Fall through if unrecognized target platform name supplied.
      }
    }
    return TargetPlatform.unsupported;
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

/// A host-side [Emulator] wrapper representing a target emulator backed by a tool extension.
@immutable
class ExtensionEmulator extends Emulator {
  /// Creates an [ExtensionEmulator] wrapping a [TargetEmulator].
  ExtensionEmulator({
    required this._deviceService,
    required this._logger,
    required TargetEmulator targetEmulator,
  }) : _targetEmulator = targetEmulator,
       super(targetEmulator.id, true);

  final DeviceService _deviceService;
  final Logger _logger;
  final TargetEmulator _targetEmulator;

  @override
  String get name => _targetEmulator.name;

  @override
  String? get manufacturer => _targetEmulator.manufacturer;

  @override
  Category get category => _targetEmulator.category ?? Category.other;

  @override
  PlatformType get platformType => PlatformType.custom;

  @override
  Future<void> launch({bool coldBoot = false}) async {
    var launched = false;
    try {
      launched = await _deviceService.launchEmulator(emulatorId: id, coldBoot: coldBoot);
    } on Object catch (err, stack) {
      _logger.printTrace('Error launching extension emulator "$id": $err\n$stack');
    }
    if (!launched) {
      _logger.printError('Failed to launch emulator "$id".');
    }
  }
}

/// A host-side [EmulatorDiscovery] mechanism that discovers emulators registered by active extensions.
class ExtensionEmulators extends EmulatorDiscovery {
  ExtensionEmulators({required this._extensionManager, required this._logger});

  final ExtensionManager _extensionManager;
  final Logger _logger;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  bool get canLaunchAnything => true;

  @override
  Future<List<Emulator>> get emulators async {
    _logger.printTrace('ExtensionEmulators querying active tool extension emulators...');
    await _extensionManager.ensureInitialized();
    final List<DeviceService> deviceServices = _extensionManager.deviceExtensions;
    if (deviceServices.isEmpty) {
      _logger.printTrace('ExtensionEmulators found 0 active device extensions.');
      return <Emulator>[];
    }

    final List<List<Emulator>> emulatorsPerService = await Future.wait(
      deviceServices.map((DeviceService service) async {
        try {
          final List<TargetEmulator> emulators = await service.getEmulators();
          return <Emulator>[
            for (final TargetEmulator targetEmulator in emulators)
              ExtensionEmulator(
                deviceService: service,
                logger: _logger,
                targetEmulator: targetEmulator,
              ),
          ];
        } on Object catch (e, st) {
          final String extensionDescription = switch (service) {
            ExtensionDeviceClient(:final ExtensionConnection connection) =>
              'tool extension "${connection.extensionName}"',
            _ => 'tool extension',
          };
          _logger.printWarning('Failed to query emulators from $extensionDescription: $e');
          _logger.printTrace('$st');
          return const <Emulator>[];
        }
      }),
    );

    final targetEmulators = <Emulator>[
      for (final List<Emulator> emulatorList in emulatorsPerService) ...emulatorList,
    ];

    _logger.printTrace('ExtensionEmulators retrieved ${targetEmulators.length} emulator(s).');
    return targetEmulators;
  }
}
