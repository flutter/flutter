// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.install;

import 'dart:async';

import 'package:args/command_runner.dart';

import 'application_package.dart';
import 'device.dart';

class InstallCommand extends Command {
  final name = 'install';
  final description = 'Install your Flutter app on attached devices.';
  AndroidDevice android = null;
  InstallCommand([this.android]) {
    if (android == null) {
      android = new AndroidDevice();
    }
  }

  @override
  Future<int> run() async {
    if (install()) {
      return 0;
    } else {
      return 2;
    }
  }

  bool install() {
    bool installedSomewhere = false;

    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();
    ApplicationPackage androidApp = packages[BuildPlatform.android];
    if (androidApp != null && android.isConnected()) {
      installedSomewhere = android.installApp(androidApp) || installedSomewhere;
    }

    return installedSomewhere;
  }
}
