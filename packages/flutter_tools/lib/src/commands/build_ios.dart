// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../runner/flutter_command.dart';

class BuildIOSCommand extends FlutterCommand {
  BuildIOSCommand() {
    addBuildModeFlags();
    argParser.addFlag('simulator', help: 'Build for the iOS simulator instead of the device.');
    argParser.addFlag('codesign', negatable: true, defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).');
  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OSX host only).';

  @override
  Future<int> runInProject() async {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64) {
      printError('Building for iOS is only supported on the Mac.');
      return 1;
    }

    IOSApp app = applicationPackages.getPackageForPlatform(TargetPlatform.ios);

    if (app == null) {
      printError('Application not configured for iOS');
      return 1;
    }

    bool forSimulator = argResults['simulator'];
    bool shouldCodesign = argResults['codesign'];

    if (!forSimulator && !shouldCodesign) {
      printStatus('Warning: Building for device with codesigning disabled.');
      printStatus('You will have to manually codesign before deploying to device.');
    }

    String logTarget = forSimulator ? "simulator" : "device";

    printStatus('Building $app for $logTarget...');

    bool result = await buildIOSXcodeProject(app, getBuildMode(),
        buildForDevice: !forSimulator,
        codesign: shouldCodesign);

    if (!result) {
      printError('Encountered error while building for $logTarget.');
      return 1;
    }

    printStatus('Built in ios/.generated.');

    return 0;
  }
}
