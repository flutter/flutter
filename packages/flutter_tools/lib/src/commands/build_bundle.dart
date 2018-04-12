// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../build_info.dart';
import '../bundle.dart';
import 'build.dart';

class BuildBundleCommand extends BuildSubCommand {
  BuildBundleCommand({bool verboseHelp: false}) {
    usesTargetOption();
    argParser
      ..addFlag('precompiled', negatable: false)
      // This option is still referenced by the iOS build scripts. We should
      // remove it once we've updated those build scripts.
      ..addOption('asset-base', help: 'Ignored. Will be removed.', hide: !verboseHelp)
      ..addOption('manifest', defaultsTo: defaultManifestPath)
      ..addOption('private-key', defaultsTo: defaultPrivateKeyPath)
      ..addOption('snapshot', defaultsTo: defaultSnapshotPath)
      ..addOption('depfile', defaultsTo: defaultDepfilePath)
      ..addOption('kernel-file', defaultsTo: defaultApplicationKernelPath)
      ..addFlag('preview-dart-2',
        defaultsTo: true,
        hide: !verboseHelp,
        help: 'Preview Dart 2.0 functionality.',
      )
      ..addFlag('track-widget-creation',
        hide: !verboseHelp,
        help: 'Track widget creation locations. Requires Dart 2.0 functionality.',
      )
      ..addOption('asset-dir', defaultsTo: getAssetBuildDirectory())
      ..addFlag('report-licensed-packages',
        help: 'Whether to report the names of all the packages that are included '
              'in the application\'s LICENSE file.',
        defaultsTo: false)
      ..addMultiOption('filesystem-root',
        hide: !verboseHelp,
        help: 'Specify the path, that is used as root in a virtual file system\n'
            'for compilation. Input file name should be specified as Uri in\n'
            'filesystem-scheme scheme. Use only in Dart 2 mode.\n'
            'Requires --output-dill option to be explicitly specified.\n')
      ..addOption('filesystem-scheme',
        defaultsTo: 'org-dartlang-root',
        hide: !verboseHelp,
        help: 'Specify the scheme that is used for virtual file system used in\n'
            'compilation. See more details on filesystem-root option.\n');
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
  Future<Null> runCommand() async {
    await super.runCommand();

    await build(
      mainPath: targetFile,
      manifestPath: argResults['manifest'],
      snapshotPath: argResults['snapshot'],
      applicationKernelFilePath: argResults['kernel-file'],
      depfilePath: argResults['depfile'],
      privateKeyPath: argResults['private-key'],
      assetDirPath: argResults['asset-dir'],
      previewDart2: argResults['preview-dart-2'],
      precompiledSnapshot: argResults['precompiled'],
      reportLicensedPackages: argResults['report-licensed-packages'],
      trackWidgetCreation: argResults['track-widget-creation'],
      fileSystemScheme: argResults['filesystem-scheme'],
      fileSystemRoots: argResults['filesystem-root'],
    );
  }
}
