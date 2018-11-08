// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../runner/flutter_command.dart';
import '../test/coverage_collector.dart';
import '../test/event_printer.dart';
import '../test/runner.dart';
import '../test/watcher.dart';

class TestCommand extends FlutterCommand {
  TestCommand({ bool verboseHelp = false }) {
    requiresPubspecYaml();
    usesPubOption();
    argParser
      ..addMultiOption('name',
        help: 'A regular expression matching substrings of the names of tests to run.',
        valueHelp: 'regexp',
        splitCommas: false,
      )
      ..addMultiOption('plain-name',
        help: 'A plain-text substring of the names of tests to run.',
        valueHelp: 'substring',
        splitCommas: false,
      )
      ..addFlag('start-paused',
        defaultsTo: false,
        negatable: false,
        help: 'Start in a paused mode and wait for a debugger to connect.\n'
              'You must specify a single test file to run, explicitly.\n'
              'Instructions for connecting with a debugger and printed to the '
              'console once the test has started.',
      )
      ..addFlag('coverage',
        defaultsTo: false,
        negatable: false,
        help: 'Whether to collect coverage information.',
      )
      ..addFlag('merge-coverage',
        defaultsTo: false,
        negatable: false,
        help: 'Whether to merge coverage data with "coverage/lcov.base.info".\n'
              'Implies collecting coverage data. (Requires lcov)',
      )
      ..addFlag('ipv6',
        negatable: false,
        hide: true,
        help: 'Whether to use IPv6 for the test harness server socket.',
      )
      ..addOption('coverage-path',
        defaultsTo: 'coverage/lcov.info',
        help: 'Where to store coverage information (if coverage is enabled).',
      )
      ..addFlag('machine',
        hide: !verboseHelp,
        negatable: false,
        help: 'Handle machine structured JSON command input\n'
              'and provide output and progress in machine friendly format.',
      )
      ..addFlag('track-widget-creation',
        negatable: false,
        hide: !verboseHelp,
        help: 'Track widget creation locations.\n'
              'This enables testing of features such as the widget inspector.',
      )
      ..addFlag('update-goldens',
        negatable: false,
        help: 'Whether matchesGoldenFile() calls within your test methods should '
              'update the golden files rather than test for an existing match.',
      )
      ..addOption('concurrency',
        abbr: 'j',
        defaultsTo: math.max<int>(1, platform.numberOfProcessors - 2).toString(),
        help: 'The number of concurrent test processes to run.',
        valueHelp: 'jobs');
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run Flutter unit tests for the current project.';

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    if (!fs.isFileSync('pubspec.yaml')) {
      throwToolExit(
        'Error: No pubspec.yaml file found in the current working directory.\n'
        'Run this command from the root of your project. Test files must be '
        'called *_test.dart and must reside in the package\'s \'test\' '
        'directory (or one of its subdirectories).');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> names = argResults['name'];
    final List<String> plainNames = argResults['plain-name'];

    Iterable<String> files = argResults.rest.map<String>((String testPath) => fs.path.absolute(testPath)).toList();

    final bool startPaused = argResults['start-paused'];
    if (startPaused && files.length != 1) {
      throwToolExit(
        'When using --start-paused, you must specify a single test file to run.',
        exitCode: 1,
      );
    }

    final int jobs = int.tryParse(argResults['concurrency']);
    if (jobs == null || jobs <= 0 || !jobs.isFinite) {
      throwToolExit(
        'Could not parse -j/--concurrency argument. It must be an integer greater than zero.'
      );
    }

    Directory workDir;
    if (files.isEmpty) {
      // We don't scan the entire package, only the test/ subdirectory, so that
      // files with names like like "hit_test.dart" don't get run.
      workDir = fs.directory('test');
      if (!workDir.existsSync())
        throwToolExit('Test directory "${workDir.path}" not found.');
      files = _findTests(workDir).toList();
      if (files.isEmpty) {
        throwToolExit(
            'Test directory "${workDir.path}" does not appear to contain any test files.\n'
            'Test files must be in that directory and end with the pattern "_test.dart".'
        );
      }
    }

    CoverageCollector collector;
    if (argResults['coverage'] || argResults['merge-coverage']) {
      collector = CoverageCollector();
    }

    final bool machine = argResults['machine'];
    if (collector != null && machine) {
      throwToolExit("The test command doesn't support --machine and coverage together");
    }

    TestWatcher watcher;
    if (collector != null) {
      watcher = collector;
    } else if (machine) {
      watcher = EventPrinter();
    }

    Cache.releaseLockEarly();

    final int result = await runTests(
      files,
      workDir: workDir,
      names: names,
      plainNames: plainNames,
      watcher: watcher,
      enableObservatory: collector != null || startPaused,
      startPaused: startPaused,
      ipv6: argResults['ipv6'],
      machine: machine,
      trackWidgetCreation: argResults['track-widget-creation'],
      updateGoldens: argResults['update-goldens'],
      concurrency: jobs,
    );

    if (collector != null) {
      if (!await collector.collectCoverageData(
          argResults['coverage-path'], mergeCoverageData: argResults['merge-coverage']))
        throwToolExit(null);
    }

    if (result != 0)
      throwToolExit(null);
    return const FlutterCommandResult(ExitStatus.success);
  }
}

Iterable<String> _findTests(Directory directory) {
  return directory.listSync(recursive: true, followLinks: false)
      .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart') &&
      fs.isFileSync(entity.path))
      .map((FileSystemEntity entity) => fs.path.absolute(entity.path));
}
