// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../features.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterOptions, FlutterCommandResult;
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({bool verboseHelp = false, this.bundleBuilder}) {
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    usesBuildNumberOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    argParser
      ..addFlag('precompiled', negatable: false)
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
      ..addMultiOption(FlutterOptions.kExtraFrontEndOptions,
        splitCommas: true,
        hide: true,
      )
      ..addMultiOption(FlutterOptions.kExtraGenSnapshotOptions,
        splitCommas: true,
        hide: true,
      )
      ..addOption('asset-dir', defaultsTo: getAssetBuildDirectory())
      ..addFlag('report-licensed-packages',
        help: 'Whether to report the names of all the packages that are included '
              'in the application\'s LICENSE file.',
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
    final String projectDir = fs.file(targetFile).parent.parent.path;
    final FlutterProject futterProject = FlutterProject.fromPath(projectDir);
    if (futterProject == null) {
      return const <CustomDimensions, String>{};
    }
    return <CustomDimensions, String>{
      CustomDimensions.commandBuildBundleTargetPlatform: argResults['target-platform'],
      CustomDimensions.commandBuildBundleIsModule: '${futterProject.isModule}'
    };
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = argResults['target-platform'];
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

    final BuildMode buildMode = getBuildMode();

    await bundleBuilder.build(
      platform: platform,
      buildMode: buildMode,
      mainPath: targetFile,
      manifestPath: argResults['manifest'],
      depfilePath: argResults['depfile'],
      privateKeyPath: argResults['private-key'],
      assetDirPath: argResults['asset-dir'],
      precompiledSnapshot: argResults['precompiled'],
      reportLicensedPackages: argResults['report-licensed-packages'],
      trackWidgetCreation: argResults['track-widget-creation'],
      extraFrontEndOptions: argResults[FlutterOptions.kExtraFrontEndOptions],
      extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions],
      fileSystemScheme: argResults['filesystem-scheme'],
      fileSystemRoots: argResults['filesystem-root'],
    );
    return null;
  }
}
