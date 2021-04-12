// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../android/android_device.dart';
import '../application_package.dart';
import '../base/common.dart';
import '../base/io.dart';
import '../device.dart';
import '../globals_null_migrated.dart' as globals;
import '../runner/flutter_command.dart';

class InstallCommand extends FlutterCommand with DeviceBasedDevelopmentArtifacts {
  InstallCommand() {
    requiresPubspecYaml();
    usesDeviceUserOption();
    usesDeviceTimeoutOption();
    argParser.addFlag('uninstall-only',
      negatable: true,
      defaultsTo: false,
      help: 'Uninstall the app if already on the device. Skip install.',
    );
  }

  @override
  final String name = 'install';

  @override
  final String description = 'Install a Flutter app on an attached device.';

  Device device;

  bool get uninstallOnly => boolArg('uninstall-only');
  String get userIdentifier => stringArg(FlutterOptions.kDeviceUser);

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    device = await findTargetDevice();
    if (device == null) {
      throwToolExit('No target device found');
    }
    if (userIdentifier != null && device is! AndroidDevice) {
      throwToolExit('--${FlutterOptions.kDeviceUser} is only supported for Android');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ApplicationPackage package = await applicationPackages.getPackageForPlatform(
      await device.targetPlatform,
    );

    if (uninstallOnly) {
      await _uninstallApp(package);
    } else {
      await _installApp(package);
    }
    return FlutterCommandResult.success();
  }

  Future<void> _uninstallApp(ApplicationPackage package) async {
    if (await device.isAppInstalled(package, userIdentifier: userIdentifier)) {
      globals.printStatus('Uninstalling $package from $device...');
      if (!await device.uninstallApp(package, userIdentifier: userIdentifier)) {
        globals.printError('Uninstalling old version failed');
      }
    } else {
      globals.printStatus('$package not found on $device, skipping uninstall');
    }
  }

  Future<void> _installApp(ApplicationPackage package) async {
    globals.printStatus('Installing $package to $device...');

    if (!await installApp(device, package, userIdentifier: userIdentifier)) {
      throwToolExit('Install failed');
    }
  }
}

Future<bool> installApp(
  Device device,
  ApplicationPackage package, {
  String userIdentifier,
  bool uninstall = true
}) async {
  if (package == null) {
    return false;
  }

  try {
    if (uninstall && await device.isAppInstalled(package, userIdentifier: userIdentifier)) {
      globals.printStatus('Uninstalling old version...');
      if (!await device.uninstallApp(package, userIdentifier: userIdentifier)) {
        globals.printError('Warning: uninstalling old version failed');
      }
    }
  } on ProcessException catch (e) {
    globals.printError('Error accessing device ${device.id}:\n${e.message}');
  }

  return device.installApp(package, userIdentifier: userIdentifier);
}
