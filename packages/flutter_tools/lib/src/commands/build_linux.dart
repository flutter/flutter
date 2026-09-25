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
import '../context/tool_context.dart';
import '../features.dart';
import '../linux/build_linux.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

/// A command to build a linux desktop target through a build shell script.
class BuildLinuxCommand extends BuildSubCommand {
  BuildLinuxCommand({
    required this.buildSystem,
    required ToolContext super.toolContext,
    required super.verboseHelp,
    required this._featureFlags,
  }) : super(logger: toolContext.logger, outputPreferences: toolContext.outputPreferences) {
    final OperatingSystemUtils os = toolContext.os;
    final TargetPlatform defaultTargetPlatform = switch (os.hostPlatform) {
      HostPlatform.linux_arm64 => TargetPlatform.linux_arm64,
      HostPlatform.linux_riscv64 => TargetPlatform.linux_riscv64,
      _ => TargetPlatform.linux_x64,
    };
    registerOptionBundles(const <OptionBundle>[DesktopBuildOptionsBundle()]);
    argParser.addDescriptors(<OptionDescriptor<Object?>>[
      _targetPlatformOption(defaultTargetPlatform),
      _targetSysroot,
    ], verboseHelp: verboseHelp);
  }

  static DefaultedEnumOptionDescriptor<TargetPlatform> _targetPlatformOption(
    TargetPlatform defaultPlatform,
  ) => DefaultedEnumOptionDescriptor<TargetPlatform>(
    name: 'target-platform',
    defaultsTo: defaultPlatform,
    values: const <TargetPlatform>[
      TargetPlatform.linux_arm64,
      TargetPlatform.linux_x64,
      TargetPlatform.linux_riscv64,
    ],
    nameMapper: (TargetPlatform platform) => platform.getName(),
    valueParser: TargetPlatform.fromName,
    help: 'The target platform for which the app is compiled.',
  );

  static const _targetSysroot = DefaultedStringOptionDescriptor(
    name: 'target-sysroot',
    defaultsTo: '/',
    help:
        'The root filesystem path of target platform for which '
        'the app is compiled. This option is valid only '
        'if the current host and target architectures are different.',
  );

  final BuildSystem buildSystem;
  final FeatureFlags _featureFlags;

  @visibleForTesting
  FeatureFlags get featureFlags => _featureFlags;

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  final name = 'linux';

  @override
  bool get hidden => !_featureFlags.isLinuxEnabled || !toolContext.platform.isLinux;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.linux,
  };

  @override
  String get description => 'Build a Linux desktop application.';

  bool get configOnly => getValue(DesktopBuildOptionsBundle.configOnly);

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = toolContext.fs;
    final Logger logger = this.logger;
    final OperatingSystemUtils os = toolContext.os;
    final Platform platform = toolContext.platform;

    final BuildInfo buildInfo = await getBuildInfo();
    final TargetPlatform targetPlatform = getValue(_targetPlatformOption(TargetPlatform.linux_x64));
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
      targetSysroot: getValue(_targetSysroot),
      logger: logger,
      configOnly: configOnly,
    );
    return FlutterCommandResult.success();
  }
}
