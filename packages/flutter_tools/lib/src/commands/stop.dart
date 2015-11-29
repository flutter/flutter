// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../device.dart';
import '../runner/flutter_command.dart';

class StopCommand extends FlutterCommand {
  final String name = 'stop';
  final String description = 'Stop your Flutter app on all attached devices.';

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackagesAndConnectToDevices();
    return await stop() ? 0 : 2;
  }

  Future<bool> stop() async {
    bool stoppedSomething = false;

    for (Device device in devices.all) {
      ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
      if (package == null || !device.isConnected())
        continue;
      if (await device.stopApp(package))
        stoppedSomething = true;
    }

    return stoppedSomething;
  }
}
