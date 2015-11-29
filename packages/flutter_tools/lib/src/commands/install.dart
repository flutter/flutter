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

  InstallCommand() {
    argParser.addFlag('boot',
        help: 'Boot the iOS Simulator if it isn\'t already running.');
  }

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackagesAndConnectToDevices();
    return install(boot: argResults['boot']) ? 0 : 2;
  }

  bool install({ bool boot: false }) {
    if (boot)
      devices.iOSSimulator?.boot();

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
}
