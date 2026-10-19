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
import 'extension_build_manager.dart';
import 'extension_discovery.dart';
import 'extension_manager.dart';

/// A host-side [DeviceService] client adapter delegating RPC queries to an [ExtensionConnection].
final class ExtensionDeviceClient extends DeviceService {
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
      final Object? rawResult = await connection.sendRequest(DeviceService.getDevicesMethod);
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
      final Object? rawResult = await connection.sendRequest(
        DeviceService.isSupportedForProjectMethod,
        params: <String, Object?>{
          DeviceService.deviceIdParam: deviceId,
          DeviceService.projectRootParam: projectRoot.toString(),
        },
      );
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
  Future<bool> launchApp({
    required String deviceId,
    required String executablePath,
    ExtensionDebuggingOptions? debuggingOptions,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient launching app "$executablePath" on "$deviceId" via RPC '
      '("${DeviceService.launchAppMethod}")...',
    );
    try {
      final Map<String, Object?>? optionsMap = debuggingOptions?.toMap();
      final Object? rawResult = await connection.sendRequest(
        DeviceService.launchAppMethod,
        params: <String, Object?>{
          DeviceService.deviceIdParam: deviceId,
          DeviceService.executablePathParam: executablePath,
          DeviceService.debuggingOptionsParam: ?optionsMap,
        },
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
        timeout: null,
      );
      if (rawResult case final bool launched) {
        return launched;
      }
      _logger.printError(
        'ExtensionDeviceClient received invalid response for "${DeviceService.launchAppMethod}": '
        'expected bool, got ${rawResult.runtimeType}.',
      );
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to launch app: $err\n$stack');
    }
    return false;
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient getting VM Service URI for "$deviceId" via RPC '
      '("${DeviceService.getVmServiceUriMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.getVmServiceUriMethod,
        params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
        timeout: null,
      );
      if (rawResult case {DeviceService.vmServiceUriKey: final String uri}) {
        return Uri.tryParse(uri);
      }
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to get VM Service URI: $err\n$stack');
    }
    return null;
  }

  @override
  Future<bool> stopApp({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping app on "$deviceId" via RPC '
      '("${DeviceService.stopAppMethod}")...',
    );
    try {
      final Object? rawResult = await connection.sendRequest(
        DeviceService.stopAppMethod,
        params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
        // TODO(bkonyi): Support heartbeat / liveness monitoring for long-running RPCs,
        // https://github.com/flutter/flutter/issues/193955.
        timeout: null,
      );
      if (rawResult case final bool stopped) {
        return stopped;
      }
      _logger.printError(
        'ExtensionDeviceClient received invalid response for "${DeviceService.stopAppMethod}": '
        'expected bool, got ${rawResult.runtimeType}.',
      );
    } on Object catch (err, stack) {
      _logger.printTrace('ExtensionDeviceClient failed to stop app: $err\n$stack');
    }
    return false;
  }
}

/// A host-side [DeviceDiscovery] mechanism that discovers devices registered by active extensions.
class ExtensionDevices extends PollingDeviceDiscovery {
  ExtensionDevices({
    required this._extensionBuildManager,
    required this._extensionManager,
    required this._fileSystem,
    required this._logger,
  }) : super('tool_extension');

  final ExtensionBuildManager _extensionBuildManager;
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
      deviceServices.map((DeviceService service) async {
        try {
          final List<TargetDevice> devices = await service.getDevices();
          return devices
              .map(
                (TargetDevice targetDevice) => ExtensionBackedDevice(
                  buildManager: _extensionBuildManager,
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
  ExtensionBackedDevice({
    required this._buildManager,
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

  final ExtensionBuildManager _buildManager;
  final DeviceService _deviceService;
  final FileSystem _fileSystem;
  final Logger _logger;
  final TargetDevice _targetDevice;

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
    required DebuggingOptions debuggingOptions,
    bool ipv6 = false,
    String? mainPath,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    String? route,
    String? userIdentifier,
  }) async {
    final BuildMode buildMode = debuggingOptions.buildInfo.mode;

    String? executablePath;
    if (prebuiltApplication) {
      if (package is PrebuiltApplicationPackage) {
        executablePath = package.applicationPackage.path;
      }
      if (executablePath == null || executablePath.isEmpty) {
        _logger.printError('No prebuilt application binary provided for launching on $name.');
        return LaunchResult.failed();
      }
    } else {
      final String? buildTargetName = _targetDevice.buildTarget;
      if (buildTargetName == null) {
        _logger.printError(
          'Device $name does not specify a buildTarget for launching applications.',
        );
        return LaunchResult.failed();
      }

      final String targetMainPath = mainPath ?? 'lib/main.dart';
      _logger.printTrace('Building application using extension target "$buildTargetName"...');
      try {
        final ExtensionBuildResult result = await _buildManager.build(
          buildMode: buildMode,
          mainPath: targetMainPath,
          projectRoot: _fileSystem.currentDirectory.uri,
          targetName: buildTargetName,
        );
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
      } on Object catch (err, stack) {
        _logger.printError('Failed to build application for $name: $err\n$stack');
        return LaunchResult.failed();
      }

      if (executablePath == null || executablePath.isEmpty) {
        _logger.printError(
          'Extension build target "$buildTargetName" did not return an executablePath.',
        );
        return LaunchResult.failed();
      }
    }

    final bool debuggingEnabled = debuggingOptions.debuggingEnabled;
    final bool launched = await _deviceService.launchApp(
      deviceId: id,
      executablePath: executablePath,
      debuggingOptions: ExtensionDebuggingOptions(
        buildMode: buildMode,
        debuggingEnabled: debuggingEnabled,
      ),
    );
    if (!launched) {
      _logger.printError('Failed to launch application on $name.');
      return LaunchResult.failed();
    }

    if (debuggingEnabled) {
      final Uri? vmServiceUri = await _deviceService.getVmServiceUri(deviceId: id);
      if (vmServiceUri != null) {
        return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
      }
    }

    return LaunchResult.succeeded();
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    return _deviceService.stopApp(deviceId: id);
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;
}
