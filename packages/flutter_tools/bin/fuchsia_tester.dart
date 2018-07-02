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
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/disabled_usage.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/usage.dart';

// Note: this was largely inspired by lib/src/commands/test.dart.

const String _kOptionPackages = 'packages';
const String _kOptionShell = 'shell';
const String _kOptionTestDirectory = 'test-directory';
const List<String> _kRequiredOptions = const <String>[
  _kOptionPackages,
  _kOptionShell,
  _kOptionTestDirectory,
];
const String _kOptionCoverage = 'coverage';
const String _kOptionCoveragePath = 'coverage-path';

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
    ..addOption(_kOptionTestDirectory, help: 'Directory containing the tests')
    ..addFlag(_kOptionCoverage,
      defaultsTo: false,
      negatable: false,
      help: 'Whether to collect coverage information.',
    )
    ..addOption(_kOptionCoveragePath,
        defaultsTo: 'coverage/lcov.info',
        help: 'Where to store coverage information (if coverage is enabled).',
    );
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
    // Put the tester shell where runTests expects it.
    final Link testerDestLink =
        fs.link(artifacts.getArtifactPath(Artifact.flutterTester));
    testerDestLink.parent.createSync(recursive: true);
    testerDestLink.createSync(shellPath);

    PackageMap.globalPackagesPath =
        fs.path.normalize(fs.path.absolute(argResults[_kOptionPackages]));

    CoverageCollector collector;
    if (argResults['coverage']) {
      collector = new CoverageCollector();
    }

    final int result = await runTests(
      tests,
      workDir: testDirectory,
      watcher: collector,
      enableObservatory: collector != null,
    );

    if (collector != null) {
      // collector expects currentDirectory to be the root of the dart
      // package (i.e. contains lib/ and test/ sub-dirs).
      fs.currentDirectory = testDirectory.parent;
      if (!await
          collector.collectCoverageData(argResults[_kOptionCoveragePath]))
        throwToolExit('Failed to collect coverage data');
    }

    exit(result);
  } finally {
    tempDirectory.deleteSync(recursive: true);
  }
}
