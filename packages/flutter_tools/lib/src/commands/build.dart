// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../flx.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../toolchain.dart';

class BuildCommand extends FlutterCommand {
  final String name = 'build';
  final String description = 'Package your Flutter app into an FLX.';

  BuildCommand() {
    argParser.addFlag('precompiled', negatable: false);
    // This option is still referenced by the iOS build scripts. We should
    // remove it once we've updated those build scripts.
    argParser.addOption('asset-base', help: 'Ignored. Will be removed.', hide: true);
    argParser.addOption('compiler');
    argParser.addOption('manifest', defaultsTo: defaultManifestPath);
    argParser.addOption('private-key', defaultsTo: defaultPrivateKeyPath);
    argParser.addOption('output-file', abbr: 'o', defaultsTo: defaultFlxOutputPath);
    argParser.addOption('snapshot', defaultsTo: defaultSnapshotPath);
    argParser.addOption('depfile', defaultsTo: defaultDepfilePath);
    addTargetOption();
  }

  Future<int> runInProject() async {
    String compilerPath = argResults['compiler'];

    if (compilerPath == null)
      await downloadToolchain();
    else
      toolchain = new Toolchain(compiler: new Compiler(compilerPath));

    String outputPath = argResults['output-file'];

    return await build(
      toolchain,
      mainPath: argResults['target'],
      manifestPath: argResults['manifest'],
      outputPath: outputPath,
      snapshotPath: argResults['snapshot'],
      depfilePath: argResults['depfile'],
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
