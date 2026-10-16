// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Category;
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../application_package.dart';
import '../base/file_system.dart';
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
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot}) async {
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
              DeviceService.projectRootParam: projectRoot.toString(),
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
  Future<bool> launchApp(
    String deviceId,
    String executablePath, {
    Map<String, Object?>? debuggingOptions,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient launching app "$executablePath" on "$deviceId" via RPC '
      '("${DeviceService.launchAppMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.launchAppMethod,
        params: <String, Object?>{
          DeviceService.deviceIdParam: deviceId,
          DeviceService.executablePathParam: executablePath,
          DeviceService.debuggingOptionsParam: ?debuggingOptions,
        },
        timeout: const Duration(seconds: 30),
      );
      if (rawResult case final bool launched) {
        return launched;
      }
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to launch app: $err\n$stack');
    }
    return false;
  }

  @override
  Future<String?> getVmServiceUri(String deviceId) async {
    _logger.printTrace(
      'ExtensionDeviceClient getting VM Service URI for "$deviceId" via RPC '
      '("${DeviceService.getVmServiceUriMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.getVmServiceUriMethod,
        params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
        timeout: const Duration(seconds: 15),
      );
      if (rawResult case {DeviceService.vmServiceUriKey: final String uri}) {
        return uri;
      }
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to get VM Service URI: $err\n$stack');
    }
    return null;
  }

  @override
  Future<bool> stopApp(String deviceId) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping app on "$deviceId" via RPC '
      '("${DeviceService.stopAppMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.stopAppMethod,
        params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
      );
      if (rawResult case final bool stopped) {
        return stopped;
      }
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to stop app: $err\n$stack');
    }
    return false;
  }
}

/// A host-side [DeviceDiscovery] mechanism that discovers devices registered by active extensions.
class ExtensionDevices extends PollingDeviceDiscovery {
  /// Creates an [ExtensionDevices] instance.
  ExtensionDevices({
    required this._extensionManager,
    required this._fileSystem,
    required this._logger,
  }) : super('tool_extension');

  final ExtensionManager _extensionManager;
  final FileSystem _fileSystem;
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
                  fileSystem: _fileSystem,
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
    required this._fileSystem,
    required super.logger,
    required TargetDevice targetDevice,
  }) : _logger = logger,
       _targetDevice = targetDevice,
       super(
         targetDevice.id,
         category: targetDevice.category,
         platformType: PlatformType.custom,
         ephemeral: targetDevice.ephemeral,
       );

  final DeviceService _deviceService;
  final FileSystem _fileSystem;
  final Logger _logger;
  final TargetDevice _targetDevice;
  final ExtensionConnection connection;

  @override
  String get name => _targetDevice.name;

  @override
  Future<bool> isSupported() async => _targetDevice.isSupported;

  @override
  Future<bool> isSupportedForProject(FlutterProject flutterProject) =>
      _deviceService.isSupportedForProject(deviceId: id, projectRoot: flutterProject.directory.uri);

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
    final String? buildTargetName = _targetDevice.buildTarget;
    if (buildTargetName == null) {
      _logger.printError('Device $name does not specify a buildTarget for launching applications.');
      return LaunchResult.failed();
    }

    final BuildMode buildMode = debuggingOptions?.buildInfo.mode ?? .debug;
    final String targetMainPath = mainPath ?? 'lib/main.dart';

    String? executablePath;
    if (!prebuiltApplication) {
      _logger.printTrace('Building application using extension target "$buildTargetName"...');
      try {
        final Object? rawTargets = await connection.sendRequest(BuildService.getBuildTargetsMethod);
        final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(rawTargets);
        final ExtensionBuildTarget? target = targets
            .where((ExtensionBuildTarget t) => t.name == buildTargetName)
            .firstOrNull;
        if (target == null) {
          _logger.printError(
            'Extension does not provide build target "$buildTargetName" required by device $name.',
          );
          return LaunchResult.failed();
        }

        final Directory projectDir = _fileSystem.currentDirectory;
        final Object? rawResult = await connection.sendRequest(
          BuildService.buildMethod,
          params: <String, Object?>{
            BuildService.targetNameParam: target.name,
            BuildService.projectRootParam: projectDir.uri.toString(),
            BuildService.mainPathParam: targetMainPath,
            BuildService.buildModeParam: buildMode.cliName,
          },
          timeout: null,
        );

        if (rawResult case final Map<String, Object?> map) {
          final result = ExtensionBuildResult.fromJson(map);
          if (!result.success) {
            final String? errorMessage = result.errorMessage;
            _logger.printError(
              errorMessage != null && errorMessage.isNotEmpty
                  ? 'Build failed: $errorMessage'
                  : 'Build failed.',
            );
            return LaunchResult.failed();
          }
          executablePath = result.executablePath;
        } else {
          _logger.printError('Invalid build response from extension.');
          return LaunchResult.failed();
        }
      } on Object catch (err, stack) {
        _logger.printError('Failed to build application for $name: $err\n$stack');
        return LaunchResult.failed();
      }
    }

    if (executablePath == null || executablePath.isEmpty) {
      _logger.printError(
        'Extension build target "$buildTargetName" did not return an executablePath.',
      );
      return LaunchResult.failed();
    }

    final bool launched = await _deviceService.launchApp(
      id,
      executablePath,
      debuggingOptions: <String, Object?>{
        'debuggingEnabled': debuggingOptions?.debuggingEnabled ?? false,
        'buildMode': buildMode.cliName,
      },
    );
    if (!launched) {
      _logger.printError('Failed to launch application on $name.');
      return LaunchResult.failed();
    }

    if (debuggingOptions?.debuggingEnabled ?? false) {
      final String? vmServiceUriStr = await _deviceService.getVmServiceUri(id);
      if (vmServiceUriStr != null) {
        final Uri? vmServiceUri = Uri.tryParse(vmServiceUriStr);
        return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
      }
    }

    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    return _deviceService.stopApp(id);
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;
}
