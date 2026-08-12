// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../bundle.dart';
import '../bundle_builder.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    required bool verboseHelp,
    super.analytics,
    BundleBuilder? bundleBuilder,
    FeatureFlags? featureFlags,
  }) : _buildSystem = buildSystem,
       _bundleBuilder = bundleBuilder ?? BundleBuilder(),
       _featureFlags = featureFlags ?? const _DefaultFeatureFlags(),
       _toolContext = toolContext,
       super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ) {
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    usesBuildNumberOption();
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false);
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    argParser
      ..addOption(
        'depfile',
        defaultsTo: defaultDepfilePath,
        help:
            'A file path where a depfile will be written. '
            'This contains all build inputs and outputs in a Make-style syntax.',
      )
      ..addOption(
        'target-platform',
        defaultsTo: 'android-arm',
        allowed: const <String>[
          'android-arm',
          'android-arm64',
          'android-x64',
          'ios',
          'darwin',
          'linux-x64',
          'linux-arm64',
          'linux-riscv64',
          'windows-x64',
          'windows-arm64',
        ],
        help: 'The architecture for which to build the application.',
      )
      ..addOption(
        'asset-dir',
        defaultsTo: getAssetBuildDirectory(toolContext.config, toolContext.fs),
        help:
            'The output directory for the kernel_blob.bin file, the native snapshot, the assets, etc. '
            'Can be used to redirect the output when driving the Flutter toolchain from another build system.',
      )
      ..addFlag(
        'tree-shake-icons',
        hide: !verboseHelp,
        help: '(deprecated) Icon font tree shaking is not supported by this command.',
      );
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  final BuildSystem _buildSystem;
  final BundleBuilder _bundleBuilder;
  final FeatureFlags _featureFlags;
  final ToolContext _toolContext;

  @visibleForTesting
  BuildSystem get buildSystem => _buildSystem;

  @visibleForTesting
  BundleBuilder get bundleBuilder => _bundleBuilder;

  @visibleForTesting
  FeatureFlags get featureFlags => _featureFlags;

  @visibleForTesting
  @override
  ToolContext get toolContext => _toolContext;

  @override
  final name = 'bundle';

  @override
  final description = 'Build the Flutter assets directory from your app.';

  @override
  final usageFooter =
      'The Flutter assets directory contains your '
      'application code and resources; they are used by some Flutter Android and'
      ' iOS runtimes.';

  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async {
    final FileSystem fs = _toolContext.fs;
    final FlutterProjectFactory projectFactory = _toolContext.projectFactory;
    final String projectDir = fs.file(targetFile).parent.parent.path;
    final FlutterProject flutterProject = projectFactory.fromDirectory(fs.directory(projectDir));
    return Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      buildBundleTargetPlatform: stringArg('target-platform'),
      buildBundleIsModule: flutterProject.isModule,
    );
  }

  @override
  Future<void> validateCommand() async {
    if (boolArg('tree-shake-icons')) {
      throwToolExit(
        'The "--tree-shake-icons" flag is deprecated for "build bundle" and will be removed in a future version of Flutter.',
      );
    }
    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = stringArg('target-platform')!;
    final platform = TargetPlatform.fromName(targetPlatform);
    // Check for target platforms that are only allowed via feature flags.
    switch (platform) {
      case TargetPlatform.darwin:
        if (!_featureFlags.isMacOSEnabled) {
          throwToolExit('macOS is not a supported target platform.');
        }
      case TargetPlatform.windows_x64:
      case TargetPlatform.windows_arm64:
        if (!_featureFlags.isWindowsEnabled) {
          throwToolExit('Windows is not a supported target platform.');
        }
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_riscv64:
        if (!_featureFlags.isLinuxEnabled) {
          throwToolExit('Linux is not a supported target platform.');
        }
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.ios:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
        break;
      case TargetPlatform.unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }

    final BuildInfo buildInfo = await getBuildInfo();

    await _bundleBuilder.build(
      platform: platform,
      buildInfo: buildInfo,
      mainPath: targetFile,
      depfilePath: stringArg('depfile'),
      assetDirPath: stringArg('asset-dir'),
      buildSystem: _buildSystem,
    );
    return FlutterCommandResult.success();
  }
}

class _DefaultFeatureFlags extends FeatureFlags {
  const _DefaultFeatureFlags();

  @override
  bool isEnabled(Feature feature) => false;
  @override
  bool get isLinuxEnabled => false;
  @override
  bool get isMacOSEnabled => false;
  @override
  bool get isWindowsEnabled => false;
  @override
  bool get isWebEnabled => false;
  @override
  bool get isAndroidEnabled => false;
  @override
  bool get isIOSEnabled => false;
  @override
  bool get isFuchsiaEnabled => false;
  @override
  bool get areCustomDevicesEnabled => false;
  @override
  bool get isCliAnimationEnabled => false;
  @override
  bool get isNativeAssetsEnabled => false;
  @override
  bool get isDartDataAssetsEnabled => false;
  @override
  bool get isRecordUseEnabled => false;
  @override
  bool get isSwiftPackageManagerEnabled => false;
  @override
  bool get isOmitLegacyVersionFileEnabled => false;
  @override
  bool get isWindowingEnabled => false;
  @override
  bool get isAccessibilityEvaluationsEnabled => false;
  @override
  bool get isLLDBDebuggingEnabled => false;
  @override
  bool get isUISceneMigrationEnabled => false;
  @override
  bool get isRiscv64SupportEnabled => false;
  @override
  bool get isMacOSArm64OnlyEnabled => false;
}
