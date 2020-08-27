// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/mac.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host. For producing deployment
/// .ipas, see https://flutter.dev/docs/deployment/ios.
class BuildIPaCommand extends BuildSubCommand {
  BuildIPaCommand({ @required bool verboseHelp }) {
    addTreeShakeIconsFlag();
    addSplitDebugInfoOption();
    addBuildModeFlags(defaultToRelease: true);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraFrontendOptions();
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
  }

  @override
  final String name = 'ipa';

  @override
  final String description = 'Build an IPA for iOS distribution (Mac OS X host only).';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.iOS,
  };

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!globals.platform.isMacOS) {
      throwToolExit('Building for iOS is only supported on the Mac.');
    }

    final BuildInfo buildInfo = getBuildInfo();
    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(
      TargetPlatform.ios,
      buildInfo,
    ) as BuildableIOSApp;

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }

    final String typeName = globals.artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    globals.printStatus('Building $app for generic iOS device ($typeName)...');
    final ParsedProjectInfo parsedProjectInfo = await valdateXcodeBuild(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: true,
      codesign: true,
    );
    int result = await buildXcodeArchive(
      parsedProjectInfo: parsedProjectInfo,
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: true,
      codesign: true,
    );
    if (result != 0) {
      throwToolExit('');
    }
    result = await buildXcodeIpa(
      parsedProjectInfo: parsedProjectInfo,
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: true,
      codesign: true,
    );

    if (result != 0) {
      throwToolExit('');
    }

    return FlutterCommandResult.success();
  }
}
