// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../build_info.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class StopCommand extends FlutterCommand {
  @override
  final String name = 'stop';

  @override
  final String description = 'Stop your Flutter app on an attached device.';

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
    ApplicationPackage app = applicationPackages.getPackageForPlatform(device.platform);
    if (app == null) {
      String platformName = getNameForTargetPlatform(device.platform);
      printError('No Flutter application for $platformName found in the current directory.');
      return 1;
    }
    printStatus('Stopping apps on ${device.name}.');
    return await device.stopApp(app) ? 0 : 1;
  }
}
