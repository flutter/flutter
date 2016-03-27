// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../application_package.dart';
import '../build_configuration.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../runner/flutter_command.dart';

import 'package:path/path.dart' as path;

class BuildIOSCommand extends FlutterCommand {
  BuildIOSCommand() {
    argParser.addFlag('simulator', help: 'Build for the iOS simulator instead of the device');
  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OSX host only).';

  @override
  Future<int> runInProject() async {
    if (getCurrentHostPlatform() != HostPlatform.mac) {
      printError('Building for iOS is only supported on the Mac.');
      return 1;
    }

    printTrace('Ensuring toolchains are up to date.');

    await Future.wait([
      downloadToolchain(),
      downloadApplicationPackages(),
    ], eagerError: true);

    IOSApp app = applicationPackages.iOS;

    if (app == null) {
      printError('Application not configured for iOS');
      return 1;
    }

    bool forSimulator = argResults['simulator'];

    String logTarget = forSimulator ? "simulator" : "device";

    printStatus('Building the application for $logTarget.');

    Directory buildDir = new Directory(path.join('build', 'ios_$logTarget'));

    if (!buildDir.existsSync())
      await buildDir.create();

    bool result = await buildIOSXcodeProject(app,
        buildForDevice: !forSimulator, buildDirectory: buildDir);

    if (!result) {
      printError('Encountered error while building for $logTarget.');
      return 1;
    }

    printStatus('Built in ${buildDir.path}.');

    return 0;
  }
}
