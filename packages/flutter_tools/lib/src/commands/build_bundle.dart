// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../base/common.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({bool verboseHelp = false, this.bundleBuilder}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    usesBuildNumberOption();
    addBuildModeFlags(verboseHelp: verboseHelp, defaultToRelease: false);
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    argParser
      ..addOption('depfile',
        defaultsTo: defaultDepfilePath,
        help: 'A file path where a depfile will be written. '
              'This contains all build inputs and outputs in a Make-style syntax.'
      )
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: const <String>[
          'android-arm',
          'android-arm64',
          'android-x86',
          'android-x64',
          'ios',
          'darwin-x64',
          'linux-x64',
          'linux-arm64',
          'windows-x64',
        ],
        help: 'The architecture for which to build the application.',
      )
      ..addOption('asset-dir',
        defaultsTo: getAssetBuildDirectory(),
        help: 'The output directory for the kernel_blob.bin file, the native snapshet, the assets, etc. '
              'Can be used to redirect the output when driving the Flutter toolchain from another build system.',
      );
    usesPubOption();
    usesTrackWidgetCreation(verboseHelp: verboseHelp);

    bundleBuilder ??= BundleBuilder();
  }

  BundleBuilder bundleBuilder;

  @override
  final String name = 'bundle';

  @override
  final String description = 'Build the Flutter assets directory from your app.';

  @override
  final String usageFooter = 'The Flutter assets directory contains your '
      'application code and resources; they are used by some Flutter Android and'
      ' iOS runtimes.';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final String projectDir = globals.fs.file(targetFile).parent.parent.path;
    final FlutterProject flutterProject = FlutterProject.fromDirectory(globals.fs.directory(projectDir));
    if (flutterProject == null) {
      return const <CustomDimensions, String>{};
    }
    return <CustomDimensions, String>{
      CustomDimensions.commandBuildBundleTargetPlatform: stringArg('target-platform'),
      CustomDimensions.commandBuildBundleIsModule: '${flutterProject.isModule}',
    };
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = stringArg('target-platform');
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null) {
      throwToolExit('Unknown platform: $targetPlatform');
    }
    // Check for target platforms that are only allowed via feature flags.
    switch (platform) {
      case TargetPlatform.darwin_x64:
        if (!featureFlags.isMacOSEnabled) {
          throwToolExit('macOS is not a supported target platform.');
        }
        break;
      case TargetPlatform.windows_x64:
        if (!featureFlags.isWindowsEnabled) {
          throwToolExit('Windows is not a supported target platform.');
        }
        break;
      case TargetPlatform.linux_x64:
        if (!featureFlags.isLinuxEnabled) {
          throwToolExit('Linux is not a supported target platform.');
        }
        break;
      default:
        break;
    }

    final BuildInfo buildInfo = await getBuildInfo();
    displayNullSafetyMode(buildInfo);

    await bundleBuilder.build(
      platform: platform,
      buildInfo: buildInfo,
      mainPath: targetFile,
      manifestPath: defaultManifestPath,
      depfilePath: stringArg('depfile'),
      assetDirPath: stringArg('asset-dir'),
      trackWidgetCreation: boolArg('track-widget-creation'),
      extraFrontEndOptions: buildInfo.extraFrontEndOptions,
      extraGenSnapshotOptions: buildInfo.extraGenSnapshotOptions,
      fileSystemRoots: stringsArg(FlutterOptions.kFileSystemRoot),
      fileSystemScheme: stringArg(FlutterOptions.kFileSystemScheme),
      treeShakeIcons: buildInfo.treeShakeIcons,
    );
    return FlutterCommandResult.success();
  }
}
