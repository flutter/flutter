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

/// Class that represents a pending task of coverage data collection.
/// Instances of this class are obtained when a process starts running code
/// by calling [CoverageCollector.addTask]. Then, when the code has run to
/// completion (all the coverage data has been recorded), the task is started
/// to actually collect the coverage data.
abstract class CoverageCollectionTask {
  /// Starts the task of collecting coverage. Returns a future that completes
  /// when coverage has been collected.
  ///
  /// This should be called when the code whose coverage data is being
  /// collected has been run to completion so that all coverage data has been
  /// recorded.
  Future<Null> start();

  /// Indicates whether the task has been started or not.
  bool get isStarted;
}

/// Singleton class that's used to collect coverage data during tests.
class CoverageCollector {
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
  /// If this collector is not [enabled], the task will still be added to the
  /// pending queue. Only when the task is started will the enabled state of
  /// the collector be consulted.
  CoverageCollectionTask addTask({
    String host,
    int port,
    Process processToKill,
  }) {
    final _Task task = new _Task(this, host, port, processToKill);
    _tasks.add(task.future);
    return task;
  }

  List<Future<Null>> _tasks = <Future<Null>>[];
  Map<String, dynamic> _globalHitmap;

  Future<Null> _startTask(_Task task) async {
    assert(!task.isStarted);
    if (!enabled) {
      task.processToKill.kill();
      return;
    }

    int pid = task.processToKill.pid;
    printTrace('collecting coverage data from pid $pid on port ${task.port}');
    Map<String, dynamic> data = await collect(task.host, task.port, false, false);
    printTrace('done collecting coverage data from pid $pid');
    task.processToKill.kill();
    Map<String, dynamic> hitmap = createHitmap(data['coverage']);
    if (_globalHitmap == null)
      _globalHitmap = hitmap;
    else
      mergeHitmaps(hitmap, _globalHitmap);
    printTrace('done merging data from pid $pid into global coverage map');
    task._completer.complete();
  }

  /// Returns a future that completes once all tasks have finished.
  /// This will not start any tasks that were not already started.
  ///
  /// If [timeout] is specified, the future will timeout (with a
  /// [TimeoutException]) after the specified duration.
  Future<Null> finishPendingTasks({ Duration timeout }) {
    Future<Null> future = Future.wait(_tasks, eagerError: true);
    if (timeout != null) {
      future = future.timeout(timeout);
    }
    return future;
  }

  /// Returns a future that will complete with the formatted coverage data
  /// (using [formatter]) once all coverage data has been collected.
  ///
  /// Note: this will not start any collection tasks. It us up to the caller
  /// of [addTask] to maintain a reference to the [CoverageCollectionTask]
  /// and call `start` on the task once the code in question has run. Failure
  /// to do so will keep this future from completing.
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

class _Task implements CoverageCollectionTask {
  final Completer<Null> _completer = new Completer<Null>();
  final CoverageCollector collector;
  final String host;
  final int port;
  final Process processToKill;

  bool _started = false;

  _Task(this.collector, this.host, this.port, this.processToKill);

  @override
  Future<Null> start() {
    if (!_started) {
      _started = true;
      collector._startTask(this);
    }
    return future;
  }

  @override
  bool get isStarted => _started;

  Future<Null> get future => _completer.future;
}
