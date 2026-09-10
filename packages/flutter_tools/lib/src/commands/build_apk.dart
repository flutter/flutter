// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_builder.dart';
import '../android/build_validation.dart';
import '../android/gradle_utils.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({required super.logger, super.verboseHelp = false}) {
    registerOptionBundles(const <OptionBundle>[
      CommonBuildOptionsBundle(),
      BuildModeOptionsBundle(),
      DartCompileOptionsBundle(),
      AndroidBuildOptionsBundle(),
    ]);
    argParser.addDescriptors(const <OptionDescriptor<Object?>>[
      _splitPerAbi,
      _configOnly,
      _targetPlatform,
    ]);
  }

  static const _splitPerAbi = FlagOptionDescriptor(
    name: 'split-per-abi',
    negatable: false,
    help:
        'Whether to split the APKs per ABIs. '
        'To learn more, see: https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split',
  );

  static const _configOnly = FlagOptionDescriptor(
    name: 'config-only',
    help:
        'Generate build files used by flutter but '
        'do not build any artifacts.',
  );

  static const _targetPlatform = MultiOptionDescriptor(
    name: 'target-platform',
    allowed: <String>['android-arm', 'android-arm64', 'android-x64'],
    help: 'The target platform for which the app is compiled.',
  );

  BuildMode get _buildMode {
    if (getValue(CommonOptions.releaseMode)) {
      return BuildMode.release;
    } else if (getValue(CommonOptions.profileMode)) {
      return BuildMode.profile;
    } else if (getValue(CommonOptions.debugMode)) {
      return BuildMode.debug;
    } else if (getValue(CommonOptions.jitReleaseMode)) {
      return BuildMode.jitRelease;
    }
    return BuildMode.release;
  }

  static const _kDefaultJitArchs = <String>['android-arm', 'android-arm64', 'android-x64'];
  static const _kDefaultAotArchs = <String>['android-arm', 'android-arm64', 'android-x64'];
  List<String> get _targetArchs {
    final List<String> targetPlatform = getValue(_targetPlatform);
    return targetPlatform.isEmpty
        ? switch (_buildMode) {
            BuildMode.release || BuildMode.profile => _kDefaultAotArchs,
            BuildMode.debug || BuildMode.jitRelease => _kDefaultJitArchs,
          }
        : targetPlatform;
  }

  @override
  final name = 'apk';

  @override
  DeprecationBehavior get deprecationBehavior => getValue(BuildInfoOptions.ignoreDeprecation)
      ? DeprecationBehavior.ignore
      : DeprecationBehavior.exit;

  bool get configOnly => getValue(_configOnly);

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  final description =
      'Build an Android APK file from your app.\n\n'
      "This command can build debug and release versions of your application. 'debug' builds support "
      "debugging and a quick development cycle. 'release' builds don't support debugging and are "
      'suitable for deploying to app stores. If you are deploying the app to the Play Store, '
      "it's recommended to use app bundles or split the APK to reduce the APK size. Learn more at:\n\n"
      ' * https://developer.android.com/guide/app-bundle\n'
      ' * https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split';

  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async {
    return Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      buildApkTargetPlatform: _targetArchs.join(','),
      buildApkBuildMode: _buildMode.cliName,
      buildApkSplitPerAbi: getValue(_splitPerAbi),
      buildApkEnableHcpp:
          explicitEnableHcpp ?? project.android.computeHcppEnabled(ifAbsent: enableHcpp),
    );
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (globals.androidSdk == null) {
      exitWithNoSdkMessage();
    }
    final BuildInfo buildInfo = await getBuildInfo();

    final androidBuildInfo = AndroidBuildInfo(
      buildInfo,
      splitPerAbi: getValue(_splitPerAbi),
      targetArchs: _targetArchs.map<CpuArch>(getCpuArchForName),
    );
    validateBuild(androidBuildInfo);
    globals.terminal.usesTerminalUi = true;
    await androidBuilder?.buildApk(
      project: project,
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
      configOnly: configOnly,
    );

    final bool impellerEnabled = project.android.computeImpellerEnabled();
    final buildLabel = impellerEnabled ? 'manifest-impeller-enabled' : 'manifest-impeller-disabled';
    globals.analytics.send(Event.flutterBuildInfo(label: buildLabel, buildType: 'android'));

    return FlutterCommandResult.success();
  }
}
