// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/mac.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host. For producing deployment
/// .ipas, see https://flutter.dev/docs/deployment/ios.
class BuildIOSCommand extends BuildSubCommand {
  BuildIOSCommand() {
    addBuildModeFlags(defaultToRelease: false);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    argParser
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
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.iOS,
  };

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool forSimulator = boolArg('simulator');
    defaultBuildMode = forSimulator ? BuildMode.debug : BuildMode.release;

    if (!globals.platform.isMacOS) {
      throwToolExit('Building for iOS is only supported on the Mac.');
    }

    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(TargetPlatform.ios) as BuildableIOSApp;

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }

    final bool shouldCodesign = boolArg('codesign');

    if (!forSimulator && !shouldCodesign) {
      globals.printStatus('Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.');
    }
    final BuildInfo buildInfo = getBuildInfo();
    if (forSimulator && !buildInfo.supportsSimulator) {
      throwToolExit('${toTitleCase(buildInfo.friendlyModeName)} mode is not supported for simulators.');
    }

    final String logTarget = forSimulator ? 'simulator' : 'device';

    final String typeName = globals.artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    globals.printStatus('Building $app for $logTarget ($typeName)...');
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

    if (result.output != null) {
      globals.printStatus('Built ${result.output}.');
    }

    return null;
  }
}
