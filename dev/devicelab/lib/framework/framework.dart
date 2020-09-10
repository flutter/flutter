// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'running_processes.dart';
import 'utils.dart';

/// Represents a unit of work performed in the CI environment that can
/// succeed, fail and be retried independently of others.
typedef TaskFunction = Future<TaskResult> Function();

bool _isTaskRegistered = false;

/// Registers a [task] to run, returns the result when it is complete.
///
/// The task does not run immediately but waits for the request via the
/// VM service protocol to run it.
///
/// It is OK for a [task] to perform many things. However, only one task can be
/// registered per Dart VM.
Future<TaskResult> task(TaskFunction task) {
  if (_isTaskRegistered)
    throw StateError('A task is already registered');

  _isTaskRegistered = true;

  // TODO(ianh): allow overriding logging.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  final _TaskRunner runner = _TaskRunner(task);
  runner.keepVmAliveUntilTaskRunRequested();
  return runner.whenDone;
}

class _TaskRunner {
  _TaskRunner(this.task) {
    registerExtension('ext.cocoonRunTask',
        (String method, Map<String, String> parameters) async {
      final Duration taskTimeout = parameters.containsKey('timeoutInMinutes')
        ? Duration(minutes: int.parse(parameters['timeoutInMinutes']))
        : null;
      final TaskResult result = await run(taskTimeout);
      return ServiceExtensionResponse.result(json.encode(result.toJson()));
    });
    registerExtension('ext.cocoonRunnerReady',
        (String method, Map<String, String> parameters) async {
      return ServiceExtensionResponse.result('"ready"');
    });
  }

  final TaskFunction task;

  // TODO(ianh): workaround for https://github.com/dart-lang/sdk/issues/23797
  RawReceivePort _keepAlivePort;
  Timer _startTaskTimeout;
  bool _taskStarted = false;

  final Completer<TaskResult> _completer = Completer<TaskResult>();

  static final Logger logger = Logger('TaskRunner');

  /// Signals that this task runner finished running the task.
  Future<TaskResult> get whenDone => _completer.future;

  Future<TaskResult> run(Duration taskTimeout) async {
    try {
      _taskStarted = true;
      print('Running task with a timeout of $taskTimeout.');
      final String exe = Platform.isWindows ? '.exe' : '';
      section('Checking running Dart$exe processes');
      final Set<RunningProcessInfo> beforeRunningDartInstances = await getRunningProcesses(
        processName: 'dart$exe',
      ).toSet();
      beforeRunningDartInstances.forEach(print);

      print('enabling configs for macOS, Linux, Windows, and Web...');
      final int configResult = await exec(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
        'config',
        '--enable-macos-desktop',
        '--enable-windows-desktop',
        '--enable-linux-desktop',
        '--enable-web'
      ]);
      if (configResult != 0) {
        print('Failed to enable configuration, tasks may not run.');
      }

      Future<TaskResult> futureResult = _performTask();
      if (taskTimeout != null)
        futureResult = futureResult.timeout(taskTimeout);

      TaskResult result = await futureResult;

      section('Checking running Dart$exe processes after task...');
      final List<RunningProcessInfo> afterRunningDartInstances = await getRunningProcesses(
        processName: 'dart$exe',
      ).toList();
      for (final RunningProcessInfo info in afterRunningDartInstances) {
        if (!beforeRunningDartInstances.contains(info)) {
          print('$info was leaked by this test.');
          if (result is TaskResultCheckProcesses) {
            result = TaskResult.failure('This test leaked dart processes');
          }
          final bool killed = await killProcess(info.pid);
          if (!killed) {
            print('Failed to kill process ${info.pid}.');
          } else {
            print('Killed process id ${info.pid}.');
          }
        }
      }

      _completer.complete(result);
      return result;
    } on TimeoutException catch (err, stackTrace) {
      print('Task timed out in framework.dart after $taskTimeout.');
      print(err);
      print(stackTrace);
      return TaskResult.failure('Task timed out after $taskTimeout');
    } finally {
      print('Cleaning up after task...');
      await forceQuitRunningProcesses();
      _closeKeepAlivePort();
    }
  }

  /// Causes the Dart VM to stay alive until a request to run the task is
  /// received via the VM service protocol.
  void keepVmAliveUntilTaskRunRequested() {
    if (_taskStarted)
      throw StateError('Task already started.');

    // Merely creating this port object will cause the VM to stay alive and keep
    // the VM service server running until the port is disposed of.
    _keepAlivePort = RawReceivePort();

    // Timeout if nothing bothers to connect and ask us to run the task.
    const Duration taskStartTimeout = Duration(seconds: 60);
    _startTaskTimeout = Timer(taskStartTimeout, () {
      if (!_taskStarted) {
        logger.severe('Task did not start in $taskStartTimeout.');
        _closeKeepAlivePort();
        exitCode = 1;
      }
    });
  }

  /// Disables the keepalive port, allowing the VM to exit.
  void _closeKeepAlivePort() {
    _startTaskTimeout?.cancel();
    _keepAlivePort?.close();
  }

  Future<TaskResult> _performTask() {
    final Completer<TaskResult> completer = Completer<TaskResult>();
    Chain.capture(() async {
      completer.complete(await task());
    }, onError: (dynamic taskError, Chain taskErrorStack) {
      final String message = 'Task failed: $taskError';
      stderr
        ..writeln(message)
        ..writeln('\nStack trace:')
        ..writeln(taskErrorStack.terse);
      // IMPORTANT: We're completing the future _successfully_ but with a value
      // that indicates a task failure. This is intentional. At this point we
      // are catching errors coming from arbitrary (and untrustworthy) task
      // code. Our goal is to convert the failure into a readable message.
      // Propagating it further is not useful.
      if (!completer.isCompleted)
        completer.complete(TaskResult.failure(message));
    });
    return completer.future;
  }
}

