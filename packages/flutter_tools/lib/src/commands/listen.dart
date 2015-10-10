// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.listen;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../application_package.dart';
import '../device.dart';
import '../process.dart';

final Logger _logging = new Logger('sky_tools.listen');

class ListenCommand extends Command {
  final name = 'listen';
  final description = 'Listen for changes to files and reload the running app '
      'on all connected devices.';
  AndroidDevice android;
  IOSDevice ios;
  List<String> watchCommand;

  /// Only run once.  Used for testing.
  bool singleRun;

  ListenCommand({this.android, this.ios, this.singleRun: false}) {}

  @override
  Future<int> run() async {
    if (android == null) {
      android = new AndroidDevice();
    }

    if (ios == null) {
      ios = new IOSDevice();
    }

    if (argResults.rest.length > 0) {
      watchCommand = _initWatchCommand(argResults.rest);
    } else {
      watchCommand = _initWatchCommand(['.']);
    }

    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();
    ApplicationPackage androidApp = packages[BuildPlatform.android];
    ApplicationPackage iosApp = packages[BuildPlatform.iOS];

    while (true) {
      _logging.info('Updating running Sky apps...');

      // TODO(iansf): refactor build command so that this doesn't have
      //              to call out like this.
      List<String> command = ['pub', 'run', 'sky_tools', 'build',];

      try {
        // In testing, sky-src-path isn't added to the options, and
        // the ArgParser module throws an exception, so we have to
        // catch and ignore the error in order to test.
        if (globalResults.wasParsed('sky-src-path')) {
          command.addAll([
            // TODO(iansf): Don't rely on sky-src-path for the snapshotter.
            '--compiler',
            '${globalResults['sky-src-path']}'
                '/out/ios_Debug/clang_x64/sky_snapshot'
          ]);
        }
      } catch (e) {}
      runSync(command);

      String localFLXPath = 'app.flx';
      String remoteFLXPath = 'Documents/app.flx';

      if (ios.isConnected()) {
        await ios.pushFile(iosApp, localFLXPath, remoteFLXPath);
      }

      if (android.isConnected()) {
        await android.startServer(
            argResults['target'], true, argResults['checked'], androidApp);
      }

      if (singleRun || !watchDirectory()) {
        break;
      }
    }

    return 0;
  }

  List<String> _initWatchCommand(List<String> directories) {
    if (Platform.isMacOS) {
      try {
        runCheckedSync(['which', 'fswatch']);
      } catch (e) {
        _logging.severe('"listen" command is only useful if you have installed '
            'fswatch on Mac.  Run "brew install fswatch" to install it with '
            'homebrew.');
        return null;
      }
      return ['fswatch', '-r', '-v', '-1']..addAll(directories);
    } else if (Platform.isLinux) {
      try {
        runCheckedSync(['which', 'inotifywait']);
      } catch (e) {
        _logging.severe('"listen" command is only useful if you have installed '
            'inotifywait on Linux.  Run "apt-get install inotify-tools" or '
            'equivalent to install it.');
        return null;
      }
      return [
        'inotifywait',
        '-r',
        '-e',
        // Only listen for events that matter, to avoid triggering constantly
        // from the editor watching files
        'modify,close_write,move,create,delete',
      ]..addAll(directories);
    } else {
      _logging.severe('"listen" command is only available on Mac and Linux.');
    }
    return null;
  }

  bool watchDirectory() {
    if (watchCommand == null) {
      return false;
    }

    try {
      runCheckedSync(watchCommand);
    } catch (e) {
      _logging.warning('Watching directories failed.', e);
      return false;
    }
    return true;
  }
}
