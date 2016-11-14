// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../lib/src/base/common.dart';
import '../lib/src/base/context.dart';
import '../lib/src/base/logger.dart';
import '../lib/src/cache.dart';
import '../lib/src/flx.dart';
import '../lib/src/globals.dart';

const String _kOptionPackages = 'packages';
const String _kOptionOutput = 'output-file';
const String _kOptionHeader = 'header';
const String _kOptionSnapshot = 'snapshot';
const String _kOptionWorking = 'working-dir';
const List<String> _kOptions = const <String>[
  _kOptionPackages,
  _kOptionOutput,
  _kOptionHeader,
  _kOptionSnapshot,
  _kOptionWorking,
];

Future<Null> main(List<String> args) async {
  context[Logger] = new StdoutLogger();
  final ArgParser parser = new ArgParser()
    ..addOption(_kOptionPackages, help: 'The .packages file')
    ..addOption(_kOptionOutput, help: 'The generated flx file')
    ..addOption(_kOptionHeader, help: 'The header of the flx file')
    ..addOption(_kOptionSnapshot, help: 'The generated snapshot file')
    ..addOption(_kOptionWorking,
        help: 'The directory where to put temporary files');
  final ArgResults argResults = parser.parse(args);
  if (_kOptions.any((String option) => !argResults.options.contains(option))) {
    printError('Missing option! All options must be specified.');
    exit(1);
  }
  Cache.flutterRoot = Platform.environment['FLUTTER_ROOT'];
  String outputPath = argResults[_kOptionOutput];
  try {
    await assemble(
      outputPath: outputPath,
      snapshotFile: new File(argResults[_kOptionSnapshot]),
      workingDirPath: argResults[_kOptionWorking],
      packagesPath: argResults[_kOptionPackages],
      manifestPath: defaultManifestPath,
      includeDefaultFonts: false,
    );
  } on ToolExit catch (e) {
    printError(e.message);
    exit(e.exitCode);
  }
  final int headerResult = _addHeader(outputPath, argResults[_kOptionHeader]);
  if (headerResult != 0) {
    printError('Error adding header to $outputPath: $headerResult.');
  }
  exit(headerResult);
}

int _addHeader(String outputPath, String header) {
  try {
    final File outputFile = new File(outputPath);
    final List<int> content = outputFile.readAsBytesSync();
    outputFile.writeAsStringSync('$header\n');
    outputFile.writeAsBytesSync(content, mode: FileMode.APPEND);
    return 0;
  } catch (_) {
    return 1;
  }
}
