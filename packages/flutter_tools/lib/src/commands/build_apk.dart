// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_builder.dart';
import '../android/build_validation.dart';
import '../android/gradle_utils.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({bool verboseHelp = false}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addShrinkingFlag();
    addSplitDebugInfoOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraFrontendOptions();
    addBundleSkSLPathOption(hide: !verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
    argParser
      ..addFlag('split-per-abi',
        negatable: false,
        help: 'Whether to split the APKs per ABIs. '
              'To learn more, see: https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split',
      )
      ..addMultiOption('target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the app is compiled.',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  @override
  final String name = 'apk';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  final String description = 'Build an Android APK file from your app.\n\n'
    "This command can build debug and release versions of your application. 'debug' builds support "
    "debugging and a quick development cycle. 'release' builds don't support debugging and are "
    'suitable for deploying to app stores.';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usage = <CustomDimensions, String>{};

    usage[CustomDimensions.commandBuildApkTargetPlatform] =
        stringsArg('target-platform').join(',');
    usage[CustomDimensions.commandBuildApkSplitPerAbi] =
        boolArg('split-per-abi').toString();

    if (boolArg('release')) {
      usage[CustomDimensions.commandBuildApkBuildMode] = 'release';
    } else if (boolArg('debug')) {
      usage[CustomDimensions.commandBuildApkBuildMode] = 'debug';
    } else if (boolArg('profile')) {
      usage[CustomDimensions.commandBuildApkBuildMode] = 'profile';
    } else {
      // The build defaults to release.
      usage[CustomDimensions.commandBuildApkBuildMode] = 'release';
    }
    return usage;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (globals.androidSdk == null) {
      exitWithNoSdkMessage();
    }
    final BuildInfo buildInfo = getBuildInfo();
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(
      buildInfo,
      splitPerAbi: boolArg('split-per-abi'),
      targetArchs: stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName),
      shrink: boolArg('shrink'),
    );
    validateBuild(androidBuildInfo);

    if (buildInfo.isRelease && !androidBuildInfo.splitPerAbi && androidBuildInfo.targetArchs.length > 1) {
      final String targetPlatforms = stringsArg('target-platform').join(', ');

      globals.printStatus('You are building a fat APK that includes binaries for '
                  '$targetPlatforms.', emphasis: true, color: TerminalColor.green);
      globals.printStatus('If you are deploying the app to the Play Store, '
                  "it's recommended to use app bundles or split the APK to reduce the APK size.", emphasis: true);
      globals.printStatus('To generate an app bundle, run:', emphasis: true, indent: 4);
      globals.printStatus('flutter build appbundle '
                  '--target-platform ${targetPlatforms.replaceAll(' ', '')}',indent: 8);
      globals.printStatus('Learn more on: https://developer.android.com/guide/app-bundle',indent: 8);
      globals.printStatus('To split the APKs per ABI, run:', emphasis: true, indent: 4);
      globals.printStatus('flutter build apk '
                  '--target-platform ${targetPlatforms.replaceAll(' ', '')} '
                  '--split-per-abi', indent: 8);
      globals.printStatus('Learn more on:  https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split',indent: 8);
    }
    await androidBuilder.buildApk(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
    );
    return FlutterCommandResult.success();
  }
}
