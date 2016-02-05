// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/flx.dart' as flx;

import '../base/context.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';

class BuildCommand extends FlutterCommand {
  final String name = 'build';
  final String description = 'Packages your Flutter app into an FLX.';

  BuildCommand() {
    argParser.addFlag('precompiled', negatable: false);
    argParser.addOption('asset-base', defaultsTo: flx.defaultMaterialAssetBasePath);
    argParser.addOption('compiler');
    argParser.addOption('target',
      abbr: 't',
      defaultsTo: flx.defaultMainPath,
      help: 'Target app path / main entry-point file.'
    );
    // TODO(devoncarew): Remove this once the xcode project is switched over.
    argParser.addOption('main', hide: true);
    argParser.addOption('manifest', defaultsTo: flx.defaultManifestPath);
    argParser.addOption('private-key', defaultsTo: flx.defaultPrivateKeyPath);
    argParser.addOption('output-file', abbr: 'o', defaultsTo: flx.defaultFlxOutputPath);
    argParser.addOption('snapshot', defaultsTo: flx.defaultSnapshotPath);
  }

  Future<int> runInProject() async {
    String compilerPath = argResults['compiler'];

    if (compilerPath == null)
      await downloadToolchain();
    else
      toolchain = new Toolchain(compiler: new Compiler(compilerPath));

    String outputPath = argResults['output-file'];

    return await flx.build(
      toolchain,
      materialAssetBasePath: argResults['asset-base'],
      mainPath: argResults.wasParsed('main') ? argResults['main'] : argResults['target'],
      manifestPath: argResults['manifest'],
      outputPath: outputPath,
      snapshotPath: argResults['snapshot'],
      privateKeyPath: argResults['private-key'],
      precompiledSnapshot: argResults['precompiled']
    ).then((int result) {
      if (result == 0)
        printStatus('Built $outputPath.');
      else
        printError('Error building $outputPath: $result.');
      return result;
    });
  }
}
