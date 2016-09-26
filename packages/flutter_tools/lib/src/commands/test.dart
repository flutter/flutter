// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/src/executable.dart' as executable; // ignore: implementation_imports

import '../base/logger.dart';
import '../base/os.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../test/coverage_collector.dart';
import '../test/flutter_platform.dart' as loader;
import '../toolchain.dart';

class TestCommand extends FlutterCommand {
  TestCommand() {
    usesPubOption();
    argParser.addFlag('coverage',
      defaultsTo: false,
      negatable: false,
      help: 'Whether to collect coverage information.'
    );
    argParser.addFlag('merge-coverage',
      defaultsTo: false,
      negatable: false,
      help: 'Whether to merge converage data with "coverage/lcov.base.info". '
            'Implies collecting coverage data. (Requires lcov)'
    );
    argParser.addOption('coverage-path',
      defaultsTo: 'coverage/lcov.info',
      help: 'Where to store coverage information (if coverage is enabled).'
    );
    commandValidator = () {
      if (!FileSystemEntity.isFileSync('pubspec.yaml')) {
        printError(
          'Error: No pubspec.yaml file found in the current working directory.\n'
          'Run this command from the root of your project. Test files must be\n'
          'called *_test.dart and must reside in the package\'s \'test\'\n'
          'directory (or one of its subdirectories).');
        return false;
      }
      return true;
    };
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run Flutter unit tests for the current project.';

  Iterable<String> _findTests(Directory directory) {
    return directory.listSync(recursive: true, followLinks: false)
                    .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart') &&
                      FileSystemEntity.isFileSync(entity.path))
                    .map((FileSystemEntity entity) => path.absolute(entity.path));
  }

  Directory get _currentPackageTestDir {
    // We don't scan the entire package, only the test/ subdirectory, so that
    // files with names like like "hit_test.dart" don't get run.
    return new Directory('test');
  }

  Future<int> _runTests(List<String> testArgs, Directory testDirectory) async {
    Directory currentDirectory = Directory.current;
    try {
      if (testDirectory != null) {
        printTrace('switching to directory $testDirectory to run tests');
        PackageMap.globalPackagesPath = path.normalize(path.absolute(PackageMap.globalPackagesPath));
        Directory.current = testDirectory;
      }
      printTrace('running test package with arguments: $testArgs');
      await executable.main(testArgs);
      printTrace('test package returned with exit code $exitCode');

      return exitCode;
    } finally {
      Directory.current = currentDirectory;
    }
  }

  Future<bool> _collectCoverageData(CoverageCollector collector, { bool mergeCoverageData: false }) async {
    Status status = logger.startProgress('Collecting coverage information...');
    String coverageData = await collector.finalizeCoverage();
    status.stop(showElapsedTime: true);
    if (coverageData == null)
      return false;

    String coveragePath = argResults['coverage-path'];
    File coverageFile = new File(coveragePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(coverageData, flush: true);
    printTrace('wrote coverage data to $coveragePath (size=${coverageData.length})');

    String baseCoverageData = 'coverage/lcov.base.info';
    if (mergeCoverageData) {
      if (!os.isLinux) {
        printError(
          'Merging coverage data is supported only on Linux because it '
          'requires the "lcov" tool.'
        );
        return false;
      }

      if (!FileSystemEntity.isFileSync(baseCoverageData)) {
        printError('Missing "$baseCoverageData". Unable to merge coverage data.');
        return false;
      }

      if (os.which('lcov') == null) {
        String installMessage = 'Please install lcov.';
        if (os.isLinux)
          installMessage = 'Consider running "sudo apt-get install lcov".';
        else if (os.isMacOS)
          installMessage = 'Consider running "brew install lcov".';
        printError('Missing "lcov" tool. Unable to merge coverage data.\n$installMessage');
        return false;
      }

      Directory tempDir = Directory.systemTemp.createTempSync('flutter_tools');
      try {
        File sourceFile = coverageFile.copySync(path.join(tempDir.path, 'lcov.source.info'));
        ProcessResult result = Process.runSync('lcov', <String>[
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
  Future<int> runCommand() async {
    List<String> testArgs = argResults.rest.map((String testPath) => path.absolute(testPath)).toList();

    if (!commandValidator())
      return 1;

    Directory testDir;

    if (testArgs.isEmpty) {
      testDir = _currentPackageTestDir;
      if (!testDir.existsSync()) {
        printError("Test directory '${testDir.path}' not found.");
        return 1;
      }

      testArgs.addAll(_findTests(testDir));
    }

    testArgs.insert(0, '--');
    if (!terminal.supportsColor)
      testArgs.insertAll(0, <String>['--no-color', '-rexpanded']);

    if (argResults['coverage'])
      testArgs.insert(0, '--concurrency=1');

    loader.installHook();
    loader.shellPath = tools.getHostToolPath(HostTool.SkyShell);
    if (!FileSystemEntity.isFileSync(loader.shellPath)) {
        printError('Cannot find Flutter shell at ${loader.shellPath}');
      return 1;
    }

    Cache.releaseLockEarly();

    CoverageCollector collector = CoverageCollector.instance;
    collector.enabled = argResults['coverage'] || argResults['merge-coverage'];

    int result = await _runTests(testArgs, testDir);

    if (collector.enabled) {
      if (!await _collectCoverageData(collector, mergeCoverageData: argResults['merge-coverage']))
        return 1;
    }

    return result;
  }
}
