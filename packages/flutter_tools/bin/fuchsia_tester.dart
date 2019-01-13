// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/disabled_usage.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/usage.dart';

// This was largely inspired by lib/src/commands/test.dart.

const String _kOptionPackages = 'packages';
const String _kOptionShell = 'shell';
const String _kOptionTestDirectory = 'test-directory';
const String _kOptionSdkRoot = 'sdk-root';
const String _kOptionIcudtl = 'icudtl';
const String _kOptionTests = 'tests';
const String _kOptionCoverageDirectory = 'coverage-directory';
const List<String> _kRequiredOptions = <String>[
  _kOptionPackages,
  _kOptionShell,
  _kOptionTestDirectory,
  _kOptionSdkRoot,
  _kOptionIcudtl,
  _kOptionTests,
];
const String _kOptionCoverage = 'coverage';
const String _kOptionCoveragePath = 'coverage-path';

void main(List<String> args) {
  runInContext<void>(() => run(args), overrides: <Type, Generator>{
    Usage: () => DisabledUsage(),
  });
}

Future<void> run(List<String> args) async {
  final ArgParser parser = ArgParser()
    ..addOption(_kOptionPackages, help: 'The .packages file')
    ..addOption(_kOptionShell, help: 'The Flutter shell binary')
    ..addOption(_kOptionTestDirectory, help: 'Directory containing the tests')
    ..addOption(_kOptionSdkRoot, help: 'Path to the SDK platform files')
    ..addOption(_kOptionIcudtl, help: 'Path to the ICU data file')
    ..addOption(_kOptionTests, help: 'Path to json file that maps Dart test files to precompiled dill files')
    ..addOption(_kOptionCoverageDirectory, help: 'The path to the directory that will have coverage collected')
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
    throwToolExit('Missing option! All options must be specified.');
  }
  final Directory tempDir =
      fs.systemTempDirectory.createTempSync('flutter_fuchsia_tester.');
  try {
    Cache.flutterRoot = tempDir.path;
    final Directory testDirectory =
        fs.directory(argResults[_kOptionTestDirectory]);

    final String shellPath = argResults[_kOptionShell];
    if (!fs.isFileSync(shellPath)) {
      throwToolExit('Cannot find Flutter shell at $shellPath');
    }

    final Directory sdkRootSrc = fs.directory(argResults[_kOptionSdkRoot]);
    if (!fs.isDirectorySync(sdkRootSrc.path)) {
      throwToolExit('Cannot find SDK files at ${sdkRootSrc.path}');
    }
    Directory coverageDirectory;
    final String coverageDirectoryPath = argResults[_kOptionCoverageDirectory];
    if (coverageDirectoryPath != null) {
      if (!fs.isDirectorySync(coverageDirectoryPath)) {
        throwToolExit('Cannot find coverage directory at $coverageDirectoryPath');
      }
      coverageDirectory = fs.directory(coverageDirectoryPath);
    }

    // Put the tester shell where runTests expects it.
    // TODO(garymm): Switch to a Fuchsia-specific Artifacts impl.
    final Link testerDestLink =
        fs.link(artifacts.getArtifactPath(Artifact.flutterTester));
    testerDestLink.parent.createSync(recursive: true);
    testerDestLink.createSync(shellPath);
    final Link icudtlLink = testerDestLink.parent.childLink('icudtl.dat');
    icudtlLink.createSync(argResults[_kOptionIcudtl]);
    final Directory sdkRootDest =
        fs.directory(artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath));
    sdkRootDest.createSync(recursive: true);
    for (FileSystemEntity artifact in sdkRootSrc.listSync()) {
      fs.link(sdkRootDest.childFile(artifact.basename).path).createSync(artifact.path);
    }
    // TODO(tvolkert): Remove once flutter_tester no longer looks for this.
    fs.link(sdkRootDest.childFile('platform.dill').path).createSync('platform_strong.dill');

    PackageMap.globalPackagesPath =
        fs.path.normalize(fs.path.absolute(argResults[_kOptionPackages]));

    CoverageCollector collector;
    if (argResults['coverage']) {
      collector = CoverageCollector();
    }


    final Map<String, String> tests = <String, String>{};
    final List<Map<String, dynamic>> jsonList = List<Map<String, dynamic>>.from(
      json.decode(fs.file(argResults[_kOptionTests]).readAsStringSync()));
    for (Map<String, dynamic> map in jsonList) {
      tests[map['source']] = map['dill'];
    }

    exitCode = await runTests(
      tests.keys.toList(),
      workDir: testDirectory,
      watcher: collector,
      ipv6: false,
      enableObservatory: collector != null,
      precompiledDillFiles: tests,
      concurrency: math.max(1, platform.numberOfProcessors - 2),
    );

    if (collector != null) {
      // collector expects currentDirectory to be the root of the dart
      // package (i.e. contains lib/ and test/ sub-dirs). In some cases,
      // test files may appear to be in the root directory.
      if (coverageDirectory == null) {
        fs.currentDirectory = testDirectory.parent;
      } else {
        fs.currentDirectory = testDirectory;
      }
      if (!await collector.collectCoverageData(argResults[_kOptionCoveragePath], coverageDirectory: coverageDirectory))
        throwToolExit('Failed to collect coverage data');
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
  // TODO(ianh): There's apparently some sort of lost async task keeping the
  // process open. Remove the next line once that's been resolved.
  exit(exitCode);
}
