// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import 'environment.dart';
import 'utils.dart';

class BuildCommand extends Command<bool> with ArgUtils {
  BuildCommand() {
    argParser
      ..addFlag(
        'watch',
        abbr: 'w',
        help: 'Run the build in watch mode so it rebuilds whenever a change'
            'is made.',
      )
      ..addOption(
        'ninja-jobs',
        abbr: 'j',
        help: 'Number of parallel jobs to use in the ninja build.',
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => 'Build the Flutter web engine.';

  bool get isWatchMode => boolArg('watch');

  int getNinjaJobCount() => intArg('ninja-jobs');

  @override
  FutureOr<bool> run() async {
    final int ninjaJobCount = getNinjaJobCount();
    final FilePath libPath = FilePath.fromWebUi('lib');
    final Pipeline buildPipeline = Pipeline(steps: <PipelineStep>[
      gn,
      () => ninja(ninjaJobCount),
    ]);
    await buildPipeline.start();

    if (isWatchMode) {
      print('Initial build done!');
      print('Watching directory: ${libPath.relativeToCwd}/');
      PipelineWatcher(
        dir: libPath.absolute,
        pipeline: buildPipeline,
        // Ignore font files that are copied whenever tests run.
        ignore: (event) => event.path.endsWith('.ttf'),
      ).start();
      // Return a never-ending future.
      return Completer<bool>().future;
    } else {
      return true;
    }
  }
}

Future<void> gn() {
  print('Running gn...');
  return runProcess(
    path.join(environment.flutterDirectory.path, 'tools', 'gn'),
    <String>[
      '--unopt',
      '--full-dart-sdk',
    ],
  );
}

// TODO(mdebbar): Make the ninja step interruptable in the pipeline.
Future<void> ninja(int ninjaJobs) {
  if (ninjaJobs == null) {
    print('Running ninja (with default ninja parallelization)...');
  } else {
    print('Running ninja (with $ninjaJobs parallel jobs)...');
  }

  return runProcess('ninja', <String>[
    '-C',
    environment.hostDebugUnoptDir.path,
    if (ninjaJobs != null) ...['-j', '$ninjaJobs'],
  ]);
}

enum PipelineStatus {
  idle,
  started,
  stopping,
  stopped,
  error,
  done,
}

typedef PipelineStep = Future<void> Function();

class Pipeline {
  Pipeline({@required this.steps});

  final Iterable<PipelineStep> steps;

  Future<dynamic> _currentStepFuture;

  PipelineStatus status = PipelineStatus.idle;

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

  Future<void> stop() {
    status = PipelineStatus.stopping;
    return (_currentStepFuture ?? Future<void>.value(null)).then((_) {
      status = PipelineStatus.stopped;
    });
  }
}

typedef WatchEventPredicate = bool Function(WatchEvent event);

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
