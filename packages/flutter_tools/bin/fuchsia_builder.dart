// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:process/process.dart';

import '../lib/src/base/common.dart';
import '../lib/src/base/config.dart';
import '../lib/src/base/context.dart';
import '../lib/src/base/file_system.dart';
import '../lib/src/base/io.dart';
import '../lib/src/base/logger.dart';
import '../lib/src/base/os.dart';
import '../lib/src/base/platform.dart';
import '../lib/src/cache.dart';
import '../lib/src/flx.dart';
import '../lib/src/globals.dart';
import '../lib/src/usage.dart';

const String _kOptionPackages = 'packages';
const String _kOptionOutput = 'output-file';
const String _kOptionHeader = 'header';
const String _kOptionSnapshot = 'snapshot';
const String _kOptionWorking = 'working-dir';
const String _kOptionsManifest = 'manifest';
const List<String> _kRequiredOptions = const <String>[
  _kOptionPackages,
  _kOptionOutput,
  _kOptionHeader,
  _kOptionSnapshot,
  _kOptionWorking,
];

Future<Null> main(List<String> args) async {
  AppContext executableContext = new AppContext();
  executableContext.setVariable(Logger, new StdoutLogger());
  executableContext.runInZone(() {
    // Initialize the context with some defaults.
    context.putIfAbsent(Platform, () => new LocalPlatform());
    context.putIfAbsent(FileSystem, () => new LocalFileSystem());
    context.putIfAbsent(ProcessManager, () => new LocalProcessManager());
    context.putIfAbsent(Logger, () => new StdoutLogger());
    context.putIfAbsent(Cache, () => new Cache());
    context.putIfAbsent(Config, () => new Config());
    context.putIfAbsent(OperatingSystemUtils, () => new OperatingSystemUtils());
    context.putIfAbsent(Usage, () => new Usage());
    return run(args);
  });
}

Future<Null> run(List<String> args) async {
  final ArgParser parser = new ArgParser()
    ..addOption(_kOptionPackages, help: 'The .packages file')
    ..addOption(_kOptionOutput, help: 'The generated flx file')
    ..addOption(_kOptionHeader, help: 'The header of the flx file')
    ..addOption(_kOptionSnapshot, help: 'The generated snapshot file')
    ..addOption(_kOptionWorking,
        help: 'The directory where to put temporary files')
    ..addOption(_kOptionsManifest, help: 'The manifest file');
  final ArgResults argResults = parser.parse(args);
  if (_kRequiredOptions.any((String option) => !argResults.options.contains(option))) {
    printError('Missing option! All options must be specified.');
    exit(1);
  }
  Cache.flutterRoot = platform.environment['FLUTTER_ROOT'];
  String outputPath = argResults[_kOptionOutput];
  try {
    await assemble(
      outputPath: outputPath,
      snapshotFile: fs.file(argResults[_kOptionSnapshot]),
      workingDirPath: argResults[_kOptionWorking],
      packagesPath: argResults[_kOptionPackages],
      manifestPath: argResults[_kOptionsManifest] ?? defaultManifestPath,
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
    final File outputFile = fs.file(outputPath);
    final List<int> content = outputFile.readAsBytesSync();
    outputFile.writeAsStringSync('$header\n');
    outputFile.writeAsBytesSync(content, mode: FileMode.APPEND);
    return 0;
  } catch (_) {
    return 1;
  }
}
