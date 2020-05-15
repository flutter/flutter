// Copyright 2014 The Flutter Authors. All rights reserved.
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

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:flutter_tools/src/test/runner.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';

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
      globals.fs.systemTempDirectory.createTempSync('flutter_fuchsia_tester.');
  try {
    Cache.flutterRoot = tempDir.path;

    final String shellPath = globals.fs.file(argResults[_kOptionShell]).resolveSymbolicLinksSync();
    if (!globals.fs.isFileSync(shellPath)) {
      throwToolExit('Cannot find Flutter shell at $shellPath');
    }

    final Directory sdkRootSrc = globals.fs.directory(argResults[_kOptionSdkRoot]);
    if (!globals.fs.isDirectorySync(sdkRootSrc.path)) {
      throwToolExit('Cannot find SDK files at ${sdkRootSrc.path}');
    }
    Directory coverageDirectory;
    final String coverageDirectoryPath = argResults[_kOptionCoverageDirectory] as String;
    if (coverageDirectoryPath != null) {
      if (!globals.fs.isDirectorySync(coverageDirectoryPath)) {
        throwToolExit('Cannot find coverage directory at $coverageDirectoryPath');
      }
      coverageDirectory = globals.fs.directory(coverageDirectoryPath);
    }

    // Put the tester shell where runTests expects it.
    // TODO(garymm): Switch to a Fuchsia-specific Artifacts impl.
    final Link testerDestLink =
        globals.fs.link(globals.artifacts.getArtifactPath(Artifact.flutterTester));
    testerDestLink.parent.createSync(recursive: true);
    testerDestLink.createSync(globals.fs.path.absolute(shellPath));

    final Directory sdkRootDest =
        globals.fs.directory(globals.artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath));
    sdkRootDest.createSync(recursive: true);
    for (final FileSystemEntity artifact in sdkRootSrc.listSync()) {
      globals.fs.link(sdkRootDest.childFile(artifact.basename).path).createSync(artifact.path);
    }
    // TODO(tvolkert): Remove once flutter_tester no longer looks for this.
    globals.fs.link(sdkRootDest.childFile('platform.dill').path).createSync('platform_strong.dill');

    globalPackagesPath =
        globals.fs.path.normalize(globals.fs.path.absolute(argResults[_kOptionPackages] as String));

    Directory testDirectory;
    CoverageCollector collector;
    if (argResults['coverage'] as bool) {
      collector = CoverageCollector(
        libraryPredicate: (String libraryName) {
          // If we have a specified coverage directory then accept all libraries.
          if (coverageDirectory != null) {
            return true;
          }
          final String projectName = FlutterProject.current().manifest.appName;
          return libraryName.contains(projectName);
        });
      if (!argResults.options.contains(_kOptionTestDirectory)) {
        throwToolExit('Use of --coverage requires setting --test-directory');
      }
      testDirectory = globals.fs.directory(argResults[_kOptionTestDirectory]);
    }


    final Map<String, String> tests = <String, String>{};
    final List<Map<String, dynamic>> jsonList = List<Map<String, dynamic>>.from(
      (json.decode(globals.fs.file(argResults[_kOptionTests]).readAsStringSync()) as List<dynamic>).cast<Map<String, dynamic>>());
    for (final Map<String, dynamic> map in jsonList) {
      final String source = globals.fs.file(map['source']).resolveSymbolicLinksSync();
      final String dill = globals.fs.file(map['dill']).resolveSymbolicLinksSync();
      tests[source] = dill;
    }

    // TODO(dnfield): This should be injected.
    exitCode = await const FlutterTestRunner().runTests(
      const TestWrapper(),
      tests.keys.toList(),
      workDir: testDirectory,
      watcher: collector,
      ipv6: false,
      enableObservatory: collector != null,
      buildMode: BuildMode.debug,
      precompiledDillFiles: tests,
      concurrency: math.max(1, globals.platform.numberOfProcessors - 2),
      icudtlPath: globals.fs.path.absolute(argResults[_kOptionIcudtl] as String),
      coverageDirectory: coverageDirectory,
      extraFrontEndOptions: <String>[],
    );

    if (collector != null) {
      // collector expects currentDirectory to be the root of the dart
      // package (i.e. contains lib/ and test/ sub-dirs). In some cases,
      // test files may appear to be in the root directory.
      if (coverageDirectory == null) {
        globals.fs.currentDirectory = testDirectory.parent;
      } else {
        globals.fs.currentDirectory = testDirectory;
      }
      if (!await collector.collectCoverageData(argResults[_kOptionCoveragePath] as String, coverageDirectory: coverageDirectory)) {
        throwToolExit('Failed to collect coverage data');
      }
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
  // TODO(ianh): There's apparently some sort of lost async task keeping the
  // process open. Remove the next line once that's been resolved.
  exit(exitCode);
}
