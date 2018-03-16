// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../build_info.dart';
import '../flx.dart';
import 'build.dart';

class BuildFlxCommand extends BuildSubCommand {
  BuildFlxCommand({bool verboseHelp: false}) {
    usesTargetOption();
    argParser.addFlag('precompiled', negatable: false);
    // This option is still referenced by the iOS build scripts. We should
    // remove it once we've updated those build scripts.
    argParser.addOption('asset-base', help: 'Ignored. Will be removed.', hide: !verboseHelp);
    argParser.addOption('manifest', defaultsTo: defaultManifestPath);
    argParser.addOption('private-key', defaultsTo: defaultPrivateKeyPath);
    argParser.addOption('output-file', abbr: 'o', defaultsTo: defaultFlxOutputPath);
    argParser.addOption('snapshot', defaultsTo: defaultSnapshotPath);
    argParser.addOption('depfile', defaultsTo: defaultDepfilePath);
    argParser.addOption('kernel-file', defaultsTo: defaultApplicationKernelPath);
    argParser.addFlag('preview-dart-2', negatable: false, hide: !verboseHelp);
    argParser.addFlag(
      'track-widget-creation',
      hide: !verboseHelp,
      help: 'Track widget creation locations. Requires Dart 2.0 functionality.',
    );
    argParser.addOption('working-dir', defaultsTo: getAssetBuildDirectory());
    argParser.addFlag('report-licensed-packages', help: 'Whether to report the names of all the packages that are included in the application\'s LICENSE file.', defaultsTo: false);
    usesPubOption();
  }

  @override
  final String name = 'flx';

  @override
  final String description = 'Build a Flutter FLX file from your app.';

  @override
  final String usageFooter = 'FLX files are archives of your application code and resources; '
    'they are used by some Flutter Android and iOS runtimes.';

  @override
  Future<Null> runCommand() async {
    await super.runCommand();
    final String outputPath = argResults['output-file'];

    await build(
      mainPath: targetFile,
      manifestPath: argResults['manifest'],
      outputPath: outputPath,
      snapshotPath: argResults['snapshot'],
      applicationKernelFilePath: argResults['kernel-file'],
      depfilePath: argResults['depfile'],
      privateKeyPath: argResults['private-key'],
      workingDirPath: argResults['working-dir'],
      previewDart2: argResults['preview-dart-2'],
      precompiledSnapshot: argResults['precompiled'],
      reportLicensedPackages: argResults['report-licensed-packages'],
      trackWidgetCreation: argResults['track-widget-creation'],
    );
  }
}
