// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../device.dart';
import 'build.dart';
import 'flutter_command.dart';
import 'install.dart';
import 'stop.dart';

final Logger _logging = new Logger('sky_tools.start');
const String _localBundleName = 'app.flx';
const String _localSnapshotName = 'snapshot_blob.bin';

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
    argParser.addFlag('http',
        negatable: true,
        help: 'Use a local HTTP server to serve your app to your device.');
    argParser.addFlag('boot',
        help: 'Boot the iOS Simulator if it isn\'t already running.');
  }

  @override
  Future<int> runInProject() async {
    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackagesAndConnectToDevices(),
    ]);

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
        if (argResults['http']) {
          if (await device.startServer(target, poke, argResults['checked'], package))
            startedSomething = true;
        } else {
          String mainPath = target;
          if (FileSystemEntity.isDirectorySync(target))
            mainPath = path.join(target, 'lib', 'main.dart');
          BuildCommand builder = new BuildCommand();
          builder.inheritFromParent(this);

          Directory tempDir = await Directory.systemTemp.createTemp('flutter_tools');
          try {
            String localBundlePath = path.join(tempDir.path, _localBundleName);
            String localSnapshotPath = path.join(tempDir.path, _localSnapshotName);
            await builder.build(
              snapshotPath: localSnapshotPath,
              outputPath: localBundlePath,
              mainPath: mainPath);
            if (device.startBundle(package, localBundlePath, poke, argResults['checked']))
              startedSomething = true;
          } finally {
            tempDir.deleteSync(recursive: true);
          }
        }
      } else {
        if (await device.startApp(package))
          startedSomething = true;
      }
    }

    if (!startedSomething) {
      if (!devices.all.any((device) => device.isConnected())) {
        _logging.severe('Unable to run application - no connected devices.');
      } else {
        _logging.severe('Unable to run application.');
      }
    }

    return startedSomething ? 0 : 2;
  }
}
