// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../test/coverage_collector.dart';
import '../test/event_printer.dart';
import '../test/runner.dart';
import '../test/watcher.dart';

class TestCommand extends FlutterCommand {
  TestCommand({ bool verboseHelp: false }) {
    requiresPubspecYaml();
    usesPubOption();
    argParser.addMultiOption(
      'name',
      help: 'A regular expression matching substrings of the names of tests to run.',
      valueHelp: 'regexp',
      splitCommas: false,
    );
    argParser.addMultiOption(
      'plain-name',
      help: 'A plain-text substring of the names of tests to run.',
      valueHelp: 'substring',
      splitCommas: false,
    );
    argParser.addFlag(
      'start-paused',
      defaultsTo: false,
      negatable: false,
      help: 'Start in a paused mode and wait for a debugger to connect.\n'
            'You must specify a single test file to run, explicitly.\n'
            'Instructions for connecting with a debugger and printed to the\n'
            'console once the test has started.',
    );
    argParser.addFlag(
      'coverage',
      defaultsTo: false,
      negatable: false,
      help: 'Whether to collect coverage information.',
    );
    argParser.addFlag(
      'merge-coverage',
      defaultsTo: false,
      negatable: false,
      help: 'Whether to merge coverage data with "coverage/lcov.base.info".\n'
            'Implies collecting coverage data. (Requires lcov)',
    );
    argParser.addFlag(
      'ipv6',
      negatable: false,
      hide: true,
      help: 'Whether to use IPv6 for the test harness server socket.',
    );
    argParser.addOption(
      'coverage-path',
      defaultsTo: 'coverage/lcov.info',
      help: 'Where to store coverage information (if coverage is enabled).',
    );
    argParser.addFlag(
      'machine',
      hide: !verboseHelp,
      negatable: false,
      help: 'Handle machine structured JSON command input\n'
            'and provide output and progress in machine friendly format.',
    );
    argParser.addFlag(
      'preview-dart-2',
      hide: !verboseHelp,
      help: 'Preview Dart 2.0 functionality.',
    );
    argParser.addFlag(
      'track-widget-creation',
      negatable: false,
      hide: !verboseHelp,
      help: 'Track widget creation locations.\n'
            'This enables testing of features such as the widget inspector.',
    );
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run Flutter unit tests for the current project.';

  Future<bool> _collectCoverageData(CoverageCollector collector, { bool mergeCoverageData: false }) async {
    final Status status = logger.startProgress('Collecting coverage information...');
    final String coverageData = await collector.finalizeCoverage(
      timeout: const Duration(seconds: 30),
    );
    status.stop();
    printTrace('coverage information collection complete');
    if (coverageData == null)
      return false;

    final String coveragePath = argResults['coverage-path'];
    final File coverageFile = fs.file(coveragePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(coverageData, flush: true);
    printTrace('wrote coverage data to $coveragePath (size=${coverageData.length})');

    const String baseCoverageData = 'coverage/lcov.base.info';
    if (mergeCoverageData) {
      if (!platform.isLinux) {
        printError(
          'Merging coverage data is supported only on Linux because it '
          'requires the "lcov" tool.'
        );
        return false;
      }

      if (!fs.isFileSync(baseCoverageData)) {
        printError('Missing "$baseCoverageData". Unable to merge coverage data.');
        return false;
      }

      if (os.which('lcov') == null) {
        String installMessage = 'Please install lcov.';
        if (platform.isLinux)
          installMessage = 'Consider running "sudo apt-get install lcov".';
        else if (platform.isMacOS)
          installMessage = 'Consider running "brew install lcov".';
        printError('Missing "lcov" tool. Unable to merge coverage data.\n$installMessage');
        return false;
      }

      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_tools');
      try {
        final File sourceFile = coverageFile.copySync(fs.path.join(tempDir.path, 'lcov.source.info'));
        final ProcessResult result = processManager.runSync(<String>[
          'lcov',
          '--add-tracefile', baseCoverageData,
          '--add-tracefile', sourceFile.path,
          '--output-file', coverageFile.path,
        ]);
        if (result.exitCode != 0)
          return false;
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    }
    return true;
  }

  @override
  Future<Null> validateCommand() async {
    await super.validateCommand();
    if (!fs.isFileSync('pubspec.yaml')) {
      throwToolExit(
          'Error: No pubspec.yaml file found in the current working directory.\n'
              'Run this command from the root of your project. Test files must be\n'
              'called *_test.dart and must reside in the package\'s \'test\'\n'
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
          exitCode: 1);
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
      collector = new CoverageCollector();
    }

    final bool machine = argResults['machine'];
    if (collector != null && machine) {
      throwToolExit(
          "The test command doesn't support --machine and coverage together");
    }

    TestWatcher watcher;
    if (collector != null) {
      watcher = collector;
    } else if (machine) {
      watcher = new EventPrinter();
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
      previewDart2: argResults['preview-dart-2'],
      trackWidgetCreation: argResults['track-widget-creation'],
    );

    if (collector != null) {
      if (!await _collectCoverageData(collector, mergeCoverageData: argResults['merge-coverage']))
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
