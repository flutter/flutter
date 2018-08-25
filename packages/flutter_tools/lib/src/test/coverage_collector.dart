// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:coverage/coverage.dart' as coverage;

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../dart/package_map.dart';
import '../globals.dart';

import 'watcher.dart';

/// A class that's used to collect coverage data during tests.
class CoverageCollector extends TestWatcher {
  Map<String, dynamic> _globalHitmap;

  @override
  Future<void> handleFinishedTest(ProcessEvent event) async {
    printTrace('test ${event.childIndex}: collecting coverage');
    await collectCoverage(event.process, event.observatoryUri);
  }

  void _addHitmap(Map<String, dynamic> hitmap) {
    if (_globalHitmap == null)
      _globalHitmap = hitmap;
    else
      coverage.mergeHitmaps(hitmap, _globalHitmap);
  }

  /// Collects coverage for the given [Process] using the given `port`.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  ///
  /// The returned [Future] completes when the coverage is collected.
  Future<Null> collectCoverage(Process process, Uri observatoryUri) async {
    assert(process != null);
    assert(observatoryUri != null);

    final int pid = process.pid;
    int exitCode;
    // Synchronization is enforced by the API contract. Error handling
    // synchronization is done in the code below where `exitCode` is checked.
    // Callback cannot throw.
    process.exitCode.then<Null>((int code) { // ignore: unawaited_futures
      exitCode = code;
    });
    if (exitCode != null)
      throw new Exception('Failed to collect coverage, process terminated before coverage could be collected.');

    printTrace('pid $pid: collecting coverage data from $observatoryUri...');
    final Map<String, dynamic> data = await coverage
        .collect(observatoryUri, false, false)
        .timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw new Exception('Timed out while collecting coverage.');
          },
        );
    printTrace(() {
      final StringBuffer buf = new StringBuffer()
          ..write('pid $pid ($observatoryUri): ')
          ..write(exitCode == null
              ? 'collected coverage data; merging...'
              : 'process terminated prematurely with exit code $exitCode; aborting');
      return buf.toString();
    }());
    if (exitCode != null)
      throw new Exception('Failed to collect coverage, process terminated while coverage was being collected.');
    _addHitmap(coverage.createHitmap(data['coverage']));
    printTrace('pid $pid ($observatoryUri): done merging coverage data into global coverage map.');
  }

  /// Returns a future that will complete with the formatted coverage data
  /// (using [formatter]) once all coverage data has been collected.
  ///
  /// This will not start any collection tasks. It us up to the caller of to
  /// call [collectCoverage] for each process first.
  ///
  /// If [timeout] is specified, the future will timeout (with a
  /// [TimeoutException]) after the specified duration.
  Future<String> finalizeCoverage({
    coverage.Formatter formatter,
    Duration timeout,
  }) async {
    printTrace('formating coverage data');
    if (_globalHitmap == null)
      return null;
    if (formatter == null) {
      final coverage.Resolver resolver = new coverage.Resolver(packagesPath: PackageMap.globalPackagesPath);
      final String packagePath = fs.currentDirectory.path;
      final List<String> reportOn = <String>[fs.path.join(packagePath, 'lib')];
      formatter = new coverage.LcovFormatter(resolver, reportOn: reportOn, basePath: packagePath);
    }
    final String result = await formatter.format(_globalHitmap);
    _globalHitmap = null;
    return result;
  }

  Future<bool> collectCoverageData(String coveragePath, { bool mergeCoverageData = false }) async {
    final Status status = logger.startProgress('Collecting coverage information...');
    final String coverageData = await finalizeCoverage(
      timeout: const Duration(seconds: 30),
    );
    status.stop();
    printTrace('coverage information collection complete');
    if (coverageData == null)
      return false;

    final File coverageFile = fs.file(coveragePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(coverageData, flush: true);
    printTrace('wrote coverage data to $coveragePath (size=${coverageData.length})');

    const String baseCoverageData = 'coverage/lcov.base.info';
    if (mergeCoverageData) {
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

      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_test_coverage.');
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
}
