// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/mac.dart';
import 'build.dart';

class BuildIOSCommand extends BuildSubCommand {
  BuildIOSCommand() {
    usesTargetOption();
    argParser.addFlag('debug',
      negatable: false,
      help: 'Build a debug version of your app (default mode for iOS simulator builds).');
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.');
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a release version of your app (default mode for device builds).');
    argParser.addFlag('simulator', help: 'Build for the iOS simulator instead of the device.');
    argParser.addFlag('codesign', negatable: true, defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).');
  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

  @override
  Future<Null> runCommand() async {
    bool forSimulator = argResults['simulator'];
    defaultBuildMode = forSimulator ? BuildMode.debug : BuildMode.release;

    await super.runCommand();
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      throwToolExit('Building for iOS is only supported on the Mac.');

    IOSApp app = applicationPackages.getPackageForPlatform(TargetPlatform.ios);

    if (app == null)
      throwToolExit('Application not configured for iOS');

    bool shouldCodesign = argResults['codesign'];

    if (!forSimulator && !shouldCodesign) {
      printStatus('Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.');
    }

    if (forSimulator && !isEmulatorBuildMode(getBuildMode()))
      throwToolExit('${toTitleCase(getModeName(getBuildMode()))} mode is not supported for emulators.');

    String logTarget = forSimulator ? 'simulator' : 'device';

    String typeName = path.basename(tools.getEngineArtifactsDirectory(TargetPlatform.ios, getBuildMode()).path);
    Status status = logger.startProgress('Building $app for $logTarget ($typeName)...');
    XcodeBuildResult result = await buildXcodeProject(
      app: app,
      mode: getBuildMode(),
      target: targetFile,
      buildForDevice: !forSimulator,
      codesign: shouldCodesign
    );
    status.stop();

    if (!result.success) {
      printError('Encountered error while building for $logTarget.');
      diagnoseXcodeBuildFailure(result);
      throwToolExit('');
    }

    if (result.output != null)
      printStatus('Built ${result.output}.');
  }
}
