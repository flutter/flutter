// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
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
  Future<bool> installApp({required Uri bundleUri, required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient installing app "$bundleUri" on "$deviceId" via RPC '
      '("${DeviceService.installAppMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.installAppMethod,
      params: <String, Object?>{
        DeviceService.bundleUriParam: bundleUri.toString(),
        DeviceService.deviceIdParam: deviceId,
      },
    );
    if (rawResult case final bool installed) {
      return installed;
    }
    _logger.printError(
      'ExtensionDeviceClient received invalid response for "${DeviceService.installAppMethod}": '
      'expected bool, got ${rawResult.runtimeType}.',
    );
    return false;
  }

  @override
  Future<bool> uninstallApp({required String appId, required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient uninstalling app "$appId" from "$deviceId" via RPC '
      '("${DeviceService.uninstallAppMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.uninstallAppMethod,
      params: <String, Object?>{
        DeviceService.appIdParam: appId,
        DeviceService.deviceIdParam: deviceId,
      },
    );
    if (rawResult case final bool uninstalled) {
      return uninstalled;
    }
    _logger.printError(
      'ExtensionDeviceClient received invalid response for "${DeviceService.uninstallAppMethod}": '
      'expected bool, got ${rawResult.runtimeType}.',
    );
    return false;
  }

  @override
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient checking if app "$appId" is installed on "$deviceId" via RPC '
      '("${DeviceService.isAppInstalledMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.isAppInstalledMethod,
      params: <String, Object?>{
        DeviceService.appIdParam: appId,
        DeviceService.deviceIdParam: deviceId,
      },
    );
    if (rawResult case final bool installed) {
      return installed;
    }
    _logger.printError(
      'ExtensionDeviceClient received invalid response for "${DeviceService.isAppInstalledMethod}": '
      'expected bool, got ${rawResult.runtimeType}.',
    );
    return false;
  }

  @override
  Future<void> takeScreenshot({required String deviceId, required Uri outputFileUri}) async {
    _logger.printTrace(
      'ExtensionDeviceClient taking screenshot on "$deviceId" to "$outputFileUri" via RPC '
      '("${DeviceService.takeScreenshotMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.takeScreenshotMethod,
      params: <String, Object?>{
        DeviceService.deviceIdParam: deviceId,
        DeviceService.outputFileUriParam: outputFileUri.toString(),
      },
    );
  }

  @override
  Future<void> startScreenRecording({
    required String deviceId,
    required Uri outputFileUri,
    Duration? duration,
  }) async {
    _logger.printTrace(
      'ExtensionDeviceClient starting screen recording on "$deviceId" to "$outputFileUri" via RPC '
      '("${DeviceService.startScreenRecordingMethod}")...',
    );
    await connection.sendRequest(
      DeviceService.startScreenRecordingMethod,
      params: <String, Object?>{
        DeviceService.deviceIdParam: deviceId,
        DeviceService.durationMsParam: ?duration?.inMilliseconds,
        DeviceService.outputFileUriParam: outputFileUri.toString(),
      },
    );
  }

  @override
  Future<Uri> stopScreenRecording({required String deviceId}) async {
    _logger.printTrace(
      'ExtensionDeviceClient stopping screen recording on "$deviceId" via RPC '
      '("${DeviceService.stopScreenRecordingMethod}")...',
    );
    final Object? rawResult = await connection.sendRequest(
      DeviceService.stopScreenRecordingMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
    );
    if (rawResult case final String rawUri) {
      final Uri? uri = Uri.tryParse(rawUri);
      if (uri != null && uri.isValidFileUri) {
        return uri;
      }
      throw FormatException(
        'ExtensionDeviceClient received invalid file URI for '
        '"${DeviceService.stopScreenRecordingMethod}": "$rawUri".',
      );
    }
    throw FormatException(
      'ExtensionDeviceClient received invalid response for '
      '"${DeviceService.stopScreenRecordingMethod}": expected String, got ${rawResult.runtimeType}.',
    );
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
  }) : _logger = logger,
       _targetDevice = targetDevice,
       super(
         targetDevice.id,
         category: targetDevice.category,
         platformType: PlatformType.custom,
         ephemeral: targetDevice.ephemeral,
       );

  final DeviceService _deviceService;
  final Logger _logger;
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
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async {
    if (app is! PrebuiltApplicationPackage) {
      _logger.printWarning(
        'Cannot install application "${app.id}" on "$id": '
        'expected a PrebuiltApplicationPackage.',
      );
      return false;
    }
    final Uri bundleUri = app.applicationPackage.absolute.uri;
    try {
      return await _deviceService.installApp(bundleUri: bundleUri, deviceId: id);
    } on Object catch (err, stack) {
      _logger.printWarning(
        'Failed to install application "${app.id}" on "$id" '
        '("${connection.extensionName}"): $err',
      );
      _logger.printTrace('$stack');
      return false;
    }
  }

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
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async {
    try {
      return await _deviceService.uninstallApp(appId: app.id, deviceId: id);
    } on Object catch (err, stack) {
      _logger.printWarning(
        'Failed to uninstall application "${app.id}" from "$id" '
        '("${connection.extensionName}"): $err',
      );
      _logger.printTrace('$stack');
      return false;
    }
  }

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async {
    try {
      return await _deviceService.isAppInstalled(appId: app.id, deviceId: id);
    } on Object catch (err, stack) {
      _logger.printWarning(
        'Failed to check if application "${app.id}" is installed on "$id" '
        '("${connection.extensionName}"): $err',
      );
      _logger.printTrace('$stack');
      return false;
    }
  }

  @override
  bool get supportsScreenshot => _targetDevice.supportsScreenshot;

  /// Whether the device supports recording the screen of a running Flutter
  /// application.
  bool get supportsScreenRecording => _targetDevice.supportsScreenRecording;

  @override
  Future<void> takeScreenshot(File outputFile) =>
      _deviceService.takeScreenshot(deviceId: id, outputFileUri: outputFile.absolute.uri);

  /// Starts recording the device screen to [outputFile], optionally stopping
  /// automatically after [duration].
  Future<void> startScreenRecording(File outputFile, {Duration? duration}) =>
      _deviceService.startScreenRecording(
        deviceId: id,
        duration: duration,
        outputFileUri: outputFile.absolute.uri,
      );

  /// Stops an active screen recording on the device and returns the [Uri] of
  /// the recorded output file.
  Future<Uri> stopScreenRecording() => _deviceService.stopScreenRecording(deviceId: id);
}
