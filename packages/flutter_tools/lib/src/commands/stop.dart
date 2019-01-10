// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class StopCommand extends FlutterCommand {
  StopCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'stop';

  @override
  final String description = 'Stop your Flutter app on an attached device.';

  Device device;

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    device = await findTargetDevice();
    if (device == null)
      throwToolExit(null);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final TargetPlatform targetPlatform = await device.targetPlatform;
    final ApplicationPackage app = await applicationPackages.getPackageForPlatform(targetPlatform);
    if (app == null) {
      final String platformName = getNameForTargetPlatform(targetPlatform);
      throwToolExit('No Flutter application for $platformName found in the current directory.');
    }
    printStatus('Stopping apps on ${device.name}.');
    if (!await device.stopApp(app))
      throwToolExit(null);

    return null;
  }
}
