// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.start;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../device.dart';
import 'install.dart';
import 'stop.dart';

final Logger _logging = new Logger('sky_tools.start');

class StartCommand extends Command {
  final name = 'start';
  final description = 'Start your Flutter app on attached devices.';
  AndroidDevice android = null;
  IOSDevice ios = null;

  StartCommand({this.android, this.ios}) {
    argParser.addFlag('poke',
        negatable: false,
        help: 'Restart the connection to the server (Android only).');
    argParser.addFlag('checked',
        negatable: true,
        defaultsTo: true,
        help: 'Toggle Dart\'s checked mode.');
    argParser.addOption('target',
        defaultsTo: '.',
        abbr: 't',
        help: 'Target app path or filename to start.');
  }

  @override
  Future<int> run() async {
    if (android == null) {
      android = new AndroidDevice();
    }
    if (ios == null) {
      ios = new IOSDevice();
    }

    bool startedSomewhere = false;
    bool poke = argResults['poke'];
    if (!poke) {
      StopCommand stopper = new StopCommand(android: android, ios: ios);
      stopper.stop();

      // Only install if the user did not specify a poke
      InstallCommand installer = new InstallCommand(android: android, ios: ios);
      installer.install();
    }

    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();

    bool startedOnAndroid = false;
    if (android.isConnected()) {
      ApplicationPackage androidApp = packages[BuildPlatform.android];

      String target = path.absolute(argResults['target']);
      startedOnAndroid = await android.startServer(
          target, poke, argResults['checked'], androidApp);
    }

    if (ios.isConnected()) {
      ApplicationPackage iosApp = packages[BuildPlatform.iOS];

      startedSomewhere = await ios.startApp(iosApp) || startedSomewhere;
    }

    if (startedSomewhere || startedOnAndroid) {
      return 0;
    } else {
      return 2;
    }
  }
}
