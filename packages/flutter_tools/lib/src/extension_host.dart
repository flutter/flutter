// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'device.dart';
import 'doctor.dart';
import 'extension/app.dart' as ext;
import 'extension/build.dart' as ext;
import 'extension/device.dart' as ext;
import 'extension/doctor.dart' as ext;
import 'extension/extension.dart';
import 'features.dart';
import 'globals.dart';
import 'linux/linux_extension.dart';
import 'project.dart';

/// The [ExtensionHost] instance.
ExtensionHost get extensionHost => context.get<ExtensionHost>();

/// A migration path for loading a [ToolExtension] hosted in the same isolate.
class ExtensionHost {
  ExtensionHost([List<ToolExtension> additionalExtensions = const <ToolExtension>[]]) {
    if (featureFlags.isLinuxEnabled) {
      final LinuxToolExtension toolExtension = LinuxToolExtension();
      toolExtensions.add(toolExtension);
    }
    toolExtensions.addAll(additionalExtensions);
    // Initialize logging.
    for (ToolExtension toolExtension in toolExtensions) {
      toolExtension.logs.listen((Log log) {
        if (log.trace == true) {
          printTrace(log.body);
        }
        if (log.error == true) {
          printError(log.body);
        }
        printStatus(log.body);
      });
    }
  }

  @visibleForTesting
  final List<ToolExtension> toolExtensions = <ToolExtension>[];

  /// Return devices provided by an extension host.
  Stream<Device> getExtensionDevices() async* {
    for (ToolExtension toolExtension in toolExtensions) {
      final ext.DeviceList toolDevices = await toolExtension.deviceDomain.listDevices();
      for (ext.Device device in toolDevices.devices) {
        yield DeviceDelegate(
          device,
          toolExtension,
        );
      }
    }
  }

  /// Return doctor validations provided by an extension host.
  List<DoctorValidator> getExtensionValidations() {
    return toolExtensions.map((ToolExtension toolExtension) {
      return DelegateDoctorValidator(toolExtension);
    }).toList();
  }
}

/// A doctor validator that delegates to a tool extension.
class DelegateDoctorValidator implements DoctorValidator {
  DelegateDoctorValidator(this.extension);

  final ToolExtension extension;

  @override
  String get slowWarning => null;

  @override
  String get title => _lastResult.name;

  ext.ValidationResult _lastResult;

  @override
  Future<ValidationResult> validate() async {
    final ext.ValidationResult result = await extension.doctorDomain.diagnose();
    _lastResult = result;

    ValidationType type;
    final List<ValidationMessage> messages = <ValidationMessage>[];

    switch (result.type) {
      case ext.ValidationType.missing:
        type = ValidationType.missing;
        break;
      case ext.ValidationType.partial:
        type = ValidationType.partial;
        break;
      case ext.ValidationType.notAvailable:
        type = ValidationType.notAvailable;
        break;
      case ext.ValidationType.installed:
        type = ValidationType.installed;
        break;
    }
    for (ext.ValidationMessage message in result.messages) {
      ValidationMessageType messageType;
      switch (message.type) {
        case ext.ValidationMessageType.hint:
          messageType = ValidationMessageType.hint;
          break;
        case ext.ValidationMessageType.error:
          messageType = ValidationMessageType.error;
          break;
        case ext.ValidationMessageType.information:
          messageType = ValidationMessageType.information;
          break;
      }
      messages.add(ValidationMessage(message.message, messageType));
    }

    return ValidationResult(
      type,
      messages,
    );
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
    final ext.DartBuildMode dartBuildMode = debuggingOptions?.buildInfo?.isDebug == true
        ? ext.DartBuildMode.debug
        : ext.DartBuildMode.release;
    ext.ApplicationBundle applicationBundle;
    try {
      applicationBundle = await extension.buildDomain.buildApp(ext.BuildInfo(
        dartBuildMode: dartBuildMode,
        projectRoot: fs.currentDirectory.uri,
        targetFile: Uri.file(mainPath),
      ));
    } catch (err, stackTrace) {
      printError(err.toString());
      printError(stackTrace.toString());
      return LaunchResult.failed();
    }
    _applicationBundle = applicationBundle;
    try {
      final ext.ApplicationInstance applicationInstance = await extension.appDomain.startApp(applicationBundle, id);
      return LaunchResult.succeeded(
        observatoryUri: applicationInstance.vmserviceUri
      );
    } catch (err, stackTrace) {
      printError(err.toString());
      printError(stackTrace.toString());
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
  bool get supportsFlutterExit => true;

  @override
  Future<bool> get supportsHardwareRendering async => true;

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
  Future<TargetPlatform> get targetPlatform async {
    switch (device.targetPlatform) {
      case ext.TargetPlatform.macOS:
        return TargetPlatform.darwin_x64;
      case ext.TargetPlatform.linux:
        return TargetPlatform.linux_x64;
      case ext.TargetPlatform.windows:
        return TargetPlatform.windows_x64;
      case ext.TargetPlatform.android:
        switch (device.targetArchitecture) {
          case ext.TargetArchitecture.x86:
            return TargetPlatform.android_x86;
          case ext.TargetArchitecture.x86_64:
            return TargetPlatform.android_x64;
          case ext.TargetArchitecture.arm64_v8a:
            return TargetPlatform.android_arm64;
          case ext.TargetArchitecture.armeabi_v7a:
            return TargetPlatform.android_arm;
        }
        // TODO(jonahwilliams): remaining fields.
    }
    return null;
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;
}
