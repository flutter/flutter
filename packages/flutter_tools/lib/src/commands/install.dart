// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand {
  @override
  final String name = 'install';

  @override
  final String description = 'Install a Flutter app on an attached device.';

  Device device;

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    device = await findTargetDevice();
    if (device == null)
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);

    Cache.releaseLockEarly();

    printStatus('Installing $package to $device...');

    return installApp(device, package) ? 0 : 2;
  }
}

bool installApp(Device device, ApplicationPackage package, { bool uninstall: true }) {
  if (package == null)
    return false;

  if (uninstall && device.isAppInstalled(package)) {
    printStatus('Uninstalling old version...');
    if (!device.uninstallApp(package))
      printError('Warning: uninstalling old version failed');
  }

  return device.installApp(package);
}
