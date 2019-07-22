// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'application_package.dart';
import 'artifacts.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'device.dart';
import 'extension/app.dart' as ext;
import 'extension/build.dart' as ext;
import 'extension/device.dart' as ext;
import 'extension/extension.dart';
import 'project.dart';

/// The [ExtensionHost] instance.
ExtensionHost get extensionHost => context.get<ExtensionHost>();

/// A migration path for loading a [ToolExtension] hosted in the same isolate.
class ExtensionHost {
  ExtensionHost(this._toolExtensions);

  final List<ToolExtension> _toolExtensions;

  /// Return devices provided by an extension host.
  Stream<Device> getExtensionDevices() async* {
    for (ToolExtension toolExtension in _toolExtensions) {
      final ext.DeviceList toolDevices = await toolExtension.deviceDomain.listDevices();
      for (ext.Device device in toolDevices.devices) {
        yield DeviceDelegate(
          device,
          toolExtension,
        );
      }
    }
  }
}

/// A device that delegates to an extension device.
class DeviceDelegate implements Device {
  DeviceDelegate(this.device, this.extension);

  final ext.Device device;
  final ToolExtension extension;

  @override
  OverrideArtifacts get artifactOverrides => null;

  @override
  Category get category { 
    switch (device.category) {
      case ext.Category.desktop:
        return Category.desktop;
      case ext.Category.mobile:
        return Category.mobile;
      case ext.Category.web:
        return Category.web;
    }
    return null;
  }

  @override
  void clearLogs() {}

  @override
  Future<String> get emulatorId => null;

  @override
  bool get ephemeral => device.ephemeral;

  @override
  DeviceLogReader getLogReader({ApplicationPackage app}) {
    return NoOpDeviceLogReader(device.deviceName);
  }

  @override
  String get id => device.deviceId;

  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  String get name => device.deviceName;

  @override
  PlatformType get platformType => null;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => device.sdkNameAndVersion;

  ext.ApplicationBundle _applicationBundle;

  @override
  Future<LaunchResult> startApp(ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, Object> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    bool usesTerminalUi = true,
  }) async {
    final ext.DartBuildMode dartBuildMode = debuggingOptions.buildInfo.isDebug
        ? ext.DartBuildMode.debug
        : ext.DartBuildMode.release;
    final ext.ApplicationBundle applicationBundle = await extension.buildDomain.build(ext.BuildInfo(
      dartBuildMode: dartBuildMode,
      projectRoot: fs.currentDirectory.uri,
      targetFile: Uri.file(mainPath),
    ));
    _applicationBundle = applicationBundle;
    try {
      final ext.ApplicationInstance applicationInstance = await extension.appDomain.startApp(applicationBundle, id);
      return LaunchResult.succeeded(
        observatoryUri: applicationInstance.vmserviceUri
      );
    } catch (err) {
      return LaunchResult.failed();
    }
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    await extension.appDomain.stopApp(_applicationBundle);
    return true;
  }

  @override
  String supportMessage() {
    return null;
  }

  @override
  bool get supportsFlutterExit => null;

  @override
  Future<bool> get supportsHardwareRendering => null;

  @override
  bool get supportsHotReload => device.deviceCapabilities.supportsHotReload;

  @override
  bool get supportsHotRestart => device.deviceCapabilities.supportsHotRestart;

  @override
  bool get supportsScreenshot => device.deviceCapabilities.supportsScreenshot;

  @override
  bool get supportsStartPaused => device.deviceCapabilities.supportsStartPaused;

  @override
  Future<void> takeScreenshot(File outputFile) => null;

  @override
  Future<TargetPlatform> get targetPlatform => null;

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;
}
