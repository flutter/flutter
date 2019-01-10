// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildIOSCommand extends BuildSubCommand {
  BuildIOSCommand() {
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    argParser
      ..addFlag('debug',
        negatable: false,
        help: 'Build a debug version of your app (default mode for iOS simulator builds).',
      )
      ..addFlag('profile',
        negatable: false,
        help: 'Build a version of your app specialized for performance profiling.',
      )
      ..addFlag('release',
        negatable: false,
        help: 'Build a release version of your app (default mode for device builds).',
      )
      ..addFlag('simulator',
        help: 'Build for the iOS simulator instead of the device.',
      )
      ..addFlag('codesign',
        defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).',
      );
  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool forSimulator = argResults['simulator'];
    defaultBuildMode = forSimulator ? BuildMode.debug : BuildMode.release;

    await super.runCommand();
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      throwToolExit('Building for iOS is only supported on the Mac.');

    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(TargetPlatform.ios);

    if (app == null)
      throwToolExit('Application not configured for iOS');

    final bool shouldCodesign = argResults['codesign'];

    if (!forSimulator && !shouldCodesign) {
      printStatus('Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.');
    }
    final BuildInfo buildInfo = getBuildInfo();
    if (forSimulator && !buildInfo.supportsSimulator)
      throwToolExit('${toTitleCase(buildInfo.modeName)} mode is not supported for simulators.');

    final String logTarget = forSimulator ? 'simulator' : 'device';

    final String typeName = artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    printStatus('Building $app for $logTarget ($typeName)...');
    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: !forSimulator,
      codesign: shouldCodesign,
    );

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result);
      throwToolExit('Encountered error while building for $logTarget.');
    }

    if (result.output != null)
      printStatus('Built ${result.output}.');

    return null;
  }
}
