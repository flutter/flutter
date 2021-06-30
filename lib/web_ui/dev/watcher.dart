// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import 'utils.dart';

enum PipelineStatus {
  /// The pipeline has not started yet.
  ///
  /// This is the initial state of the pipeline.
  idle,

  /// The pipeline is running build steps.
  started,

  /// The pipeline is stopping.
  stopping,

  /// The pipeline is not running anything because it has been interrupted.
  interrupted,

  /// The pipeline is not running anything because it encountered an error.
  error,

  /// The pipeline is not running anything because it finished all build steps successfully.
  done,
}

/// A step in the build pipeline.
abstract class PipelineStep {
  /// The name of this step.
  ///
  /// This value appears in logs, so it should be descriptive and human-readable.
  String get name;

  /// Whether it is safe to interrupt this step while it's running.
  bool get isSafeToInterrupt;

  /// Runs this step.
  ///
  /// The returned future is completed when the step is finished. The future
  /// completes with an error if the step failed.
  Future<void> run();

  /// Interrupts this step, if it's already running.
  ///
  /// [Pipeline] only calls this if [isSafeToInterrupt] returns true.
  Future<void> interrupt();
}

/// A helper class for implementing [PipelineStep] in terms of a process.
abstract class ProcessStep implements PipelineStep {
  ProcessManager? _process;
  bool _isInterrupted = false;

  /// Starts and returns the process that implements the logic of this pipeline
  /// step.
  Future<ProcessManager> createProcess();

  @override
  Future<void> interrupt() async {
    _isInterrupted = true;
    _process?.kill();
  }

  @override
  Future<void> run() async {
    final ProcessManager process = await createProcess();

    if (_isInterrupted) {
      // If the step was interrupted while creating the process, the
      // `interrupt` won't kill the process; it must be done here.
      process.kill();
      return;
    }

    _process = process;
    await process.wait();
    _process = null;
  }
}

/// Represents a sequence of asynchronous tasks to be executed.
///
/// The pipeline can be executed by calling [start] and stopped by calling
/// [stop].
///
/// When a pipeline is stopped, it switches to the [PipelineStatus.stopping]
/// state and waits until the current task finishes.
class Pipeline {
  Pipeline({required this.steps});

  final Iterable<PipelineStep> steps;

  PipelineStep? _currentStep;
  Future<void>? _currentStepFuture;

  PipelineStatus get status => _status;
  PipelineStatus _status = PipelineStatus.idle;

  /// Starts executing tasks of the pipeline.
  ///
  /// Returns a future that resolves after all steps have been performed.
  Future<void> start() async {
    _status = PipelineStatus.started;
    try {
      for (PipelineStep step in steps) {
        if (status != PipelineStatus.started) {
          break;
        }
        _currentStep = step;
        _currentStepFuture = step.run();
        await _currentStepFuture;
      }
      _status = PipelineStatus.done;
    } catch (error, stackTrace) {
      _status = PipelineStatus.error;
      print('Error in the pipeline: $error');
      print(stackTrace);
    } finally {
      _currentStep = null;
    }
  }

  /// Stops executing any more tasks in the pipeline.
  ///
  /// Tasks that are safe to interrupt (according to [PipelineStep.isSafeToInterrupt]),
  /// are interrupted. Otherwise, waits for the current step to finish before
  /// interrupting the pipeline.
  Future<void> stop() async {
    _status = PipelineStatus.stopping;
    final PipelineStep? step = _currentStep;
    if (step == null) {
      _status = PipelineStatus.interrupted;
      return;
    }
    if (step.isSafeToInterrupt) {
      print('Interrupting ${step.name}');
      await step.interrupt();
      _status = PipelineStatus.interrupted;
      return;
    }
    print('${step.name} cannot be interrupted. Waiting for it to complete.');
    await _currentStepFuture;
    _status = PipelineStatus.interrupted;
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
    required this.dir,
    required this.pipeline,
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
  final WatchEventPredicate? ignore;

  /// Activates the watcher.
  Future<void> start() async {
    watcher.events.listen(_onEvent);

    // Listen to the `q` key stroke to stop the pipeline.
    print('Press \'q\' to exit felt');

    // Key strokes should be reported immediately and one at a time rather than
    // wait for the user to hit ENTER and report the whole line. To achieve
    // that, echo mode and line mode must be disabled.
    io.stdin.echoMode = false;
    io.stdin.lineMode = false;

    await io.stdin.firstWhere((List<int> event) {
      const int qKeyCode = 113;
      final bool qEntered = event.isNotEmpty && event.first == qKeyCode;
      return qEntered;
    });
    print('Stopping felt');
    await pipeline.stop();
  }

  int _pipelineRunCount = 0;
  Timer? _scheduledPipeline;

  void _onEvent(WatchEvent event) {
    if (ignore?.call(event) == true) {
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
      print('Press \'q\' to exit felt');
    }
  }
}
