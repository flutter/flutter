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

  AndroidDevice android;
  IOSDevice ios;
  IOSSimulator iosSim;

  InstallCommand({this.android, this.ios, this.iosSim}) {
    argParser.addFlag('boot',
        help: 'Boot the iOS Simulator if it isn\'t already running.');
  }

  @override
  Future<int> run() async {
    if (install(argResults['boot'])) {
      return 0;
    } else {
      return 2;
    }
  }

  bool install([bool boot = false]) {
    if (android == null) {
      android = new AndroidDevice();
    }
    if (ios == null) {
      ios = new IOSDevice();
    }
    if (iosSim == null) {
      iosSim = new IOSSimulator();
    }

    if (boot) {
      iosSim.boot();
    }

    bool installedSomewhere = false;

    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();
    ApplicationPackage androidApp = packages[BuildPlatform.android];
    ApplicationPackage iosApp = packages[BuildPlatform.iOS];
    ApplicationPackage iosSimApp = packages[BuildPlatform.iOSSimulator];

    if (androidApp != null && android.isConnected()) {
      installedSomewhere = android.installApp(androidApp) || installedSomewhere;
    }

    if (iosApp != null && ios.isConnected()) {
      installedSomewhere = ios.installApp(iosApp) || installedSomewhere;
    }

    if (iosSimApp != null && iosSim.isConnected()) {
      installedSomewhere = iosSim.installApp(iosSimApp) || installedSomewhere;
    }

    return installedSomewhere;
  }
}
