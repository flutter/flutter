// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'flutter_application_package.dart';
library;

import 'base/file_system.dart';
import 'build_info.dart';
import 'device.dart';
import 'experimental/extension_device_manager.dart';

abstract class ApplicationPackageFactory {
  /// Create an [ApplicationPackage] for the given platform.
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  });
}

/// Device-aware package resolution helper for [ApplicationPackageFactory].
extension ApplicationPackageFactoryDeviceExtension on ApplicationPackageFactory {
  /// Resolves an [ApplicationPackage] for [device], delegating to
  /// [ExtensionBackedDevice.resolveApplicationPackage] for extension-backed
  /// devices and [getPackageForPlatform] otherwise.
  Future<ApplicationPackage?> getPackageForDevice(
    Device device, {
    BuildInfo? buildInfo,
    File? applicationBinary,
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
