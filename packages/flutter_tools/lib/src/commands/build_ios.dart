// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/logger.dart';
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
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

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
      printStatus('Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.');
    }

    String logTarget = forSimulator ? 'simulator' : 'device';

    String typeName = path.basename(tools.getEngineArtifactsDirectory(TargetPlatform.ios, getBuildMode()).path);
    Status status = logger.startProgress('Building $app for $logTarget ($typeName)...');
    XcodeBuildResult result = await buildXcodeProject(app, getBuildMode(),
        buildForDevice: !forSimulator,
        codesign: shouldCodesign);
    status.stop(showElapsedTime: true);

    if (!result.success) {
      printError('Encountered error while building for $logTarget.');
      return 1;
    }

    if (result.output != null)
      printStatus('Built ${result.output}.');

    return 0;
  }
}
