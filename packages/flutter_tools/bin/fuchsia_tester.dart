// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/disabled_usage.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart' as loader;
import 'package:flutter_tools/src/usage.dart';
import 'package:test/src/executable.dart'
    as test; // ignore: implementation_imports

// Note: this was largely inspired by lib/src/commands/test.dart.

const String _kOptionPackages = 'packages';
const String _kOptionShell = 'shell';
const String _kOptionTestDirectory = 'test-directory';
const List<String> _kRequiredOptions = const <String>[
  _kOptionPackages,
  _kOptionShell,
  _kOptionTestDirectory,
];

Future<Null> main(List<String> args) {
  return runInContext<Null>(() => run(args), overrides: <Type, dynamic>{
    Usage: new DisabledUsage(),
  });
}

Iterable<String> _findTests(Directory directory) {
  return directory
      .listSync(recursive: true, followLinks: false)
      .where((FileSystemEntity entity) =>
          entity.path.endsWith('_test.dart') && fs.isFileSync(entity.path))
      .map((FileSystemEntity entity) => fs.path.absolute(entity.path));
}

Future<Null> run(List<String> args) async {
  final ArgParser parser = new ArgParser()
    ..addOption(_kOptionPackages, help: 'The .packages file')
    ..addOption(_kOptionShell, help: 'The Flutter shell binary')
    ..addOption(_kOptionTestDirectory, help: 'Directory containing the tests');
  final ArgResults argResults = parser.parse(args);
  if (_kRequiredOptions
      .any((String option) => !argResults.options.contains(option))) {
    printError('Missing option! All options must be specified.');
    exit(1);
  }
  final Directory tempDirectory =
      fs.systemTempDirectory.createTempSync('fuchsia_tester');
  try {
    Cache.flutterRoot = tempDirectory.path;
    final Directory testDirectory =
        fs.directory(argResults[_kOptionTestDirectory]);
    final Iterable<String> tests = _findTests(testDirectory);

    final List<String> testArgs = <String>[];
    testArgs.add('--');
    testArgs.addAll(tests);

    final String shellPath = argResults[_kOptionShell];
    if (!fs.isFileSync(shellPath)) {
      throwToolExit('Cannot find Flutter shell at $shellPath');
    }
    loader.installHook(
      shellPath: shellPath,
    );

    PackageMap.globalPackagesPath =
        fs.path.normalize(fs.path.absolute(argResults[_kOptionPackages]));
    fs.currentDirectory = testDirectory;

    await test.main(testArgs);
    exit(exitCode);
  } finally {
    tempDirectory.deleteSync(recursive: true);
  }
}
