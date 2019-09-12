// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../convert.dart';
import '../globals.dart';
import 'context.dart';
import 'file_system.dart';
import 'io.dart';
import 'process_manager.dart';
import 'utils.dart';

typedef StringConverter = String Function(String string);

/// A function that will be run before the VM exits.
typedef ShutdownHook = FutureOr<dynamic> Function();

// TODO(ianh): We have way too many ways to run subprocesses in this project.
// Convert most of these into one or more lightweight wrappers around the
// [ProcessManager] API using named parameters for the various options.
// See [here](https://github.com/flutter/flutter/pull/14535#discussion_r167041161)
// for more details.

/// The stage in which a [ShutdownHook] will be run. All shutdown hooks within
/// a given stage will be started in parallel and will be guaranteed to run to
/// completion before shutdown hooks in the next stage are started.
class ShutdownStage implements Comparable<ShutdownStage> {
  const ShutdownStage._(this.priority);

  /// The stage priority. Smaller values will be run before larger values.
  final int priority;

  /// The stage before the invocation recording (if one exists) is serialized
  /// to disk. Tasks performed during this stage *will* be recorded.
  static const ShutdownStage STILL_RECORDING = ShutdownStage._(1);

  /// The stage during which the invocation recording (if one exists) will be
  /// serialized to disk. Invocations performed after this stage will not be
  /// recorded.
  static const ShutdownStage SERIALIZE_RECORDING = ShutdownStage._(2);

  /// The stage during which a serialized recording will be refined (e.g.
  /// cleansed for tests, zipped up for bug reporting purposes, etc.).
  static const ShutdownStage POST_PROCESS_RECORDING = ShutdownStage._(3);

  /// The stage during which temporary files and directories will be deleted.
  static const ShutdownStage CLEANUP = ShutdownStage._(4);

  @override
  int compareTo(ShutdownStage other) => priority.compareTo(other.priority);
}

Map<ShutdownStage, List<ShutdownHook>> _shutdownHooks = <ShutdownStage, List<ShutdownHook>>{};
bool _shutdownHooksRunning = false;

/// Registers a [ShutdownHook] to be executed before the VM exits.
///
/// If [stage] is specified, the shutdown hook will be run during the specified
/// stage. By default, the shutdown hook will be run during the
/// [ShutdownStage.CLEANUP] stage.
void addShutdownHook(
  ShutdownHook shutdownHook, [
  ShutdownStage stage = ShutdownStage.CLEANUP,
]) {
  assert(!_shutdownHooksRunning);
  _shutdownHooks.putIfAbsent(stage, () => <ShutdownHook>[]).add(shutdownHook);
}

/// Runs all registered shutdown hooks and returns a future that completes when
/// all such hooks have finished.
///
/// Shutdown hooks will be run in groups by their [ShutdownStage]. All shutdown
/// hooks within a given stage will be started in parallel and will be
/// guaranteed to run to completion before shutdown hooks in the next stage are
/// started.
Future<void> runShutdownHooks() async {
  printTrace('Running shutdown hooks');
  _shutdownHooksRunning = true;
  try {
    for (ShutdownStage stage in _shutdownHooks.keys.toList()..sort()) {
      printTrace('Shutdown hook priority ${stage.priority}');
      final List<ShutdownHook> hooks = _shutdownHooks.remove(stage);
      final List<Future<dynamic>> futures = <Future<dynamic>>[];
      for (ShutdownHook shutdownHook in hooks) {
        final FutureOr<dynamic> result = shutdownHook();
        if (result is Future<dynamic>) {
          futures.add(result);
        }
      }
      await Future.wait<dynamic>(futures);
    }
  } finally {
    _shutdownHooksRunning = false;
  }
  assert(_shutdownHooks.isEmpty);
  printTrace('Shutdown hooks complete');
}

class ProcessExit implements Exception {
  ProcessExit(this.exitCode, {this.immediate = false});

  final bool immediate;
  final int exitCode;

  String get message => 'ProcessExit: $exitCode';

  @override
  String toString() => message;
}

class RunResult {
  RunResult(this.processResult, this._command)
    : assert(_command != null),
      assert(_command.isNotEmpty);

  final ProcessResult processResult;

  final List<String> _command;

  int get exitCode => processResult.exitCode;
  String get stdout => processResult.stdout;
  String get stderr => processResult.stderr;

  @override
  String toString() {
    final StringBuffer out = StringBuffer();
    if (processResult.stdout.isNotEmpty)
      out.writeln(processResult.stdout);
    if (processResult.stderr.isNotEmpty)
      out.writeln(processResult.stderr);
    return out.toString().trimRight();
  }

  /// Throws a [ProcessException] with the given `message`.
  void throwException(String message) {
    throw ProcessException(
      _command.first,
      _command.skip(1).toList(),
      message,
      exitCode,
    );
  }
}

typedef RunResultChecker = bool Function(int);

ProcessUtils get processUtils => ProcessUtils.instance;

abstract class ProcessUtils {
  factory ProcessUtils() => _DefaultProcessUtils();

  static ProcessUtils get instance => context.get<ProcessUtils>();

