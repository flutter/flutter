// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.stop;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/device.dart';

final Logger _logging = new Logger('sky_tools.stop');

class StopCommand extends Command {
  final name = 'stop';
  final description = 'Stop your Flutter app on all attached devices.';
  AndroidDevice android = null;

  StopCommand([this.android]) {
    if (android == null) {
      android = new AndroidDevice();
    }
  }

  @override
  Future<int> run() async {
    if (stop()) {
      return 0;
    } else {
      return 2;
    }
  }

  bool stop() {
    bool stoppedSomething = false;
    if (android.isConnected()) {
      Map<BuildPlatform, ApplicationPackage> packages =
          ApplicationPackageFactory.getAvailableApplicationPackages();
      ApplicationPackage androidApp = packages[BuildPlatform.android];
      stoppedSomething = android.stop(androidApp) || stoppedSomething;
    }

    return stoppedSomething;
  }
}
