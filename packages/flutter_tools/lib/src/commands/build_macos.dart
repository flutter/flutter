// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../globals.dart';
import '../ios/mac.dart';
import '../macos/application_package.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildMacOSCommand extends BuildSubCommand {
  BuildMacOSCommand() {
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
  final String name = 'macos';

  @override
  final String description = 'Build a macOS application bundle (Mac OS X host only).';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64) {
      throwToolExit('Building for macOS is only supported on the Mac.');
    }

    final BuildableMacOSApp app = await applicationPackages.getPackageForPlatform(TargetPlatform.darwin_x64);

    if (app == null) {
      throwToolExit('Application not configured for macOS');
    }

    final BuildInfo buildInfo = getBuildInfo();
    final String typeName = artifacts.getEngineType(TargetPlatform.darwin_x64, buildInfo.mode);
    printStatus('Building $app for device ($typeName)...');
    final XcodeBuildResult result = await buildMacOSXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: false,
    );

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result);
      throwToolExit('Encountered error while building for device.');
    }

    if (result.output != null)
      printStatus('Built ${result.output}.');

    return null;
  }
}
