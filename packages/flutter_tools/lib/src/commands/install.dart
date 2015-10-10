// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.install;

import 'dart:async';

import 'package:args/command_runner.dart';

import '../application_package.dart';
import '../device.dart';

class InstallCommand extends Command {
  final name = 'install';
  final description = 'Install your Flutter app on attached devices.';

  AndroidDevice android = null;
  IOSDevice ios;

  InstallCommand({this.android, this.ios});

  @override
  Future<int> run() async {
    if (install()) {
      return 0;
    } else {
      return 2;
    }
  }

  bool install() {
    if (android == null) {
      android = new AndroidDevice();
    }
    if (ios == null) {
      ios = new IOSDevice();
    }

    bool installedSomewhere = false;

    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();
    ApplicationPackage androidApp = packages[BuildPlatform.android];
    ApplicationPackage iosApp = packages[BuildPlatform.iOS];

    if (androidApp != null && android.isConnected()) {
      installedSomewhere = android.installApp(androidApp) || installedSomewhere;
    }

    if (iosApp != null && ios.isConnected()) {
      installedSomewhere = ios.installApp(iosApp) || installedSomewhere;
    }

    return installedSomewhere;
  }
}
