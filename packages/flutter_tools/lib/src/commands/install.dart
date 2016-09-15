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

  Device deviceForCommand;

  @override
  Future<int> runCmd() async {
    if (!commandValidator())
      return 1;
    deviceForCommand = await findTargetDevice(androidOnly: androidOnly);
    if (deviceForCommand == null)
      return 1;
    return super.runCmd();
  }

  @override
  Future<int> runInProject() async {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(deviceForCommand.platform);

    Cache.releaseLockEarly();

    printStatus('Installing $package to $deviceForCommand...');

    return installApp(deviceForCommand, package) ? 0 : 2;
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
