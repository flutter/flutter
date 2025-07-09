// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive_io.dart';
import 'package:file/src/interface/directory.dart';
import 'package:file/src/interface/file.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_builder.dart';
import '../android/build_validation.dart';
import '../android/gradle.dart';
import '../android/gradle_utils.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({
    required super.logger,
    bool verboseHelp = false,
    required ProcessManager processManager,
  }) : _processUtils = ProcessUtils(logger: logger, processManager: processManager),
       super(verboseHelp: verboseHelp) {
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
      ..addFlag(
        'from-app-bundle',
        help:
            'Generates an APK from an app bundle.',
      )
      ..addMultiOption(
        'target-platform',
        allowed: <String>['android-arm', 'android-arm64', 'android-x64'],
        help: 'The target platform for which the app is compiled.',
      );
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

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

  static const List<String> _kDefaultJitArchs = <String>[
    'android-arm',
    'android-arm64',
    'android-x64',
  ];
  static const List<String> _kDefaultAotArchs = <String>[
    'android-arm',
    'android-arm64',
    'android-x64',
  ];

  List<String> get _targetArchs => stringsArg('target-platform').isEmpty
      ? switch (_buildMode) {
          BuildMode.release || BuildMode.profile => _kDefaultAotArchs,
          BuildMode.debug || BuildMode.jitRelease => _kDefaultJitArchs,
        }
      : stringsArg('target-platform');

  @override
  final String name = 'apk';

  @override
  DeprecationBehavior get deprecationBehavior =>
      boolArg('ignore-deprecation') ? DeprecationBehavior.ignore : DeprecationBehavior.exit;

  bool get configOnly => boolArg('config-only');

  bool get fromAppBundle => boolArg('from-app-bundle');

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  final String description =
      'Build an Android APK file from your app.\n\n'
      "This command can build debug and release versions of your application. 'debug' builds support "
      "debugging and a quick development cycle. 'release' builds don't support debugging and are "
      'suitable for deploying to app stores. If you are deploying the app to the Play Store, '
      "it's recommended to use app bundles or split the APK to reduce the APK size. Learn more at:\n\n"
      ' * https://developer.android.com/guide/app-bundle\n'
      ' * https://developer.android.com/studio/build/configure-apk-splits#configure-abi-split';

  final ProcessUtils _processUtils;

  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async {
    return Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      buildApkTargetPlatform: _targetArchs.join(','),
      buildApkBuildMode: _buildMode.cliName,
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
      targetArchs: _targetArchs.map<AndroidArch>(getAndroidArchForName),
    );
    validateBuild(androidBuildInfo);
    globals.terminal.usesTerminalUi = true;
    final FlutterProject project = FlutterProject.current();
    if (!fromAppBundle) {
      await androidBuilder?.buildApk(
        project: project,
        target: targetFile,
        androidBuildInfo: androidBuildInfo,
        configOnly: configOnly,
      );
    } else {
      final AndroidBuilder? androidGradleBuilder = androidBuilder;
      if (androidGradleBuilder is! AndroidGradleBuilder) {
        logger.printError('androidBuilder is not an AndroidGradleBuilder');
        return FlutterCommandResult.fail();
      }

      await androidBuilder?.buildAab(
        project: project,
        target: targetFile,
        androidBuildInfo: androidBuildInfo,

        // These two values are hardcoded to false, but in `build_appbundle.dart` this is
        // configured by three different arguments. We might need to consider adding these
        // as new argument options if we choose to make the changes inside `build_apk.dart`
        // instead of `build_appbundle.dart`. Otherwise if the code was in
        // `build_appbundle.dart` we would only need the `config` flag.
        // - validateDeferredComponents: boolArg('validate-deferred-components'),
        // - deferredComponentsEnabled: boolArg('deferred-components') && !boolArg('debug'),
        validateDeferredComponents: false,
        deferredComponentsEnabled: false,
      );
      final File bundleFile = findBundleFile(project, buildInfo, logger, analytics);
      final Directory bundleDir = bundleFile.parent;
      final String apksOutput = bundleDir.childFile('app-${_buildMode.cliName}.apks').path;

      // Whether or not we use universal could be determined by split-per-abi flag.
      // As a proof of concept, we are assuming split-per-abi is false.
      // A single APK is generated when split-per-abi is false.
      final File expectedApkFile = androidGradleBuilder
          .findExpectedFilesForApk(androidBuildInfo, project)
          .first;
      const String universalApkName = 'universal.apk';

      _processUtils.runSync(
        <String>[
          'bundletool',
          'build-apks',
          '--overwrite',
          '--local-testing',
          '--mode',
          'universal',
          '--bundle',
          bundleFile.path,
          '--output',
          apksOutput,
        ],
        throwOnError: true,
        verboseExceptions: true,
      );

      final List<int> bytes = globals.fs.file(apksOutput).readAsBytesSync();
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      for (final ArchiveFile file in archive) {
        if (file.name == universalApkName) {
          if (!expectedApkFile.parent.existsSync()) {
            expectedApkFile.parent.createSync(recursive: true);
          }
          expectedApkFile.writeAsBytesSync(file.content as List<int>);
        }
      }

      await androidGradleBuilder.calculateShaAndProcessApks(project, androidBuildInfo);
    }

    // When an app is successfully built, record to analytics whether Impeller
    // is enabled or disabled. Note that 'computeImpellerEnabled' will default
    // to false if not enabled explicitly in the manifest.
    final bool impellerEnabled = project.android.computeImpellerEnabled();
    final String buildLabel = impellerEnabled
        ? 'manifest-impeller-enabled'
        : 'manifest-impeller-disabled';
    globals.analytics.send(Event.flutterBuildInfo(label: buildLabel, buildType: 'android'));

    return FlutterCommandResult.success();
  }
}
