// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'base/os.dart';
import 'device.dart';

/// A partial implementation of Device for desktop-class devices to inherit
/// from, containing implementations that are common to all desktop devices.
abstract class DesktopDevice extends Device {
  DesktopDevice(String identifier, {@required PlatformType platformType, @required bool ephemeral}) : super(
      identifier,
      category: Category.desktop,
      platformType: platformType,
      ephemeral: ephemeral,
  );

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to install the application.
  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  // Since the host and target devices are the same, no work needs to be done
  // to uninstall the application.
  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();

  @override
  Future<String> get sdkNameAndVersion async => os.name;
}