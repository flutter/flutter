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
import '../linux/build_linux.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a linux desktop target through a build shell script.
class BuildLinuxCommand extends BuildSubCommand {
  BuildLinuxCommand({
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    required bool verboseHelp,
    super.analytics,
    FeatureFlags? featureFlags,
    OperatingSystemUtils? operatingSystemUtils,
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
    final OperatingSystemUtils os = _operatingSystemUtils ?? toolContext.os;
    final String defaultTargetPlatform = switch (os.hostPlatform) {
      HostPlatform.linux_arm64 => 'linux-arm64',
      HostPlatform.linux_riscv64 => 'linux-riscv64',
      _ => 'linux-x64',
    };
    argParser.addOption(
      'target-platform',
      defaultsTo: defaultTargetPlatform,
      allowed: <String>['linux-arm64', 'linux-x64', 'linux-riscv64'],
      help: 'The target platform for which the app is compiled.',
    );
    argParser.addOption(
      'target-sysroot',
      defaultsTo: '/',
      help:
          'The root filesystem path of target platform for which '
          'the app is compiled. This option is valid only '
          'if the current host and target architectures are different.',
    );
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
  final name = 'linux';

  @override
  bool get hidden => !_featureFlags.isLinuxEnabled || !_toolContext.platform.isLinux;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.linux,
  };

  @override
  String get description => 'Build a Linux desktop application.';

  bool get configOnly => boolArg('config-only');

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = _toolContext.fs;
    final Logger logger = this.logger;
    final OperatingSystemUtils os = _operatingSystemUtils ?? _toolContext.os;
    final Platform platform = _toolContext.platform;

    final BuildInfo buildInfo = await getBuildInfo();
    final targetPlatform = TargetPlatform.fromName(stringArg('target-platform')!);
    final needCrossBuild = os.hostPlatform.platformName != targetPlatform.simpleName;

    if (!_featureFlags.isLinuxEnabled) {
      throwToolExit(
        '"build linux" is not currently supported. To enable, run "flutter config --enable-linux-desktop".',
      );
    }
    if (!platform.isLinux) {
      throwToolExit('"build linux" only supported on Linux hosts.');
    }
    // Cross-building is only supported on x64 hosts
    if (os.hostPlatform != HostPlatform.linux_x64 && needCrossBuild) {
      throwToolExit('"cross-building" only supported on Linux x64 hosts.');
    }
    // TODO(fujino): https://github.com/flutter/flutter/issues/74929
    if (os.hostPlatform == HostPlatform.linux_x64 && targetPlatform == TargetPlatform.linux_arm64) {
      throwToolExit(
        'Cross-build from Linux x64 host to Linux arm64 target is not currently supported.',
      );
    }
    // Building for riscv64 (on a non-riscv64 host) is experimental
    if (os.hostPlatform != HostPlatform.linux_riscv64 &&
        targetPlatform == TargetPlatform.linux_riscv64 &&
        !_featureFlags.isRiscv64SupportEnabled) {
      throwToolExit(
        'Building for Linux riscv64 is currently an experimental feature. To enable, run "flutter config --enable-riscv64"',
      );
    }
    await buildLinux(
      project.linux,
      buildInfo,
      target: targetFile,
      sizeAnalyzer: SizeAnalyzer(fileSystem: fs, logger: logger, analytics: analytics),
      needCrossBuild: needCrossBuild,
      targetPlatform: targetPlatform,
      targetSysroot: stringArg('target-sysroot')!,
      logger: logger,
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
