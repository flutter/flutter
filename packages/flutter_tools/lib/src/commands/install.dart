// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand {
  InstallCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'install';

  @override
  final String description = 'Install a Flutter app on an attached device.';

  Device device;

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    device = await findTargetDevice();
    if (device == null)
      throwToolExit('No target device found');
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ApplicationPackage package = await applicationPackages.getPackageForPlatform(await device.targetPlatform);

    Cache.releaseLockEarly();

    printStatus('Installing $package to $device...');

    if (!await installApp(device, package))
      throwToolExit('Install failed');

    return null;
  }
}

Future<bool> installApp(Device device, ApplicationPackage package, { bool uninstall = true }) async {
  if (package == null)
    return false;

  if (uninstall && await device.isAppInstalled(package)) {
    printStatus('Uninstalling old version...');
    if (!await device.uninstallApp(package))
      printError('Warning: uninstalling old version failed');
  }

  return device.installApp(package);
}
