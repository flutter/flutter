// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../application_package.dart';
import '../base/logging.dart';
import '../base/process.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class ListenCommand extends FlutterCommand {
  final String name = 'listen';
  final String description = 'Listen for changes to files and reload the running app on all connected devices.';
  List<String> watchCommand;

  /// Only run once.  Used for testing.
  bool singleRun;

  ListenCommand({ this.singleRun: false }) {
    argParser.addFlag('checked',
        negatable: true,
        defaultsTo: true,
        help: 'Toggle Dart\'s checked mode.');
    argParser.addOption('target',
        defaultsTo: '.',
        abbr: 't',
        help: 'Target app path or filename to start.');
  }

  static const String _remoteFlutterBundle = 'Documents/app.flx';

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackagesAndConnectToDevices();
    await downloadToolchain();

    if (argResults.rest.length > 0) {
      watchCommand = _initWatchCommand(argResults.rest);
    } else {
      watchCommand = _initWatchCommand(['.']);
    }

    while (true) {
      logging.info('Updating running Flutter apps...');

      BuildCommand builder = new BuildCommand();
      builder.inheritFromParent(this);
      await builder.buildInTempDir(
        onBundleAvailable: (String localBundlePath) {
          for (Device device in devices.all) {
            ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
            if (package == null || !device.isConnected())
              continue;
            if (device is AndroidDevice) {
              device.startBundle(package, localBundlePath, poke: true, checked: argResults['checked']);
            } else if (device is IOSDevice) {
              device.pushFile(package, localBundlePath, _remoteFlutterBundle);
            } else if (device is IOSSimulator) {
              // TODO(abarth): Move pushFile up to Device once Android supports
              // pushing new bundles.
              device.pushFile(package, localBundlePath, _remoteFlutterBundle);
            } else {
              assert(false);
            }
          }
        }
      );

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
        logging.severe('"listen" command is only useful if you have installed '
            'fswatch on Mac.  Run "brew install fswatch" to install it with '
            'homebrew.');
        return null;
      }
      return ['fswatch', '-r', '-v', '-1']..addAll(directories);
    } else if (Platform.isLinux) {
      try {
        runCheckedSync(['which', 'inotifywait']);
      } catch (e) {
        logging.severe('"listen" command is only useful if you have installed '
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
      logging.severe('"listen" command is only available on Mac and Linux.');
    }
    return null;
  }

  bool watchDirectory() {
    if (watchCommand == null)
      return false;

    try {
      runCheckedSync(watchCommand);
    } catch (e) {
      logging.warning('Watching directories failed.', e);
      return false;
    }

    return true;
  }
}
