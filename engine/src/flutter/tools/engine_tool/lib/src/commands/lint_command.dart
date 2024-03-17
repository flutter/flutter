// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Directory;
import 'dart:math';

import 'package:path/path.dart' as p;

import '../dart_utils.dart';
import '../environment.dart';
import '../logger.dart';
import '../proc_utils.dart';
import '../worker_pool.dart';
import 'command.dart';
import 'flags.dart';

/// The different kind of linters we support.
enum Linter {
  /// Dart linter
  dart,

  /// Java linter
  java,

  /// C/C++ linter
  c,

  /// Python linter
  python
}

class _LinterDescription {
  _LinterDescription(this.linter, this.cwd, this.command);

  final Linter linter;
  final Directory cwd;
  final List<String> command;
}

/// The root 'lint' command.
final class LintCommand extends CommandBase {
  /// Constructs the 'lint' command.
  LintCommand({
    required super.environment,
  }) {
    final String engineFlutterPath = environment.engine.flutterDir.path;
    _linters[Linter.dart] = _LinterDescription(
        Linter.dart, environment.engine.flutterDir, <String>[
      p.join(engineFlutterPath, 'ci', 'analyze.sh'),
      findDartBinDirectory(environment)
    ]);
    _linters[Linter.java] =
        _LinterDescription(Linter.java, environment.engine.flutterDir, <String>[
      findDartBinary(environment), '--disable-dart-dev',
      p.join(engineFlutterPath, 'tools', 'android_lint', 'bin', 'main.dart'),
    ]);
    _linters[Linter.c] = _LinterDescription(
        Linter.c,
        environment.engine.flutterDir,
        <String>[p.join(engineFlutterPath, 'ci', 'clang_tidy.sh')]);
    _linters[Linter.python] = _LinterDescription(
        Linter.python,
        environment.engine.flutterDir,
        <String>[p.join(engineFlutterPath, 'ci', 'pylint.sh')]);
    argParser.addFlag(
      quietFlag,
      abbr: 'q',
      help: 'Prints minimal output',
    );
  }

  final Map<Linter, _LinterDescription> _linters =
      <Linter, _LinterDescription>{};

  @override
  String get name => 'lint';

  @override
  String get description => 'Lint the engine repository.';

  @override
  Future<int> run() async {
    // TODO(loic-sharma): Relax this restriction.
    if (environment.platform.isWindows) {
      environment.logger
          .fatal('lint command is not supported on Windows (for now).');
      return 1;
    }
    final WorkerPool wp =
        WorkerPool(environment, ProcessTaskProgressReporter(environment));

    final Set<ProcessTask> tasks = <ProcessTask>{};
    for (final MapEntry<Linter, _LinterDescription> entry in _linters.entries) {
      tasks.add(ProcessTask(
          entry.key.name, environment, entry.value.cwd, entry.value.command));
    }
    final bool r = await wp.run(tasks);

    final bool quiet = argResults![quietFlag] as bool;
    if (!quiet) {
      environment.logger.status('\nDumping failure logs\n');
      for (final ProcessTask pt in tasks) {
        final ProcessArtifacts pa = pt.processArtifacts;
        if (pa.exitCode == 0) {
          continue;
        }
        environment.logger.status('Linter ${pt.name} found issues:');
        environment.logger.status('${pa.stdout}\n');
        environment.logger.status('${pa.stderr}\n');
      }
    }
    return r ? 0 : 1;
  }
}

/// A WorkerPoolProgressReporter designed to work with ProcessTasks.
class ProcessTaskProgressReporter implements WorkerPoolProgressReporter {
  /// Construct a new reporter.
  ProcessTaskProgressReporter(this._environment);

  final Environment _environment;
  Spinner? _spinner;
  bool _finished = false;
  int _longestName = 0;

  @override
  void onRun(Set<WorkerTask> tasks) {
    for (final WorkerTask task in tasks) {
      _longestName = max(_longestName, task.name.length);
    }
  }

  @override
  void onFinish() {
    _finished = true;
    _updateSpinner(<ProcessTask>[]);
  }

  List<ProcessTask> _makeProcessTaskList(WorkerPool pool) {
    final List<ProcessTask> runningTasks = <ProcessTask>[];
    for (final WorkerTask task in pool.running) {
      if (task is! ProcessTask) {
        continue;
      }
      runningTasks.add(task);
    }
    return runningTasks;
  }

  @override
  void onTaskStart(WorkerPool pool, WorkerTask task) {
    final List<ProcessTask> running = _makeProcessTaskList(pool);
    _updateSpinner(running);
  }

  @override
  void onTaskDone(WorkerPool pool, WorkerTask task, [Object? err]) {
    final List<ProcessTask> running = _makeProcessTaskList(pool);
    task as ProcessTask;
    final ProcessArtifacts pa = task.processArtifacts;
    final String dt = _formatDurationShort(task.runTime);
    if (pa.exitCode != 0) {
      final String paPath = task.processArtifactsPath;
      _environment.logger.clearLine();
      _environment.logger.status(
          'FAIL: ${task.name.padLeft(_longestName)} after $dt [details in $paPath]');
    } else {
      _environment.logger.clearLine();
      _environment.logger
          .status('OKAY: ${task.name.padLeft(_longestName)} after $dt');
    }
    _updateSpinner(running);
  }

  void _updateSpinner(List<ProcessTask> tasks) {
    if (_spinner != null) {
      _spinner!.finish();
      _spinner = null;
    }
    if (_finished) {
      return;
    }
    _environment.logger.clearLine();
    String runStatus = '[';
    for (final ProcessTask pt in tasks) {
      if (runStatus != '[') {
        runStatus += ' ';
      }
      runStatus += pt.name;
    }
    if (tasks.isNotEmpty) {
      runStatus += '...';
    }
    runStatus += ']  ';
    _environment.logger.status('Linting $runStatus', newline: false);
    _spinner = _environment.logger.startSpinner();
  }
}

String _formatDurationShort(Duration dur) {
  int micros = dur.inMicroseconds;
  String r = '';
  if (micros >= Duration.microsecondsPerMinute) {
    final int minutes = micros ~/ Duration.microsecondsPerMinute;
    micros -= minutes * Duration.microsecondsPerMinute;
    r += '${minutes}m';
  }
  if (micros >= Duration.microsecondsPerSecond) {
    final int seconds = micros ~/ Duration.microsecondsPerSecond;
    micros -= seconds * Duration.microsecondsPerSecond;
    if (r.isNotEmpty) {
      r += '.';
    }
    r += '${seconds}s';
  }
  if (micros >= Duration.microsecondsPerMillisecond) {
    final int millis = micros ~/ Duration.microsecondsPerMillisecond;
    micros -= millis * Duration.microsecondsPerMillisecond;
    if (r.isNotEmpty) {
      r += '.';
    }
    r += '${millis}ms';
  }
  return r;
}
