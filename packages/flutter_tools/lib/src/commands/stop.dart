// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.stop;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../application_package.dart';
import '../device.dart';

final Logger _logging = new Logger('sky_tools.stop');

class StopCommand extends Command {
  final name = 'stop';
  final description = 'Stop your Flutter app on all attached devices.';
  AndroidDevice android;
  IOSDevice ios;
  IOSSimulator iosSim;

  StopCommand({this.android, this.ios, this.iosSim});

  @override
  Future<int> run() async {
    if (await stop()) {
      return 0;
    } else {
      return 2;
    }
  }

  Future<bool> stop() async {
    if (android == null) {
      android = new AndroidDevice();
    }
    if (ios == null) {
      ios = new IOSDevice();
    }
    if (iosSim == null) {
      iosSim = new IOSSimulator();
    }

    bool stoppedSomething = false;
    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();

    if (android.isConnected()) {
      ApplicationPackage androidApp = packages[BuildPlatform.android];
      stoppedSomething = await android.stopApp(androidApp) || stoppedSomething;
    }

    if (ios.isConnected()) {
      ApplicationPackage iosApp = packages[BuildPlatform.iOS];
      stoppedSomething = await ios.stopApp(iosApp) || stoppedSomething;
    }

    if (iosSim.isConnected()) {
      ApplicationPackage iosApp = packages[BuildPlatform.iOSSimulator];
      stoppedSomething = await iosSim.stopApp(iosApp) || stoppedSomething;
    }

    return stoppedSomething;
  }
}
