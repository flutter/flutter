// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.start;

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/device.dart';
import 'package:sky_tools/src/install.dart';
import 'package:sky_tools/src/stop.dart';

final Logger _logging = new Logger('sky_tools.start');

class StartCommand extends Command {
  final name = 'start';
  final description = 'Start your Flutter app on attached devices.';
  AndroidDevice android = null;

  StartCommand([this.android]) {
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

    bool startedSomewhere = false;
    bool poke = argResults['poke'];
    if (!poke) {
      StopCommand stopper = new StopCommand(android);
      stopper.stop();

      // Only install if the user did not specify a poke
      InstallCommand installer = new InstallCommand(android);
      startedSomewhere = installer.install();
    }

    bool startedOnAndroid = false;
    if (android.isConnected()) {
      Map<BuildPlatform, ApplicationPackage> packages =
          ApplicationPackageFactory.getAvailableApplicationPackages();
      ApplicationPackage androidApp = packages[BuildPlatform.android];

      String target = path.absolute(argResults['target']);
      startedOnAndroid = await android.startServer(
          target, poke, argResults['checked'], androidApp);
    }

    if (startedSomewhere || startedOnAndroid) {
      return 0;
    } else {
      return 2;
    }
  }
}
