// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../windows/build_windows.dart';
import '../windows/visual_studio.dart';
import 'build.dart';

/// A command to build a windows desktop target through a build shell script.
class BuildWindowsCommand extends BuildSubCommand {
  BuildWindowsCommand({
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    required bool verboseHelp,
    super.analytics,
    FeatureFlags? featureFlags,
    OperatingSystemUtils? operatingSystemUtils,
    this.visualStudioOverride,
  }) : _buildSystem = buildSystem,
       _featureFlags = featureFlags ?? const _DefaultFeatureFlags(),
       _operatingSystemUtils = operatingSystemUtils,
       _toolContext = toolContext,
       super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
    usesFlavorOption();
    argParser.addFlag(
      'config-only',
      help: 'Update the project configuration without performing a build.',
    );
  }

  final BuildSystem _buildSystem;
  final FeatureFlags _featureFlags;
  final OperatingSystemUtils? _operatingSystemUtils;
  final ToolContext _toolContext;

  @visibleForTesting
  BuildSystem get buildSystem => _buildSystem;

  @visibleForTesting
  FeatureFlags get featureFlags => _featureFlags;

  @visibleForTesting
  @override
  ToolContext get toolContext => _toolContext;

  @override
  final name = 'windows';

  @override
  bool get hidden => !_featureFlags.isWindowsEnabled || !_toolContext.platform.isWindows;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.windows,
  };

  @override
  String get description => 'Build a Windows desktop application.';

  @visibleForTesting
  VisualStudio? visualStudioOverride;

  bool get configOnly => boolArg('config-only');

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = _toolContext.fs;
    final Logger logger = this.logger;
    final OperatingSystemUtils os = _operatingSystemUtils ?? _toolContext.os;
    final Platform platform = _toolContext.platform;

    final BuildInfo buildInfo = await getBuildInfo();
    if (!_featureFlags.isWindowsEnabled) {
      throwToolExit(
        '"build windows" is not currently supported. To enable, run "flutter config --enable-windows-desktop".',
      );
    }
    if (!platform.isWindows) {
      throwToolExit('"build windows" only supported on Windows hosts.');
    }

    final defaultTargetPlatform = (os.hostPlatform == HostPlatform.windows_arm64)
        ? 'windows-arm64'
        : 'windows-x64';
    final targetPlatform = TargetPlatform.fromName(defaultTargetPlatform);

    await buildWindows(
      project.windows,
      buildInfo,
      targetPlatform,
      target: targetFile,
      visualStudioOverride: visualStudioOverride,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: fs,
        logger: logger,
        appFilenamePattern: 'app.so',
        analytics: analytics,
      ),
      cache: _toolContext.cache,
      configOnly: configOnly,
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
