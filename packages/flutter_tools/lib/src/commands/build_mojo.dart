// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../flx.dart';
import '../globals.dart';
import 'build.dart';

const String _kOptionSnapshotter = 'snapshotter-path';
const String _kOptionTarget = 'target';
const String _kOptionPackages = 'packages';
const String _kOptionOutput = 'output-file';
const String _kOptionSnapshot = 'snapshot';
const String _kOptionDepfile = 'depfile';
const String _kOptionWorking = 'working-dir';
const List<String> _kOptions = const <String>[
  _kOptionSnapshotter,
  _kOptionTarget,
  _kOptionPackages,
  _kOptionOutput,
  _kOptionSnapshot,
  _kOptionDepfile,
  _kOptionWorking
];

class BuildMojoCommand extends BuildSubCommand {
  BuildMojoCommand({bool verboseHelp: false}) {
    argParser.addOption(_kOptionSnapshotter,
        help: 'The snapshotter executable');
    argParser.addOption(_kOptionTarget, help: 'The entry point into the app');
    argParser.addOption(_kOptionPackages, help: 'The .packages file');
    argParser.addOption(_kOptionOutput, help: 'The generated flx file');
    argParser.addOption(_kOptionSnapshot, help: 'The generated snapshot file');
    argParser.addOption(_kOptionDepfile, help: 'The generated dependency file');
    argParser.addOption(_kOptionWorking,
        help: 'The directory where to put temporary files');
    commandValidator = () => true;
  }

  @override
  final String name = 'mojo';

  @override
  final String description = 'Build a Flutter FLX file for Mojo.';

  @override
  final String usageFooter =
      'FLX files are archives of your application code and resources; '
      'they are used by the Flutter content handler.';

  @override
  Future<int> runCommand() async {
    await super.runCommand();
    if (_kOptions
        .any((String option) => !argResults.options.contains(option))) {
      printError('Missing option! All options must be specified.');
      return 1;
    }
    String outputPath = argResults[_kOptionOutput];
    return await build(
      snapshotterPath: argResults[_kOptionSnapshotter],
      mainPath: argResults[_kOptionTarget],
      outputPath: outputPath,
      snapshotPath: argResults[_kOptionSnapshot],
      depfilePath: argResults[_kOptionDepfile],
      workingDirPath: argResults[_kOptionWorking],
      packagesPath: argResults[_kOptionPackages],
      includeRobotoFonts: true,
    ).then((int result) {
      if (result != 0) {
        printError('Error building $outputPath: $result.');
      }
      return result;
    });
  }
}
