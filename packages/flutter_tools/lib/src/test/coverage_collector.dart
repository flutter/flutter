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
  /// The singleton instance of the coverage collector.
  static final CoverageCollector instance = new CoverageCollector._();

  CoverageCollector._();

  /// By default, coverage collection is not enabled. Set [enabled] to true
  /// to turn on coverage collection.
  bool enabled = false;
  int observatoryPort;

  /// Adds a coverage collection tasks to the pending queue. The task will not
  /// begin collecting coverage data until [CoverageCollectionTask.start] is
  /// called.
  ///
  /// This should be called after a process has been started so that this
  /// collector knows to wait for the task in [finalizeCoverage].
  ///
  /// If this collector is not [enabled], the task will still be added to the
  /// pending queue. Only when the task is started will the enabled state of
  /// the collector be consulted.
  CoverageCollectionTask addTask({
    String host,
    int port,
    Process processToKill,
  }) {
    final CoverageCollectionTask task = new CoverageCollectionTask(
      this,
      host,
      port,
      processToKill,
    );
    _tasks.add(task._future);
    return task;
  }

  List<Future<Null>> _tasks = <Future<Null>>[];
  Map<String, dynamic> _globalHitmap;

  void _addHitmap(Map<String, dynamic> hitmap) {
    if (_globalHitmap == null)
      _globalHitmap = hitmap;
    else
      mergeHitmaps(hitmap, _globalHitmap);
  }

  /// Returns a future that completes once all tasks have finished.
  /// This will not start any tasks that were not already started.
  ///
  /// If [timeout] is specified, the future will timeout (with a
  /// [TimeoutException]) after the specified duration.
  Future<Null> finishPendingTasks({ Duration timeout }) {
    Future<dynamic> future = Future.wait(_tasks, eagerError: true);
    if (timeout != null)
      future = future.timeout(timeout);
    return future;
  }

  /// Returns a future that will complete with the formatted coverage data
  /// (using [formatter]) once all coverage data has been collected.
  ///
  /// This will not start any collection tasks. It us up to the caller of
  /// [addTask] to maintain a reference to the [CoverageCollectionTask] and
  /// call `start` on the task once the code in question has run. Failure to do
  /// so will cause this method to wait indefinitely for the task.
  ///
  /// If [timeout] is specified, the future will timeout (with a
  /// [TimeoutException]) after the specified duration.
  ///
  /// This must only be called if this collector is [enabled].
  Future<String> finalizeCoverage({
    Formatter formatter,
    Duration timeout,
  }) async {
    assert(enabled);
    await finishPendingTasks(timeout: timeout);
    printTrace('formating coverage data');
    if (_globalHitmap == null)
      return null;
    if (formatter == null) {
      Resolver resolver = new Resolver(packagesPath: PackageMap.globalPackagesPath);
      String packagePath = fs.currentDirectory.path;
      List<String> reportOn = <String>[path.join(packagePath, 'lib')];
      formatter = new LcovFormatter(resolver, reportOn: reportOn, basePath: packagePath);
    }
    return await formatter.format(_globalHitmap);
  }
}

/// A class that represents a pending task of coverage data collection.
/// Instances of this class are obtained when a process starts running code
/// by calling [CoverageCollector.addTask]. Then, when the code has run to
/// completion (all the coverage data has been recorded), the task is started
/// to actually collect the coverage data.
class CoverageCollectionTask {
  final Completer<Null> _completer = new Completer<Null>();
  final CoverageCollector _collector;
  final String _host;
  final int _port;
  final Process _processToKill;

  CoverageCollectionTask(
    this._collector,
    this._host,
    this._port,
    this._processToKill,
  );

  bool _started = false;

  Future<Null> get _future => _completer.future;

  /// Starts the task of collecting coverage.
  ///
  /// This should be called when the code whose coverage data is being collected
  /// has been run to completion so that all coverage data has been recorded.
  /// Failure to do so will cause [CoverageCollector.finalizeCoverage] to wait
  /// indefinitely for the task to complete.
  ///
  /// Each task may only be started once.
  void start() {
    assert(!_started);
    _started = true;

    if (!_collector.enabled) {
      _processToKill.kill();
      _completer.complete();
      return;
    }

    int pid = _processToKill.pid;
    printTrace('collecting coverage data from pid $pid on port $_port');
    collect(_host, _port, false, false).then(
      (Map<dynamic, dynamic> data) {
        printTrace('done collecting coverage data from pid $pid');
        _processToKill.kill();
        try {
          _collector._addHitmap(createHitmap(data['coverage']));
          printTrace('done merging data from pid $pid into global coverage map');
          _completer.complete();
        } catch (error, stackTrace) {
          _completer.completeError(error, stackTrace);
        }
      },
      onError: (dynamic error, StackTrace stackTrace) {
        _completer.completeError(error, stackTrace);
      },
    );
  }
}
