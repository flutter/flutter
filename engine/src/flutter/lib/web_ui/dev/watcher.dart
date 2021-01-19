// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

enum PipelineStatus {
  idle,
  started,
  stopping,
  stopped,
  error,
  done,
}

typedef PipelineStep = Future<void> Function();

/// Represents a sequence of asynchronous tasks to be executed.
///
/// The pipeline can be executed by calling [start] and stopped by calling
/// [stop].
///
/// When a pipeline is stopped, it switches to the [PipelineStatus.stopping]
/// state and waits until the current task finishes.
class Pipeline {
  Pipeline({@required this.steps});

  final Iterable<PipelineStep> steps;

  Future<dynamic> _currentStepFuture;

  PipelineStatus status = PipelineStatus.idle;

  /// Starts executing tasks of the pipeline.
  Future<void> start() async {
    status = PipelineStatus.started;
    try {
      for (PipelineStep step in steps) {
        if (status != PipelineStatus.started) {
          break;
        }
        _currentStepFuture = step();
        await _currentStepFuture;
      }
      status = PipelineStatus.done;
    } catch (error, stackTrace) {
      status = PipelineStatus.error;
      print('Error in the pipeline: $error');
      print(stackTrace);
    } finally {
      _currentStepFuture = null;
    }
  }

  /// Stops executing any more tasks in the pipeline.
  ///
  /// If a task is already being executed, it won't be interrupted.
  Future<void> stop() {
    status = PipelineStatus.stopping;
    return (_currentStepFuture ?? Future<void>.value(null)).then((_) {
      status = PipelineStatus.stopped;
    });
  }
}

/// Signature of functions to be called when a [WatchEvent] is received.
typedef WatchEventPredicate = bool Function(WatchEvent event);

/// Responsible for watching a directory [dir] and executing the given
/// [pipeline] whenever a change occurs in the directory.
///
/// The [ignore] callback can be used to customize the watching behavior to
/// ignore certain files.
class PipelineWatcher {
  PipelineWatcher({
    @required this.dir,
    @required this.pipeline,
    this.ignore,
  }) : watcher = DirectoryWatcher(dir);

  /// The path of the directory to watch for changes.
  final String dir;

  /// The pipeline to be executed when an event is fired by the watcher.
  final Pipeline pipeline;

  /// Used to watch a directory for any file system changes.
  final DirectoryWatcher watcher;

  /// A callback that determines whether to rerun the pipeline or not for a
  /// given [WatchEvent] instance.
  final WatchEventPredicate ignore;

  /// Activates the watcher.
  void start() {
    watcher.events.listen(_onEvent);
  }

  int _pipelineRunCount = 0;
  Timer _scheduledPipeline;

  void _onEvent(WatchEvent event) {
    if (ignore != null && ignore(event)) {
      return;
    }

    final String relativePath = path.relative(event.path, from: dir);
    print('- [${event.type}] ${relativePath}');

    _pipelineRunCount++;
    _scheduledPipeline?.cancel();
    _scheduledPipeline = Timer(const Duration(milliseconds: 100), () {
      _scheduledPipeline = null;
      _runPipeline();
    });
  }

  void _runPipeline() {
    int runCount;
    switch (pipeline.status) {
      case PipelineStatus.started:
        pipeline.stop().then((_) {
          runCount = _pipelineRunCount;
          pipeline.start().then((_) => _pipelineDone(runCount));
        });
        break;

      case PipelineStatus.stopping:
        // We are already trying to stop the pipeline. No need to do anything.
        break;

      default:
        runCount = _pipelineRunCount;
        pipeline.start().then((_) => _pipelineDone(runCount));
        break;
    }
  }

  void _pipelineDone(int pipelineRunCount) {
    if (pipelineRunCount == _pipelineRunCount) {
      print('*** Done! ***');
    }
  }
}
