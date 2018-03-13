// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'utils.dart';

/// Maximum amount of time a single task is allowed to take to run.
///
/// If exceeded the task is considered to have failed.
const Duration _kDefaultTaskTimeout = const Duration(minutes: 15);

/// Represents a unit of work performed in the CI environment that can
/// succeed, fail and be retried independently of others.
typedef Future<TaskResult> TaskFunction();

bool _isTaskRegistered = false;

/// Registers a [task] to run, returns the result when it is complete.
///
/// The task does not run immediately but waits for the request via the
/// VM service protocol to run it.
///
/// It is ok for a [task] to perform many things. However, only one task can be
/// registered per Dart VM.
Future<TaskResult> task(TaskFunction task) {
  if (_isTaskRegistered)
    throw new StateError('A task is already registered');

  _isTaskRegistered = true;

  // TODO: allow overriding logging.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  final _TaskRunner runner = new _TaskRunner(task);
  runner.keepVmAliveUntilTaskRunRequested();
  return runner.whenDone;
}

class _TaskRunner {
  static final Logger logger = new Logger('TaskRunner');

  final TaskFunction task;

  // TODO: workaround for https://github.com/dart-lang/sdk/issues/23797
  RawReceivePort _keepAlivePort;
  Timer _startTaskTimeout;
  bool _taskStarted = false;

  final Completer<TaskResult> _completer = new Completer<TaskResult>();

  _TaskRunner(this.task) {
    registerExtension('ext.cocoonRunTask',
        (String method, Map<String, String> parameters) async {
      final Duration taskTimeout = parameters.containsKey('timeoutInMinutes')
        ? new Duration(minutes: int.parse(parameters['timeoutInMinutes']))
        : _kDefaultTaskTimeout;
      final TaskResult result = await run(taskTimeout);
      return new ServiceExtensionResponse.result(json.encode(result.toJson()));
    });
    registerExtension('ext.cocoonRunnerReady',
        (String method, Map<String, String> parameters) async {
      return new ServiceExtensionResponse.result('"ready"');
    });
  }

  /// Signals that this task runner finished running the task.
  Future<TaskResult> get whenDone => _completer.future;

  Future<TaskResult> run(Duration taskTimeout) async {
    try {
      _taskStarted = true;
      final TaskResult result = await _performTask().timeout(taskTimeout);
      _completer.complete(result);
      return result;
    } on TimeoutException catch (_) {
      return new TaskResult.failure('Task timed out after $taskTimeout');
    } finally {
      await forceQuitRunningProcesses();
      _closeKeepAlivePort();
    }
  }

  /// Causes the Dart VM to stay alive until a request to run the task is
  /// received via the VM service protocol.
  void keepVmAliveUntilTaskRunRequested() {
    if (_taskStarted)
      throw new StateError('Task already started.');

    // Merely creating this port object will cause the VM to stay alive and keep
    // the VM service server running until the port is disposed of.
    _keepAlivePort = new RawReceivePort();

    // Timeout if nothing bothers to connect and ask us to run the task.
    const Duration taskStartTimeout = const Duration(seconds: 10);
    _startTaskTimeout = new Timer(taskStartTimeout, () {
      if (!_taskStarted) {
        logger.severe('Task did not start in $taskStartTimeout.');
        _closeKeepAlivePort();
        exitCode = 1;
      }
    });
  }

  /// Disables the keep-alive port, allowing the VM to exit.
  void _closeKeepAlivePort() {
    _startTaskTimeout?.cancel();
    _keepAlivePort?.close();
  }

  Future<TaskResult> _performTask() {
    final Completer<TaskResult> completer = new Completer<TaskResult>();
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
        completer.complete(new TaskResult.failure(message));
    });
    return completer.future;
  }
}

/// A result of running a single task.
class TaskResult {
  /// Constructs a successful result.
  TaskResult.success(this.data, {this.benchmarkScoreKeys: const <String>[]})
      : this.succeeded = true,
        this.message = 'success' {
    const JsonEncoder prettyJson = const JsonEncoder.withIndent('  ');
    if (benchmarkScoreKeys != null) {
      for (String key in benchmarkScoreKeys) {
        if (!data.containsKey(key)) {
          throw 'Invalid Golem score key "$key". It does not exist in task '
              'result data ${prettyJson.convert(data)}';
        } else if (data[key] is! num) {
          throw 'Invalid Golem score for key "$key". It is expected to be a num '
              'but was ${data[key].runtimeType}: ${prettyJson.convert(data[key])}';
        }
      }
    }
  }

  /// Constructs a successful result using JSON data stored in a file.
  factory TaskResult.successFromFile(File file,
      {List<String> benchmarkScoreKeys}) {
    return new TaskResult.success(json.decode(file.readAsStringSync()),
        benchmarkScoreKeys: benchmarkScoreKeys);
  }

  /// Constructs an unsuccessful result.
  TaskResult.failure(this.message)
      : this.succeeded = false,
        this.data = null,
        this.benchmarkScoreKeys = const <String>[];

  /// Whether the task succeeded.
  final bool succeeded;

  /// Task-specific JSON data
  final Map<String, dynamic> data;

  /// Keys in [data] that store scores that will be submitted to Golem.
  ///
  /// Each key is also part of a benchmark's name tracked by Golem.
  /// A benchmark name is computed by combining [Task.name] with a key
  /// separated by a dot. For example, if a task's name is
  /// `"complex_layout__start_up"` and score key is
  /// `"engineEnterTimestampMicros"`, the score will be submitted to Golem under
  /// `"complex_layout__start_up.engineEnterTimestampMicros"`.
  ///
  /// This convention reduces the amount of configuration that needs to be done
  /// to submit benchmark scores to Golem.
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
      json['benchmarkScoreKeys'] = benchmarkScoreKeys;
    } else {
      json['reason'] = message;
    }

    return json;
  }
}
