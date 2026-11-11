// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'flutter_application_package.dart';
library;

import 'base/context.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'device.dart';
import 'experimental/extension_device_manager.dart';

abstract class ApplicationPackageFactory {
  static ApplicationPackageFactory? get instance => context.get<ApplicationPackageFactory>();

  /// Create an [ApplicationPackage] for the given platform.
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  });
}

/// Device-scoped [ApplicationPackage] resolution helpers for
/// [ApplicationPackageFactory].
extension ApplicationPackageDeviceResolution on ApplicationPackageFactory {
  /// Creates an [ApplicationPackage] for [device].
  ///
  /// When [device] is an [ExtensionBackedDevice], delegates to
  /// [ExtensionBackedDevice.resolveApplicationPackage]; otherwise delegates to
  /// [ApplicationPackageFactory.getPackageForPlatform] using
  /// [Device.targetPlatform].
  Future<ApplicationPackage?> getPackageForDevice(
    Device device, {
    File? applicationBinary,
    BuildInfo? buildInfo,
  }) async {
    if (device is ExtensionBackedDevice) {
      return device.resolveApplicationPackage(
        applicationBinary: applicationBinary,
        buildInfo: buildInfo,
      );
    }
    return getPackageForPlatform(
      await device.targetPlatform,
      applicationBinary: applicationBinary,
      buildInfo: buildInfo,
    );
  }
}

/// Resolves an [ApplicationPackage] for [device], delegating directly to
/// [ExtensionBackedDevice.resolveApplicationPackage] for tool extension devices
/// without evaluating [factoryBuilder], and falling back to
/// [ApplicationPackageDeviceResolution.getPackageForDevice] otherwise.
Future<ApplicationPackage?> resolveApplicationPackageForDevice(
  Device device, {
  required ApplicationPackageFactory? Function() factoryBuilder,
  File? applicationBinary,
  BuildInfo? buildInfo,
}) async {
  if (device is ExtensionBackedDevice) {
    return device.resolveApplicationPackage(
      applicationBinary: applicationBinary,
      buildInfo: buildInfo,
    );
  }
  return factoryBuilder()?.getPackageForDevice(
    device,
    applicationBinary: applicationBinary,
    buildInfo: buildInfo,
  );
}

abstract class ApplicationPackage {
  ApplicationPackage({required this.id});

  /// Package ID from the Android Manifest or equivalent.
  final String id;

  String? get name;

  String? get displayName => name;

  @override
  String toString() => displayName ?? id;
}

/// An interface for application package that is created from prebuilt binary.
abstract class PrebuiltApplicationPackage implements ApplicationPackage {
  /// The application bundle of the prebuilt application.
  ///
  /// The same ApplicationPackage should be able to be recreated by passing
  /// the file to [FlutterApplicationPackageFactory.getPackageForPlatform].
  FileSystemEntity get applicationPackage;
}
