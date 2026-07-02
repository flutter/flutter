// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../../generic_extension_protocol.dart';
import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../extension_prototypes/linux_extension/extension.dart';
import '../linux/application_package.dart';
import '../linux/build_linux.dart';
import '../project.dart';
import '../vmservice.dart';

/// A [DeviceDiscovery] implementation that delegates discovery to active tool extensions.
class ExtensionDeviceDiscovery extends DeviceDiscovery {
  ExtensionDeviceDiscovery(this._extensionManager, {required Logger logger}) : _logger = logger;

  final ToolExtensionManager _extensionManager;
  final Logger _logger;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  @override
  List<String> get wellKnownIds => const <String>[];

  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) async {
    return discoverDevices(filter: filter);
  }

  @override
  Future<List<Device>> discoverDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
    bool forWirelessDiscovery = false,
  }) async {
    final discoveredDevices = <Device>[];

    if (Platform.environment['FLUTTER_TOOL_EXTENSION_PROTOTYPE'] == 'true') {
      if (_extensionManager.extensions.isEmpty) {
        try {
          await _extensionManager.startExtension(linuxDeviceExtensionEntryPoint);
        } on Object catch (e) {
          _logger.printError('Failed to spawn prototype extension: $e');
        }
      }
    }

    for (final ToolExtension extension in _extensionManager.extensions) {
      late final ToolExtensionCapabilities capabilities;
      try {
        capabilities = await extension.getCapabilities();
      } on Exception {
        continue;
      }
      if (!capabilities.services.contains('device')) {
        continue;
      }

      try {
        final Object? devicesResult = await extension.callMethod('device.discoverDevices');
        if (devicesResult is List) {
          for (final Object? item in devicesResult) {
            if (item is Map) {
              final Map<String, Object?> deviceData = item.cast<String, Object?>();
              discoveredDevices.add(
                ExtensionBackedDevice(
                  deviceData['id']! as String,
                  name: deviceData['name']! as String,
                  category: _parseCategory(deviceData['category'] as String?),
                  extension: extension,
                  logger: _logger,
                ),
              );
            }
          }
        }
      } on Object {
        // Ignore failures from individual extensions.
      }
    }

    return discoveredDevices;
  }

  Category _parseCategory(String? category) {
    if (category == 'desktop') {
      return Category.desktop;
    }
    if (category == 'mobile') {
      return Category.mobile;
    }
    if (category == 'web') {
      return Category.web;
    }
    return Category.mobile;
  }
}

/// A client-side [Device] implementation that delegates all commands to an extension isolate.
class ExtensionBackedDevice extends Device {
  ExtensionBackedDevice(
    super.id, {
    required super.category,
    required ToolExtension extension,
    required super.logger,
    required this.name,
  }) : _extension = extension,
       _logger = logger,
       super(platformType: PlatformType.custom, ephemeral: true) {
    _logReader = ExtensionDeviceLogReader(
      name: '$name log reader',
      logLines: _extension.notifications
          .where(
            (Notification n) =>
                n.method == 'device.log' &&
                n.params?['deviceId'] == id &&
                n.params?['message'] is String,
          )
          .map((Notification n) => n.params!['message']! as String),
    );
  }

  final ToolExtension _extension;
  final Logger _logger;

  @override
  final String name;

  late final ExtensionDeviceLogReader _logReader;

  @override
  Future<bool> isSupported() async => true;

  @override
  bool isSupportedForProject(FlutterProject project) => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  DevicePortForwarder? get portForwarder => null;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier}) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async => false;

  @override
  Future<TargetPlatform> get targetPlatform async {
    return switch (category) {
      Category.desktop => TargetPlatform.linux_x64,
      Category.mobile => TargetPlatform.android,
      Category.web => TargetPlatform.web_javascript,
      null => TargetPlatform.android,
    };
  }

  @override
  Future<String> get sdkNameAndVersion async => 'Extension Custom SDK';

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async {
    try {
      await _extension.callMethod(
        'device.installApp',
        params: <String, Object?>{'deviceId': id, 'appBundlePath': app.name},
      );
      return true;
    } on Exception catch (e) {
      throwToolExit('Failed to install app on extension device: $e');
    }
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    required DebuggingOptions debuggingOptions,
    String? mainPath,
    Map<String, Object?>? platformArgs,
    bool prebuiltApplication = false,
    String? route,
    String? userIdentifier,
  }) async {
    if (!prebuiltApplication) {
      final TargetPlatform platform = await targetPlatform;
      if (platform == TargetPlatform.linux_x64) {
        await buildLinux(
          FlutterProject.current().linux,
          debuggingOptions.buildInfo,
          target: mainPath,
          targetPlatform: platform,
          logger: _logger,
        );
      } else {
        throwToolExit('Unsupported platform for custom extension device build: $platform');
      }
    }

    String? executablePath;
    if (package is LinuxApp) {
      executablePath = package.executable(debuggingOptions.buildInfo.mode);
    }

    try {
      await _extension.callMethod(
        'device.launchApp',
        params: <String, Object?>{
          'deviceId': id,
          'appBundlePath': executablePath ?? package?.name,
          'args': debuggingOptions.dartEntrypointArgs,
        },
      );

      final Object? uriString = await _extension.callMethod(
        'device.getVmServiceUri',
        params: <String, Object?>{'deviceId': id},
      );
      if (uriString is! String) {
        return LaunchResult.failed();
      }
      final Uri vmServiceUri = Uri.parse(uriString);
      return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
    } on Object {
      return LaunchResult.failed();
    }
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    try {
      await _extension.callMethod('device.stopApp', params: <String, Object?>{'deviceId': id});
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) =>
      _logReader;

  @override
  void clearLogs() {}

  @override
  Future<void> dispose() async {
    _logReader.dispose();
  }
}

/// A [DeviceLogReader] implementation that listens to GEP notifications from the extension.
class ExtensionDeviceLogReader extends DeviceLogReader {
  ExtensionDeviceLogReader({required Stream<String> logLines, required this.name})
    : _logLines = logLines;

  @override
  final String name;

  final Stream<String> _logLines;

  @override
  Stream<String> get logLines => _logLines;

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {}

  @override
  void dispose() {}
}
