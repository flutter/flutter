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

// We don't yet support iOS here. https://github.com/flutter/flutter/issues/1036

abstract class StartCommandBase extends FlutterCommand {
  StartCommandBase() {
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
    argParser.addOption('route',
        help: 'Which route to load when starting the app.');
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

  Future<int> startApp({ bool stop: true, bool install: true, bool poke: false }) async {

    String mainPath = findMainDartFile(argResults['target']);
    if (!FileSystemEntity.isFileSync(mainPath)) {
      String message = 'Tried to run $mainPath, but that file does not exist.';
      if (!argResults.wasParsed('target'))
        message += '\nConsider using the -t option to specify that Dart file to start.';
      logging.severe(message);
      return 1;
    }

    if (stop) {
      logging.fine('Running stop command.');
      StopCommand stopper = new StopCommand();
      stopper.inheritFromParent(this);
      stopper.stop();
    }
 
    if (install) {
      logging.fine('Running install command.');
      InstallCommand installer = new InstallCommand();
      installer.inheritFromParent(this);
      installer.install();
    }

    bool startedSomething = false;

    for (Device device in devices.all) {
      ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
      if (package == null || !device.isConnected())
        continue;

      logging.fine('Running build command for $device.');
      BuildCommand builder = new BuildCommand();
      builder.inheritFromParent(this);
      await builder.buildInTempDir(
        mainPath: mainPath,
        onBundleAvailable: (String localBundlePath) {
          logging.fine('Starting bundle for $device.');
          final AndroidDevice androidDevice = device; // https://github.com/flutter/flutter/issues/1035
          if (androidDevice.startBundle(package, localBundlePath,
                                        poke: poke,
                                        checked: argResults['checked'],
                                        traceStartup: argResults['trace-startup'],
                                        route: argResults['route']))
            startedSomething = true;
        }
      );
    }

    if (!startedSomething) {
      if (!devices.all.any((device) => device.isConnected())) {
        logging.severe('Unable to run application - no connected devices.');
      } else {
        logging.severe('Unable to run application.');
      }
    }

    return startedSomething ? 0 : 2;
  }
}

class StartCommand extends StartCommandBase {
  final String name = 'start';
  final String description = 'Start your Flutter app on attached devices. (Android only.)';

  StartCommand() {
    argParser.addFlag('poke',
        negatable: false,
        help: 'Restart the connection to the server.');
  }

  @override
  Future<int> runInProject() async {
    logging.fine('Downloading toolchain.');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ]);

    bool poke = argResults['poke'];

    // Only stop and reinstall if the user did not specify a poke
    int result = await startApp(stop: !poke, install: !poke, poke: poke);

    logging.fine('Finished start command.');
    return result;
  }
}
