// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/build_validation.dart';
import '../android/gradle_utils.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/android_context.dart';
import '../context/tool_context.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({
    required AndroidBuilder? androidBuilder,
    required AndroidContext androidContext,
    required AndroidSdk? androidSdk,
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    bool verboseHelp = false,
  }) : _androidBuilder = androidBuilder,
       _androidContext = androidContext,
       _androidSdk = androidSdk,
       _buildSystem = buildSystem,
       _toolContext = toolContext,
       super(logger: toolContext.logger, toolContext: toolContext, verboseHelp: verboseHelp) {
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
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
    addAndroidSpecificBuildOptions(hide: !verboseHelp);
    addIgnoreDeprecationOption();
    addEnableHcppFlag(verboseHelp: verboseHelp);
    argParser
      ..addFlag(
        'split-per-abi',
        negatable: false,
        help:
            'Whether to split the APKs per ABIs. '
            'To learn more, see: https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split',
      )
      ..addFlag(
        'config-only',
        help:
            'Generate build files used by flutter but '
            'do not build any artifacts.',
      )
      ..addMultiOption(
        'target-platform',
        allowed: <String>['android-arm', 'android-arm64', 'android-x64'],
        help: 'The target platform for which the app is compiled.',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  final AndroidBuilder? _androidBuilder;
  final AndroidContext _androidContext;
  final AndroidSdk? _androidSdk;
  final BuildSystem _buildSystem;
  final ToolContext _toolContext;

  @visibleForTesting
  AndroidBuilder? get androidBuilder => _androidBuilder;

  @visibleForTesting
  AndroidContext get androidContext => _androidContext;

  @visibleForTesting
  AndroidSdk? get androidSdk => _androidSdk;

  @visibleForTesting
  BuildSystem get buildSystem => _buildSystem;

  BuildMode get _buildMode {
    if (boolArg('release')) {
      return BuildMode.release;
    } else if (boolArg('profile')) {
      return BuildMode.profile;
    } else if (boolArg('debug')) {
      return BuildMode.debug;
    } else if (boolArg('jit-release')) {
      return BuildMode.jitRelease;
    }
    return BuildMode.release;
  }

  static const _kDefaultJitArchs = <String>['android-arm', 'android-arm64', 'android-x64'];
  static const _kDefaultAotArchs = <String>['android-arm', 'android-arm64', 'android-x64'];
  List<String> get _targetArchs => stringsArg('target-platform').isEmpty
      ? switch (_buildMode) {
          BuildMode.release || BuildMode.profile => _kDefaultAotArchs,
          BuildMode.debug || BuildMode.jitRelease => _kDefaultJitArchs,
        }
      : stringsArg('target-platform');

  @override
  final name = 'apk';

  @override
  DeprecationBehavior get deprecationBehavior =>
      boolArg('ignore-deprecation') ? DeprecationBehavior.ignore : DeprecationBehavior.exit;

  bool get configOnly => boolArg('config-only');

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
      buildApkSplitPerAbi: boolArg('split-per-abi'),
      buildApkEnableHcpp:
          explicitEnableHcpp ?? project.android.computeHcppEnabled(ifAbsent: enableHcpp),
    );
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Logger logger = _toolContext.logger;
    final AnsiTerminal terminal = _toolContext.terminal;
    if (_androidSdk == null) {
      exitWithNoSdkMessage(analytics: analytics, logger: logger);
    }
    final BuildInfo buildInfo = await getBuildInfo();

    final androidBuildInfo = AndroidBuildInfo(
      buildInfo,
      splitPerAbi: boolArg('split-per-abi'),
      targetArchs: _targetArchs.map<CpuArch>(getCpuArchForName),
    );
    validateBuild(androidBuildInfo);
    terminal.usesTerminalUi = true;
    final FlutterProject project = this.project;
    await _androidBuilder?.buildApk(
      project: project,
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
      configOnly: configOnly,
    );

    final bool impellerEnabled = project.android.computeImpellerEnabled();
    final buildLabel = impellerEnabled ? 'manifest-impeller-enabled' : 'manifest-impeller-disabled';
    analytics.send(Event.flutterBuildInfo(label: buildLabel, buildType: 'android'));

    return FlutterCommandResult.success();
  }
}
