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
  ///
  /// A task may only be started once.
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
  /// called or [finalizeCoverage] is called (which implicitly starts all
  /// pending tasks).
  ///
  /// If this collector is not [enabled], the task will still be added to the
  /// pending queue. Only when the task is started will the enabled state of
  /// the collector be consulted.
  CoverageCollectionTask addTask({
    String host,
    int port,
    Process processToKill,
  }) {
    _Task task = new _Task(this, host, port, processToKill);
    _pendingTasks.add(task);
    return task;
  }

  Set<_Task> _pendingTasks = new Set<_Task>();
  List<Future<Null>> _activeTasks = <Future<Null>>[];
  Map<String, dynamic> _globalHitmap;

  Future<Null> _startTask(_Task task) async {
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
  }

  /// Returns a future that completes once all started tasks are finished.
  /// This will not start any tasks that were not already started.
  Future<Null> finishActiveTasks() async {
    await Future.wait(_activeTasks, eagerError: true);
  }

  /// Completes all pending collection of coverage data. This will start any
  /// tasks that have not yet been started. Returns a future that will complete
  /// with the formatted coverage data (using [formatter]) once all coverage
  /// data has been collected.
  ///
  /// This must only be called if this collector is [enabled].
  Future<String> finalizeCoverage({ Formatter formatter }) async {
    assert(enabled);
    while (_pendingTasks.isNotEmpty) {
      _pendingTasks.first.start();
    }
    await finishActiveTasks();
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
  final CoverageCollector collector;
  final String host;
  final int port;
  final Process processToKill;

  _Task(this.collector, this.host, this.port, this.processToKill);

  @override
  Future<Null> start() {
    if (!collector._pendingTasks.remove(this))
      throw new AssertionError();
    Future<Null> future = collector._startTask(this);
    collector._activeTasks.add(future);
    return future;
  }

  @override
  bool get isStarted => !collector._pendingTasks.contains(this);
}
