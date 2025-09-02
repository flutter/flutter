// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../bundle_builder.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({
    required super.logger,
    bool verboseHelp = false,
    BundleBuilder? bundleBuilder,
  }) : _bundleBuilder = bundleBuilder ?? BundleBuilder(),
       super(verboseHelp: verboseHelp) {
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
          'windows-x64',
          'windows-arm64',
        ],
        help: 'The architecture for which to build the application.',
      )
      ..addOption(
        'asset-dir',
        help:
            '(deprecated) The output directory for the kernel_blob.bin file, the native snapshot, the assets, etc. '
            'Can be used to redirect the output when driving the Flutter toolchain from another build system. '
            'The "--asset-dir" argument is deprecated; use "--output-dir" instead.',
      )
      ..addOption(
        'output-dir',
        defaultsTo: getBuildDirectory(),
        help:
            'The output directory for the Flutter assets, the AOT artifacts, etc. '
            'Can be used to redirect the output when driving the Flutter toolchain from another build system.',
      )
      ..addFlag(
        'build-aot-assets',
        help:
            'Build AOT assets when building a profile or release bundle (has no effect for debug builds).',
      )
      ..addFlag(
        'tree-shake-icons',
        hide: !verboseHelp,
        help: '(deprecated) Icon font tree shaking is not supported by this command.',
      );
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
  }

  final BundleBuilder _bundleBuilder;

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
    final String projectDir = globals.fs.file(targetFile).parent.parent.path;
    final FlutterProject flutterProject = FlutterProject.fromDirectory(
      globals.fs.directory(projectDir),
    );
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

    final dynamic assetDir = argResults?['asset-dir'];
    if (assetDir != null) {
      globals.printWarning(
        '${globals.logger.terminal.warningMark} The "--asset-dir" argument is deprecated; use "--output-dir" instead.',
      );
    }

    final dynamic outputDir = argResults?['output-dir'];
    if (assetDir != null && outputDir != null) {
      throwToolExit('Either --asset-dir or --output-dir can be provided, not both.');
    }

    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = stringArg('target-platform')!;
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    // Check for target platforms that are only allowed via feature flags.
    switch (platform) {
      case TargetPlatform.darwin:
        if (!featureFlags.isMacOSEnabled) {
          throwToolExit('macOS is not a supported target platform.');
        }
      case TargetPlatform.windows_x64:
      case TargetPlatform.windows_arm64:
        if (!featureFlags.isWindowsEnabled) {
          throwToolExit('Windows is not a supported target platform.');
        }
      case TargetPlatform.linux_x64:
      case TargetPlatform.linux_arm64:
        if (!featureFlags.isLinuxEnabled) {
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

    final String? assetDir = stringArg('asset-dir');
    final String? outputDir = assetDir == null ? stringArg('output-dir') : null;

    await _bundleBuilder.build(
      platform: platform,
      buildInfo: buildInfo,
      mainPath: targetFile,
      depfilePath: stringArg('depfile'),
      assetDirPath: assetDir,
      outputDirPath: outputDir,
      buildAOTAssets: boolArg('build-aot-assets'),
      buildNativeAssets: false,
    );
    return FlutterCommandResult.success();
  }
}
