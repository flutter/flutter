// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:coverage/coverage.dart';
import 'package:path/path.dart' as path;

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
      mergeHitmaps(hitmap, _globalHitmap);
  }

  /// Collects coverage for the given [Process] using the given `port`.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  ///
  /// The returned [Future] completes when the coverage is collected.
  Future<Null> collectCoverage(Process process, InternetAddress host, int port) async {
    assert(process != null);
    assert(port != null);

    int pid = process.pid;
    int exitCode;
    process.exitCode.then<Null>((int code) {
      exitCode = code;
    });

    printTrace('pid $pid (port $port): collecting coverage data...');
    final Map<String, dynamic> data = await collect(host.address, port, false, false);
    printTrace('pid $pid (port $port): ${ exitCode != null ? "process terminated prematurely with exit code $exitCode; aborting" : "collected coverage data; merging..." }');
    if (exitCode != null)
      throw new Exception('Failed to collect coverage, process terminated prematurely.');
    _addHitmap(createHitmap(data['coverage']));
    printTrace('pid $pid (port $port): done merging coverage data into global coverage map.');
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
    Formatter formatter,
    Duration timeout,
  }) async {
    printTrace('formating coverage data');
    if (_globalHitmap == null)
      return null;
    if (formatter == null) {
      Resolver resolver = new Resolver(packagesPath: PackageMap.globalPackagesPath);
      String packagePath = fs.currentDirectory.path;
      List<String> reportOn = <String>[path.join(packagePath, 'lib')];
      formatter = new LcovFormatter(resolver, reportOn: reportOn, basePath: packagePath);
    }
    String result = await formatter.format(_globalHitmap);
    _globalHitmap = null;
    return result;
  }
}
