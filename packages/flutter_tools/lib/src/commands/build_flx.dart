// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../flx.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class BuildFlxCommand extends FlutterCommand {
  BuildFlxCommand() {
    usesTargetOption();
    argParser.addFlag('precompiled', negatable: false);
    // This option is still referenced by the iOS build scripts. We should
    // remove it once we've updated those build scripts.
    argParser.addOption('asset-base', help: 'Ignored. Will be removed.', hide: true);
    argParser.addOption('manifest', defaultsTo: defaultManifestPath);
    argParser.addOption('private-key', defaultsTo: defaultPrivateKeyPath);
    argParser.addOption('output-file', abbr: 'o', defaultsTo: defaultFlxOutputPath);
    argParser.addOption('snapshot', defaultsTo: defaultSnapshotPath);
    argParser.addOption('depfile', defaultsTo: defaultDepfilePath);
    argParser.addOption('working-dir', defaultsTo: defaultWorkingDirPath);
    argParser.addFlag('include-roboto-fonts', defaultsTo: true);
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
  Future<int> runInProject() async {
    String outputPath = argResults['output-file'];

    return await build(
      mainPath: argResults['target'],
      manifestPath: argResults['manifest'],
      outputPath: outputPath,
      snapshotPath: argResults['snapshot'],
      depfilePath: argResults['depfile'],
      privateKeyPath: argResults['private-key'],
      workingDirPath: argResults['working-dir'],
      precompiledSnapshot: argResults['precompiled'],
      includeRobotoFonts: argResults['include-roboto-fonts']
    ).then((int result) {
      if (result == 0)
        printStatus('Built $outputPath.');
      else
        printError('Error building $outputPath: $result.');
      return result;
    });
  }
}
