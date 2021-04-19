// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../android/android_builder.dart';
import '../android/build_validation.dart';
import '../android/gradle_utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals_null_migrated.dart' as globals;
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
    addShrinkingFlag(verboseHelp: verboseHelp);
    addSplitDebugInfoOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
    addAndroidSpecificBuildOptions(hide: !verboseHelp);
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
    'suitable for deploying to app stores. If you are deploying the app to the Play Store, '
    'it\'s recommended to use app bundles or split the APK to reduce the APK size. Learn more at:\n\n'
    ' * https://developer.android.com/guide/app-bundle\n'
    ' * https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split';

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
    final BuildInfo buildInfo = await getBuildInfo();
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(
      buildInfo,
      splitPerAbi: boolArg('split-per-abi'),
      targetArchs: stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName),
    );
    validateBuild(androidBuildInfo);
    displayNullSafetyMode(androidBuildInfo.buildInfo);
    await androidBuilder.buildApk(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
    );
    return FlutterCommandResult.success();
  }
}