  /// Spawns a child process to run the command [cmd].
  ///
  /// When [throwOnError] is `true`, if the child process finishes with a non-zero
  /// exit code, a [ProcessException] is thrown.
  ///
  /// If [throwOnError] is `true`, and [whiteListFailures] is supplied,
  /// a [ProcessException] is only thrown on a non-zero exit code if
  /// [whiteListFailures] returns false when passed the exit code.
  ///
  /// When [workingDirectory] is set, it is the working directory of the child
  /// process.
  ///
  /// When [allowReentrantFlutter] is set to `true`, the child process is
  /// permitted to call the Flutter tool. By default it is not.
  ///
  /// When [environment] is supplied, it is used as the environment for the child
  /// process.
  ///
  /// When [timeout] is supplied, [runAsync] will kill the child process and
  /// throw a [ProcessException] when it doesn't finish in time.
  ///
  /// If [timeout] is supplied, the command will be retried [timeoutRetries] times
  /// if it times out.
  Future<RunResult> run(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker whiteListFailures,
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
    Duration timeout,
    int timeoutRetries = 0,
  });

  /// Run the command and block waiting for its result.
  RunResult runSync(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker whiteListFailures,
    bool hideStdout = false,
    String workingDirectory,
    Map<String, String> environment,
    bool allowReentrantFlutter = false,
  });

  /// This runs the command in the background from the specified working
  /// directory. Completes when the process has been started.
  Future<Process> start(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
  });

  /// This runs the command and streams stdout/stderr from the child process to
  /// this process' stdout/stderr. Completes with the process's exit code.
  ///
  /// If [filter] is null, no lines are removed.
  ///
  /// If [filter] is non-null, all lines that do not match it are removed. If
  /// [mapFunction] is present, all lines that match [filter] are also forwarded
  /// to [mapFunction] for further processing.
  Future<int> stream(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp filter,
    StringConverter mapFunction,
    Map<String, String> environment,
  });

  bool exitsHappySync(
    List<String> cli, {
    Map<String, String> environment,
  });

  Future<bool> exitsHappy(
    List<String> cli, {
    Map<String, String> environment,
  });
}