/// A result of running a single task.
class TaskResult {
  /// Constructs a successful result.
  TaskResult.success(this.data, {
    this.benchmarkScoreKeys = const <String>[],
    this.detailFiles,
  })
      : succeeded = true,
        message = 'success' {
    const JsonEncoder prettyJson = JsonEncoder.withIndent('  ');
    if (benchmarkScoreKeys != null) {
      for (final String key in benchmarkScoreKeys) {
        if (!data.containsKey(key)) {
          throw 'Invalid benchmark score key "$key". It does not exist in task '
              'result data ${prettyJson.convert(data)}';
        } else if (data[key] is! num) {
          throw 'Invalid benchmark score for key "$key". It is expected to be a num '
              'but was ${data[key].runtimeType}: ${prettyJson.convert(data[key])}';
        }
      }
    }
  }

  /// Constructs a successful result using JSON data stored in a file.
  factory TaskResult.successFromFile(File file,
      {List<String> benchmarkScoreKeys}) {
    return TaskResult.success(
      json.decode(file.readAsStringSync()) as Map<String, dynamic>,
      benchmarkScoreKeys: benchmarkScoreKeys,
    );
  }

  /// Constructs an unsuccessful result.
  TaskResult.failure(this.message)
      : succeeded = false,
        data = null,
        detailFiles = null,
        benchmarkScoreKeys = const <String>[];

  /// Whether the task succeeded.
  final bool succeeded;

  /// Task-specific JSON data
  final Map<String, dynamic> data;

  /// Files containing detail on the run (e.g. timeline trace files)
  final List<String> detailFiles;

  /// Keys in [data] that store scores that will be submitted to Cocoon.
  ///
  /// Each key is also part of a benchmark's name tracked by Cocoon.
  final List<String> benchmarkScoreKeys;

  /// Whether the task failed.
  bool get failed => !succeeded;

  /// Explains the result in a human-readable format.
  final String message;

  /// Serializes this task result to JSON format.
  ///
  /// The JSON format is as follows:
  ///
  ///     {
  ///       "success": true|false,
  ///       "data": arbitrary JSON data valid only for successful results,
  ///       "detailFiles": list of filenames containing detail on the run
  ///       "benchmarkScoreKeys": [
  ///         contains keys into "data" that represent benchmarks scores, which
  ///         can be uploaded, for example. to golem, valid only for successful
  ///         results
  ///       ],
  ///       "reason": failure reason string valid only for unsuccessful results
  ///     }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'success': succeeded,
    };

    if (succeeded) {
      json['data'] = data;
      if (detailFiles != null)
        json['detailFiles'] = detailFiles;
      json['benchmarkScoreKeys'] = benchmarkScoreKeys;
    } else {
      json['reason'] = message;
    }

    return json;
  }

  @override
  String toString() => message;
}

class TaskResultCheckProcesses extends TaskResult {
  TaskResultCheckProcesses() : super.success(null);
}
