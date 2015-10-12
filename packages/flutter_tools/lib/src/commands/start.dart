// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../device.dart';
import 'flutter_command.dart';
import 'install.dart';
import 'stop.dart';

final Logger _logging = new Logger('sky_tools.start');

class StartCommand extends FlutterCommand {
  final String name = 'start';
  final String description = 'Start your Flutter app on attached devices.';

  StartCommand() {
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
    argParser.addFlag('boot',
        help: 'Boot the iOS Simulator if it isn\'t already running.');
  }

  @override
  Future<int> run() async {
    await downloadApplicationPackagesAndConnectToDevices();

    bool poke = argResults['poke'];
    if (!poke) {
      StopCommand stopper = new StopCommand();
      stopper.inheritFromParent(this);
      stopper.stop();

      // Only install if the user did not specify a poke
      InstallCommand installer = new InstallCommand();
      installer.inheritFromParent(this);
      installer.install(boot: argResults['boot']);
    }

    bool startedSomething = false;

    for (Device device in devices.all) {
      ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
      if (package == null || !device.isConnected())
        continue;
      if (device is AndroidDevice) {
        String target = path.absolute(argResults['target']);
        if (await device.startServer(target, poke, argResults['checked'], package))
          startedSomething = true;
      } else {
        if (await device.startApp(package))
          startedSomething = true;
      }
    }

    return startedSomething ? 0 : 2;
  }
}
