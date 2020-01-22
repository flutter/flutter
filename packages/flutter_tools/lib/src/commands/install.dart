// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
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
    if (device == null) {
      throwToolExit('No target device found');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ApplicationPackage package = await applicationPackages.getPackageForPlatform(await device.targetPlatform);

    Cache.releaseLockEarly();

    globals.printStatus('Installing $package to $device...');

    if (!await installApp(device, package)) {
      throwToolExit('Install failed');
    }

    return FlutterCommandResult.success();
  }
}

Future<bool> installApp(Device device, ApplicationPackage package, { bool uninstall = true }) async {
  if (package == null) {
    return false;
  }

  if (uninstall && await device.isAppInstalled(package)) {
    globals.printStatus('Uninstalling old version...');
    if (!await device.uninstallApp(package)) {
      globals.printError('Warning: uninstalling old version failed');
    }
  }

  return device.installApp(package);
}
