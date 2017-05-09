// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:coverage/coverage.dart' as coverage;

import '../base/file_system.dart';
import '../base/io.dart';
import '../dart/package_map.dart';
import '../globals.dart';

/// A class that's used to collect coverage data during tests.
class CoverageCollector {
  Map<String, dynamic> _globalHitmap;

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
    process.exitCode.then<Null>((int code) {
      exitCode = code;
    });
    if (exitCode != null)
      throw new Exception('Failed to collect coverage, process terminated before coverage could be collected.');

    printTrace('pid $pid: collecting coverage data from $observatoryUri...');
    final Map<String, dynamic> data = await coverage
        .collect(observatoryUri, false, false)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw new Exception('Failed to collect coverage, it took more than thirty seconds.');
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
}
