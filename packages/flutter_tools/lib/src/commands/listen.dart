// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'flutter_command.dart';
import '../application_package.dart';
import '../device.dart';
import '../process.dart';

final Logger _logging = new Logger('sky_tools.listen');

class ListenCommand extends FlutterCommand {
  final String name = 'listen';
  final String description = 'Listen for changes to files and reload the running app on all connected devices.';
  List<String> watchCommand;

  /// Only run once.  Used for testing.
  bool singleRun;

  ListenCommand({ this.singleRun: false });

  @override
  Future<int> run() async {
    await downloadApplicationPackagesAndConnectToDevices();

    if (argResults.rest.length > 0) {
      watchCommand = _initWatchCommand(argResults.rest);
    } else {
      watchCommand = _initWatchCommand(['.']);
    }

    while (true) {
      _logging.info('Updating running Flutter apps...');

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
                '/out/ios_sim_Debug/clang_x64/sky_snapshot'
          ]);
        }
      } catch (e) {}
      runSync(command);

      String localFlutterBundle = 'app.flx';
      String remoteFlutterBundle = 'Documents/app.flx';

      for (Device device in devices.all) {
        ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
        if (package == null || !device.isConnected())
          continue;
        if (device is AndroidDevice) {
          await devices.android.startServer(
              argResults['target'], true, argResults['checked'], package);
        } else if (device is IOSDevice) {
          device.pushFile(package, localFlutterBundle, remoteFlutterBundle);
        } else if (device is IOSSimulator) {
          // TODO(abarth): Move pushFile up to Device once Android supports
          // pushing new bundles.
          device.pushFile(package, localFlutterBundle, remoteFlutterBundle);
        } else {
          assert(false);
        }
      }

      if (singleRun || !watchDirectory())
        break;
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
    if (watchCommand == null)
      return false;

    try {
      runCheckedSync(watchCommand);
    } catch (e) {
      _logging.warning('Watching directories failed.', e);
      return false;
    }

    return true;
  }
}
