// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterOptions, FlutterCommandResult;
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({bool verboseHelp = false, this.bundleBuilder}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    usesBuildNumberOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesExtraFrontendOptions();
    argParser
      ..addFlag(
        'precompiled',
        negatable: false,
        help:
          'If not provided, then '
          'a debug build is always provided, regardless of build mode. If provided '
          'then release is the default mode.',
      )
      // This option is still referenced by the iOS build scripts. We should
      // remove it once we've updated those build scripts.
      ..addOption('asset-base', help: 'Ignored. Will be removed.', hide: !verboseHelp)
      ..addOption('manifest', defaultsTo: defaultManifestPath)
      ..addOption('private-key', defaultsTo: defaultPrivateKeyPath)
      ..addOption('depfile', defaultsTo: defaultDepfilePath)
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
          'windows-x64',
        ],
      )
      ..addOption('asset-dir', defaultsTo: getAssetBuildDirectory())
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addFlag('report-licensed-packages',
        help: 'Whether to report the names of all the packages that are included '
              "in the application's LICENSE file.",
        defaultsTo: false);
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
    final FlutterProject futterProject = FlutterProject.fromPath(projectDir);
    if (futterProject == null) {
      return const <CustomDimensions, String>{};
    }
    return <CustomDimensions, String>{
      CustomDimensions.commandBuildBundleTargetPlatform: stringArg('target-platform'),
      CustomDimensions.commandBuildBundleIsModule: '${futterProject.isModule}',
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

    final BuildInfo buildInfo = getBuildInfo();

    await bundleBuilder.build(
      platform: platform,
      buildInfo: buildInfo,
      mainPath: targetFile,
      manifestPath: stringArg('manifest'),
      depfilePath: stringArg('depfile'),
      privateKeyPath: stringArg('private-key'),
      assetDirPath: stringArg('asset-dir'),
      precompiledSnapshot: boolArg('precompiled'),
      reportLicensedPackages: boolArg('report-licensed-packages'),
      trackWidgetCreation: boolArg('track-widget-creation'),
      extraFrontEndOptions: buildInfo.extraFrontEndOptions,
      extraGenSnapshotOptions: buildInfo.extraGenSnapshotOptions,
      fileSystemScheme: stringArg('filesystem-scheme'),
      fileSystemRoots: stringsArg('filesystem-root'),
      treeShakeIcons: buildInfo.treeShakeIcons,
    );
    return FlutterCommandResult.success();
  }
}
