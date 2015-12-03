// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/logging.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import 'build.dart';
import 'install.dart';
import 'stop.dart';

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
    argParser.addFlag('trace-startup',
        negatable: true,
        defaultsTo: false,
        help: 'Start tracing during startup.');
    argParser.addOption('target',
        defaultsTo: '',
        abbr: 't',
        help: 'Target app path or filename to start.');
    argParser.addOption('route', help: 'Which route to load when starting the app.');
    argParser.addFlag('boot',
        help: 'Boot the iOS Simulator if it isn\'t already running.');
  }

  /// Given the value of the --target option, return the path of the Dart file
  /// where the app's main function should be.
  static String findMainDartFile(String target) {
    String targetPath = path.absolute(target);
    if (FileSystemEntity.isDirectorySync(targetPath)) {
      return path.join(targetPath, 'lib', 'main.dart');
    } else {
      return targetPath;
    }
  }

  @override
  Future<int> runInProject() async {
    logging.fine('downloading toolchain');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ]);

    bool poke = argResults['poke'];
    if (!poke) {
      logging.fine('running stop command');

      StopCommand stopper = new StopCommand();
      stopper.inheritFromParent(this);
      stopper.stop();

      logging.fine('running install command');

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
        String mainPath = findMainDartFile(argResults['target']);
        if (!FileSystemEntity.isFileSync(mainPath)) {
          String message = 'Tried to run $mainPath, but that file does not exist.';
          if (!argResults.wasParsed('target'))
            message += '\nConsider using the -t option to specify that Dart file to start.';
          stderr.writeln(message);
          continue;
        }

        logging.fine('running build command for $device');

        BuildCommand builder = new BuildCommand();
        builder.inheritFromParent(this);
        await builder.buildInTempDir(
          mainPath: mainPath,
          onBundleAvailable: (String localBundlePath) {
            logging.fine('running start bundle for $device');

            if (device.startBundle(package, localBundlePath,
                                   poke: poke,
                                   checked: argResults['checked'],
                                   traceStartup: argResults['trace-startup'],
                                   route: argResults['route']))
              startedSomething = true;
          }
        );
      } else {
        logging.fine('running start command for $device');

        if (await device.startApp(package))
          startedSomething = true;
      }
    }

    if (!startedSomething) {
      if (!devices.all.any((device) => device.isConnected())) {
        logging.severe('Unable to run application - no connected devices.');
      } else {
        logging.severe('Unable to run application.');
      }
    }

    logging.fine('finished start command');

    return startedSomething ? 0 : 2;
  }
}
