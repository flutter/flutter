// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.listen;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/device.dart';
import 'package:sky_tools/src/process.dart';

final Logger _logging = new Logger('sky_tools.listen');

class ListenCommand extends Command {
  final name = 'listen';
  final description = 'Listen for changes to files and reload the running app '
      'on all connected devices.';
  AndroidDevice android = null;
  List<String> watchCommand;

  /// Only run once.  Used for testing.
  bool singleRun;

  ListenCommand({this.android, this.singleRun: false}) {
    argParser.addFlag('checked',
        negatable: true,
        defaultsTo: true,
        help: 'Toggle Dart\'s checked mode.');
    argParser.addOption('target',
        defaultsTo: '.',
        abbr: 't',
        help: 'Target app path or filename to start.');

    if (android == null) {
      android = new AndroidDevice();
    }
  }

  @override
  Future<int> run() async {
    if (argResults.rest.length > 0) {
      watchCommand = _initWatchCommand(argResults.rest);
    } else {
      watchCommand = _initWatchCommand(['.']);
    }

    Map<BuildPlatform, ApplicationPackage> packages =
        ApplicationPackageFactory.getAvailableApplicationPackages();
    ApplicationPackage androidApp = packages[BuildPlatform.android];

    while (true) {
      _logging.info('Updating running Sky apps...');

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
