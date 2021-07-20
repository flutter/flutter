// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

import 'devices.dart';
import 'host_agent.dart';
import 'running_processes.dart';
import 'task_result.dart';
import 'utils.dart';

/// Identifiers for devices that should never be rebooted.
final Set<String> noRebootForbidList = <String>{
  '822ef7958bba573829d85eef4df6cbdd86593730', // 32bit iPhone requires manual intervention on reboot.
};

/// The maximum number of test runs before a device must be rebooted.
///
/// This number was chosen arbitrarily.
const int maximumRuns = 30;

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
Future<TaskResult> task(TaskFunction task) async {
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
      final Duration? taskTimeout = parameters.containsKey('timeoutInMinutes')
        ? Duration(minutes: int.parse(parameters['timeoutInMinutes']!))
        : null;
      // This is only expected to be passed in unit test runs so they do not
      // kill the Dart process that is running them and waste time running config.
      final bool runFlutterConfig = parameters['runFlutterConfig'] != 'false';
      final bool runProcessCleanup = parameters['runProcessCleanup'] != 'false';
      final TaskResult result = await run(taskTimeout, runProcessCleanup: runProcessCleanup, runFlutterConfig: runFlutterConfig);
      return ServiceExtensionResponse.result(json.encode(result.toJson()));
    });
    registerExtension('ext.cocoonRunnerReady',
        (String method, Map<String, String> parameters) async {
      return ServiceExtensionResponse.result('"ready"');
    });
  }

  final TaskFunction task;

  Future<Device?> _getWorkingDeviceIfAvailable() async {
    try {
      return await devices.workingDevice;
    } on DeviceException {
      return null;
    }
  }

  // TODO(ianh): workaround for https://github.com/dart-lang/sdk/issues/23797
  RawReceivePort? _keepAlivePort;
  Timer? _startTaskTimeout;
  bool _taskStarted = false;

  final Completer<TaskResult> _completer = Completer<TaskResult>();

  static final Logger logger = Logger('TaskRunner');

  /// Signals that this task runner finished running the task.
  Future<TaskResult> get whenDone => _completer.future;

  Future<TaskResult> run(Duration? taskTimeout, {
    bool runFlutterConfig = true,
    bool runProcessCleanup = true,
  }) async {
    try {
      _taskStarted = true;
      print('Running task with a timeout of $taskTimeout.');
      final String exe = Platform.isWindows ? '.exe' : '';
      late Set<RunningProcessInfo> beforeRunningDartInstances;
      if (runProcessCleanup) {
        section('Checking running Dart$exe processes');
        beforeRunningDartInstances = await getRunningProcesses(
          processName: 'dart$exe',
        ).toSet();
        final Set<RunningProcessInfo> allProcesses = await getRunningProcesses().toSet();
        beforeRunningDartInstances.forEach(print);
        for (final RunningProcessInfo info in allProcesses) {
          if (info.commandLine.contains('iproxy')) {
            print('[LEAK]: ${info.commandLine} ${info.creationDate} ${info.pid} ');
          }
        }
      } else {
        section('Skipping check running Dart$exe processes');
      }

      if (runFlutterConfig) {
        print('enabling configs for macOS, Linux, Windows, and Web...');
        final int configResult = await exec(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
          'config',
          '-v',
          '--enable-macos-desktop',
          '--enable-windows-desktop',
          '--enable-linux-desktop',
          '--enable-web',
          if (localEngine != null) ...<String>['--local-engine', localEngine!],
        ], canFail: true);
        if (configResult != 0) {
          print('Failed to enable configuration, tasks may not run.');
        }
      } else {
        print('Skipping enabling configs for macOS, Linux, Windows, and Web');
      }

      final Device? device = await _getWorkingDeviceIfAvailable();
      late TaskResult result;
      IOSink? sink;
      try {
        if (device != null && device.canStreamLogs && hostAgent.dumpDirectory != null) {
          sink = File(path.join(hostAgent.dumpDirectory!.path, '${device.deviceId}.log')).openWrite();
          await device.startLoggingToSink(sink);
        }

        Future<TaskResult> futureResult = _performTask();
        if (taskTimeout != null)
          futureResult = futureResult.timeout(taskTimeout);

        result = await futureResult;
      } finally {
        if (device != null && device.canStreamLogs) {
          await device.stopLoggingToSink();
          await sink?.close();
        }
      }

      if (runProcessCleanup) {
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
      } else {
        print('Skipping check running Dart$exe processes after task');
      }
      _completer.complete(result);
      return result;
    } on TimeoutException catch (err, stackTrace) {
      print('Task timed out in framework.dart after $taskTimeout.');
      print(err);
      print(stackTrace);
      return TaskResult.failure('Task timed out after $taskTimeout');
    } finally {
      await checkForRebootRequired();
      await forceQuitRunningProcesses();
      _closeKeepAlivePort();
    }
  }

  Future<void> checkForRebootRequired() async {
    print('Checking for reboot');
    try {
      final Device device = await devices.workingDevice;
      if (noRebootForbidList.contains(device.deviceId)) {
        return;
      }
      final File rebootFile = _rebootFile();
      int runCount;
      if (rebootFile.existsSync()) {
        runCount = int.tryParse(rebootFile.readAsStringSync().trim()) ?? 0;
      } else {
        runCount = 0;
      }
      if (runCount < maximumRuns) {
        rebootFile
          ..createSync()
          ..writeAsStringSync((runCount + 1).toString());
        return;
      }
      rebootFile.deleteSync();
      print('rebooting');
      await device.reboot();
    } on TimeoutException {
      // Could not find device in order to reboot.
    } on DeviceException {
      // No attached device needed to reboot.
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

File _rebootFile() {
  if (Platform.isLinux || Platform.isMacOS) {
    return File(path.join(Platform.environment['HOME']!, '.reboot-count'));
  }
  if (!Platform.isWindows) {
    throw StateError('Unexpected platform ${Platform.operatingSystem}');
  }
  return File(path.join(Platform.environment['USERPROFILE']!, '.reboot-count'));
}
