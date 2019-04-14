// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../runner/flutter_command.dart' show FlutterOptions, FlutterCommandResult;
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({bool verboseHelp = false}) {
    usesTargetOption();
    usesFilesystemOptions(hide: !verboseHelp);
    usesBuildNumberOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    addDynamicModeFlags(verboseHelp: verboseHelp);
    addDynamicBaselineFlags(verboseHelp: verboseHelp);
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
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64', 'ios'],
      )
      ..addFlag('track-widget-creation',
        hide: !verboseHelp,
        help: 'Track widget creation locations. Requires Dart 2.0 functionality.',
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
  }

  @override
  final String name = 'bundle';

  @override
  final String description = 'Build the Flutter assets directory from your app.';

  @override
  final String usageFooter = 'The Flutter assets directory contains your '
      'application code and resources; they are used by some Flutter Android and'
      ' iOS runtimes.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String targetPlatform = argResults['target-platform'] as String;
    final TargetPlatform platform = getTargetPlatformForName(targetPlatform);
    if (platform == null)
      throwToolExit('Unknown platform: $targetPlatform');

    final BuildMode buildMode = getBuildMode();

    final String buildNumber = argResults['build-number'] != null ? argResults['build-number'] as String : null;

    await build(
      platform: platform,
      buildMode: buildMode,
      mainPath: targetFile,
      manifestPath: argResults['manifest'] as String,
      depfilePath: argResults['depfile'] as String,
      privateKeyPath: argResults['private-key'] as String,
      assetDirPath: argResults['asset-dir'] as String,
      precompiledSnapshot: argResults['precompiled'] as bool,
      reportLicensedPackages: argResults['report-licensed-packages'] as bool,
      trackWidgetCreation: argResults['track-widget-creation'] as bool,
      compilationTraceFilePath: argResults['compilation-trace-file'] as String,
      createPatch: argResults['patch'] as bool,
      buildNumber: buildNumber,
      baselineDir: argResults['baseline-dir'] as String,
      extraFrontEndOptions: argResults[FlutterOptions.kExtraFrontEndOptions] as List<String>,
      extraGenSnapshotOptions: argResults[FlutterOptions.kExtraGenSnapshotOptions] as List<String>,
      fileSystemScheme: argResults['filesystem-scheme'] as String,
      fileSystemRoots: argResults['filesystem-root'] as List<String>,
    );
    return null;
  }
}
