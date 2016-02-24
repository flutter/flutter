// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../device.dart';
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand {
  final String name = 'install';
  final String description = 'Install Flutter apps on attached devices.';

  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackagesAndConnectToDevices();
    bool installedAny = await installApp(devices, applicationPackages);
    return installedAny ? 0 : 2;
  }
}

Future<bool> installApp(
  DeviceStore devices,
  ApplicationPackageStore applicationPackages
) async {
  bool installedSomewhere = false;

  for (Device device in devices.all) {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
    if (package == null || !device.isConnected() || device.isAppInstalled(package))
      continue;
    if (device.installApp(package))
      installedSomewhere = true;
  }

  return installedSomewhere;
}
