// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_builder.dart';
import '../android/build_validation.dart';
import '../android/gradle_utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({
    required super.logger, bool verboseHelp = false
  }) : super(verboseHelp: verboseHelp) {
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
    addMultidexOption();
    addIgnoreDeprecationOption();
    argParser
      ..addFlag('split-per-abi',
        negatable: false,
        help: 'Whether to split the APKs per ABIs. '
              'To learn more, see: https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split',
      )
      ..addFlag('config-only',
          help: 'Generate build files used by flutter but '
                'do not build any artifacts.')
      ..addMultiOption('target-platform',
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the app is compiled.',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  @override
  final String name = 'apk';

  @override
  DeprecationBehavior get deprecationBehavior => boolArg('ignore-deprecation') ? DeprecationBehavior.ignore : DeprecationBehavior.exit;

  bool get configOnly => boolArg('config-only');

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  final String description = 'Build an Android APK file from your app.\n\n'
    "This command can build debug and release versions of your application. 'debug' builds support "
    "debugging and a quick development cycle. 'release' builds don't support debugging and are "
    'suitable for deploying to app stores. If you are deploying the app to the Play Store, '
    "it's recommended to use app bundles or split the APK to reduce the APK size. Learn more at:\n\n"
    ' * https://developer.android.com/guide/app-bundle\n'
    ' * https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split';

  @override
  Future<CustomDimensions> get usageValues async {
    String buildMode;

    if (boolArg('release')) {
      buildMode = 'release';
    } else if (boolArg('debug')) {
      buildMode = 'debug';
    } else if (boolArg('profile')) {
      buildMode = 'profile';
    } else {
      // The build defaults to release.
      buildMode = 'release';
    }

    return CustomDimensions(
      commandBuildApkTargetPlatform: stringsArg('target-platform').join(','),
      commandBuildApkBuildMode: buildMode,
      commandBuildApkSplitPerAbi: boolArg('split-per-abi'),
    );
  }

  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async {
    final String buildMode;

    if (boolArg('release')) {
      buildMode = 'release';
    } else if (boolArg('debug')) {
      buildMode = 'debug';
    } else if (boolArg('profile')) {
      buildMode = 'profile';
    } else {
      // The build defaults to release.
      buildMode = 'release';
    }

    return Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      buildApkTargetPlatform: stringsArg('target-platform').join(','),
      buildApkBuildMode: buildMode,
      buildApkSplitPerAbi: boolArg('split-per-abi'),
    );
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
      multidexEnabled: boolArg('multidex'),
    );
    validateBuild(androidBuildInfo);
    displayNullSafetyMode(androidBuildInfo.buildInfo);
    globals.terminal.usesTerminalUi = true;
    await androidBuilder?.buildApk(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
      configOnly: configOnly,
    );
    return FlutterCommandResult.success();
  }
}