class _DefaultProcessUtils implements ProcessUtils {
  @override
  Future<RunResult> run(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker whiteListFailures,
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
    Duration timeout,
    int timeoutRetries = 0,
  }) async {
    if (cmd == null || cmd.isEmpty) {
      throw ArgumentError('cmd must be a non-empty list');
    }
    if (timeoutRetries < 0) {
      throw ArgumentError('timeoutRetries must be non-negative');
    }
    _traceCommand(cmd, workingDirectory: workingDirectory);

    // When there is no timeout, there's no need to kill a running process, so
    // we can just use processManager.run().
    if (timeout == null) {
      final ProcessResult results = await processManager.run(
        cmd,
        workingDirectory: workingDirectory,
        environment: _environment(allowReentrantFlutter, environment),
      );
      final RunResult runResult = RunResult(results, cmd);
      printTrace(runResult.toString());
      if (throwOnError && runResult.exitCode != 0 &&
          (whiteListFailures == null || !whiteListFailures(runResult.exitCode))) {
        runResult.throwException('Process exited abnormally:\n$runResult');
      }
      return runResult;
    }

    // When there is a timeout, we have to kill the running process, so we have
    // to use processManager.start() through _runCommand() above.
    while (true) {
      assert(timeoutRetries >= 0);
      timeoutRetries = timeoutRetries - 1;

      final Process process = await start(
          cmd,
          workingDirectory: workingDirectory,
          allowReentrantFlutter: allowReentrantFlutter,
          environment: environment,
      );

      final StringBuffer stdoutBuffer = StringBuffer();
      final StringBuffer stderrBuffer = StringBuffer();
      final Future<void> stdoutFuture = process.stdout
          .transform<String>(const Utf8Decoder(reportErrors: false))
          .listen(stdoutBuffer.write)
          .asFuture<void>(null);
      final Future<void> stderrFuture = process.stderr
          .transform<String>(const Utf8Decoder(reportErrors: false))
          .listen(stderrBuffer.write)
          .asFuture<void>(null);

      int exitCode;
      exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        // The process timed out. Kill it.
        processManager.killPid(process.pid);
        return null;
      });

      String stdoutString;
      String stderrString;
      try {
        Future<void> stdioFuture =
            Future.wait<void>(<Future<void>>[stdoutFuture, stderrFuture]);
        if (exitCode == null) {
          // If we had to kill the process for a timeout, only wait a short time
          // for the stdio streams to drain in case killing the process didn't
          // work.
          stdioFuture = stdioFuture.timeout(const Duration(seconds: 1));
        }
        await stdioFuture;
      } catch (_) {
        // Ignore errors on the process' stdout and stderr streams. Just capture
        // whatever we got, and use the exit code
      }
      stdoutString = stdoutBuffer.toString();
      stderrString = stderrBuffer.toString();

      final ProcessResult result = ProcessResult(
          process.pid, exitCode ?? -1, stdoutString, stderrString);
      final RunResult runResult = RunResult(result, cmd);

      // If the process did not timeout. We are done.
      if (exitCode != null) {
        printTrace(runResult.toString());
        if (throwOnError && runResult.exitCode != 0 &&
            (whiteListFailures == null || !whiteListFailures(exitCode))) {
          runResult.throwException('Process exited abnormally:\n$runResult');
        }
        return runResult;
      }

      // If we are out of timeoutRetries, throw a ProcessException.
      if (timeoutRetries < 0) {
        runResult.throwException('Process timed out:\n$runResult');
      }

      // Log the timeout with a trace message in verbose mode.
      printTrace('Process "${cmd[0]}" timed out. $timeoutRetries attempts left:\n'
                 '$runResult');
    }

    // Unreachable.
  }

  @override
  RunResult runSync(
    List<String> cmd, {
    bool throwOnError = false,
    RunResultChecker whiteListFailures,
    bool hideStdout = false,
    String workingDirectory,
    Map<String, String> environment,
    bool allowReentrantFlutter = false,
  }) {
    _traceCommand(cmd, workingDirectory: workingDirectory);
    final ProcessResult results = processManager.runSync(
      cmd,
      workingDirectory: workingDirectory,
      environment: _environment(allowReentrantFlutter, environment),
    );
    final RunResult runResult = RunResult(results, cmd);

    printTrace('Exit code ${runResult.exitCode} from: ${cmd.join(' ')}');

    bool failedExitCode = runResult.exitCode != 0;
    if (whiteListFailures != null && failedExitCode) {
      failedExitCode = !whiteListFailures(runResult.exitCode);
    }

    if (runResult.stdout.isNotEmpty && !hideStdout) {
      if (failedExitCode && throwOnError) {
        printStatus(runResult.stdout.trim());
      } else {
        printTrace(runResult.stdout.trim());
      }
    }

    if (runResult.stderr.isNotEmpty) {
      if (failedExitCode && throwOnError) {
        printError(runResult.stderr.trim());
      } else {
        printTrace(runResult.stderr.trim());
      }
    }

    if (failedExitCode && throwOnError) {
      runResult.throwException('The command failed');
    }

    return runResult;
  }

  @override
  Future<Process> start(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    Map<String, String> environment,
  }) {
    _traceCommand(cmd, workingDirectory: workingDirectory);
    return processManager.start(
      cmd,
      workingDirectory: workingDirectory,
      environment: _environment(allowReentrantFlutter, environment),
    );
  }

  @override
  Future<int> stream(
    List<String> cmd, {
    String workingDirectory,
    bool allowReentrantFlutter = false,
    String prefix = '',
    bool trace = false,
    RegExp filter,
    StringConverter mapFunction,
    Map<String, String> environment,
  }) async {
    final Process process = await start(
      cmd,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: environment,
    );
    final StreamSubscription<String> stdoutSubscription = process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .where((String line) => filter == null || filter.hasMatch(line))
      .listen((String line) {
        if (mapFunction != null)
          line = mapFunction(line);
        if (line != null) {
          final String message = '$prefix$line';
          if (trace)
            printTrace(message);
          else
            printStatus(message, wrap: false);
        }
      });
    final StreamSubscription<String> stderrSubscription = process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .where((String line) => filter == null || filter.hasMatch(line))
      .listen((String line) {
        if (mapFunction != null)
          line = mapFunction(line);
        if (line != null)
          printError('$prefix$line', wrap: false);
      });

    // Wait for stdout to be fully processed
    // because process.exitCode may complete first causing flaky tests.
    await waitGroup<void>(<Future<void>>[
      stdoutSubscription.asFuture<void>(),
      stderrSubscription.asFuture<void>(),
    ]);

    await waitGroup<void>(<Future<void>>[
      stdoutSubscription.cancel(),
      stderrSubscription.cancel(),
    ]);

    return await process.exitCode;
  }

  @override
  bool exitsHappySync(
    List<String> cli, {
    Map<String, String> environment,
  }) {
    _traceCommand(cli);
    try {
      return processManager.runSync(cli, environment: environment).exitCode == 0;
    } catch (error) {
      printTrace('$cli failed with $error');
      return false;
    }
  }

  @override
  Future<bool> exitsHappy(
    List<String> cli, {
    Map<String, String> environment,
  }) async {
    _traceCommand(cli);
    try {
      return (await processManager.run(cli, environment: environment)).exitCode == 0;
    } catch (error) {
      printTrace('$cli failed with $error');
      return false;
    }
  }

  Map<String, String> _environment(bool allowReentrantFlutter, [
    Map<String, String> environment,
  ]) {
    if (allowReentrantFlutter) {
      if (environment == null)
        environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'};
      else
        environment['FLUTTER_ALREADY_LOCKED'] = 'true';
    }

    return environment;
  }

  void _traceCommand(List<String> args, { String workingDirectory }) {
    final String argsText = args.join(' ');
    if (workingDirectory == null) {
      printTrace('executing: $argsText');
    } else {
      printTrace('executing: [$workingDirectory${fs.path.separator}] $argsText');
    }
  }
}
