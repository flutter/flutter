// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../globals.dart';
import 'file_system.dart';
import 'io.dart';
import 'process_manager.dart';
import 'utils.dart';

typedef String StringConverter(String string);

/// A function that will be run before the VM exits.
typedef Future<dynamic> ShutdownHook();

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
  static const ShutdownStage STILL_RECORDING = const ShutdownStage._(1);

  /// The stage during which the invocation recording (if one exists) will be
  /// serialized to disk. Invocations performed after this stage will not be
  /// recorded.
  static const ShutdownStage SERIALIZE_RECORDING = const ShutdownStage._(2);

  /// The stage during which a serialized recording will be refined (e.g.
  /// cleansed for tests, zipped up for bug reporting purposes, etc.).
  static const ShutdownStage POST_PROCESS_RECORDING = const ShutdownStage._(3);

  /// The stage during which temporary files and directories will be deleted.
  static const ShutdownStage CLEANUP = const ShutdownStage._(4);

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
Future<Null> runShutdownHooks() async {
  printTrace('Running shutdown hooks');
  _shutdownHooksRunning = true;
  try {
    for (ShutdownStage stage in _shutdownHooks.keys.toList()..sort()) {
      printTrace('Shutdown hook priority ${stage.priority}');
      final List<ShutdownHook> hooks = _shutdownHooks.remove(stage);
      final List<Future<dynamic>> futures = <Future<dynamic>>[];
      for (ShutdownHook shutdownHook in hooks)
        futures.add(shutdownHook());
      await Future.wait<dynamic>(futures);
    }
  } finally {
    _shutdownHooksRunning = false;
  }
  assert(_shutdownHooks.isEmpty);
  printTrace('Shutdown hooks complete');
}

Map<String, String> _environment(bool allowReentrantFlutter, [Map<String, String> environment]) {
  if (allowReentrantFlutter) {
    if (environment == null)
      environment = <String, String>{ 'FLUTTER_ALREADY_LOCKED': 'true' };
    else
      environment['FLUTTER_ALREADY_LOCKED'] = 'true';
  }

  return environment;
}

/// This runs the command in the background from the specified working
/// directory. Completes when the process has been started.
Future<Process> runCommand(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false,
  Map<String, String> environment
}) {
  _traceCommand(cmd, workingDirectory: workingDirectory);
  return processManager.start(
    cmd,
    workingDirectory: workingDirectory,
    environment: _environment(allowReentrantFlutter, environment),
  );
}

/// This runs the command and streams stdout/stderr from the child process to
/// this process' stdout/stderr. Completes with the process's exit code.
Future<int> runCommandAndStreamOutput(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false,
  String prefix: '',
  bool trace: false,
  RegExp filter,
  StringConverter mapFunction,
  Map<String, String> environment
}) async {
  final Process process = await runCommand(
    cmd,
    workingDirectory: workingDirectory,
    allowReentrantFlutter: allowReentrantFlutter,
    environment: environment
  );
  final StreamSubscription<String> stdoutSubscription = process.stdout
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .where((String line) => filter == null ? true : filter.hasMatch(line))
    .listen((String line) {
      if (mapFunction != null)
        line = mapFunction(line);
      if (line != null) {
        final String message = '$prefix$line';
        if (trace)
          printTrace(message);
        else
          printStatus(message);
      }
    });
  final StreamSubscription<String> stderrSubscription = process.stderr
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .where((String line) => filter == null ? true : filter.hasMatch(line))
    .listen((String line) {
      if (mapFunction != null)
        line = mapFunction(line);
      if (line != null)
        printError('$prefix$line');
    });

  // Wait for stdout to be fully processed
  // because process.exitCode may complete first causing flaky tests.
  await waitGroup<Null>(<Future<Null>>[
    stdoutSubscription.asFuture<Null>(),
    stderrSubscription.asFuture<Null>(),
  ]);

  await waitGroup<Null>(<Future<Null>>[
    stdoutSubscription.cancel(),
    stderrSubscription.cancel(),
  ]);

  return await process.exitCode;
}

/// Runs the [command] interactively, connecting the stdin/stdout/stderr
/// streams of this process to those of the child process. Completes with
/// the exit code of the child process.
Future<int> runInteractively(List<String> command, {
  String workingDirectory,
  bool allowReentrantFlutter: false,
  Map<String, String> environment
}) async {
  final Process process = await runCommand(
    command,
    workingDirectory: workingDirectory,
    allowReentrantFlutter: allowReentrantFlutter,
    environment: environment,
  );
  process.stdin.addStream(stdin);
  // Wait for stdout and stderr to be fully processed, because process.exitCode
  // may complete first.
  Future.wait<dynamic>(<Future<dynamic>>[
    stdout.addStream(process.stdout),
    stderr.addStream(process.stderr),
  ]);
  return await process.exitCode;
}

Future<Null> runAndKill(List<String> cmd, Duration timeout) {
  final Future<Process> proc = runDetached(cmd);
  return new Future<Null>.delayed(timeout, () async {
    printTrace('Intentionally killing ${cmd[0]}');
    processManager.killPid((await proc).pid);
  });
}

Future<Process> runDetached(List<String> cmd) {
  _traceCommand(cmd);
  final Future<Process> proc = processManager.start(
    cmd,
    mode: ProcessStartMode.DETACHED,
  );
  return proc;
}

Future<RunResult> runAsync(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false,
  Map<String, String> environment
}) async {
  _traceCommand(cmd, workingDirectory: workingDirectory);
  final ProcessResult results = await processManager.run(
    cmd,
    workingDirectory: workingDirectory,
    environment: _environment(allowReentrantFlutter, environment),
  );
  final RunResult runResults = new RunResult(results);
  printTrace(runResults.toString());
  return runResults;
}

Future<RunResult> runCheckedAsync(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false,
  Map<String, String> environment
}) async {
  final RunResult result = await runAsync(
      cmd,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: environment
  );
  if (result.exitCode != 0)
    throw 'Exit code ${result.exitCode} from: ${cmd.join(' ')}:\n$result';
  return result;
}

bool exitsHappy(List<String> cli) {
  _traceCommand(cli);
  try {
    return processManager.runSync(cli).exitCode == 0;
  } catch (error) {
    return false;
  }
}

Future<bool> exitsHappyAsync(List<String> cli) async {
  _traceCommand(cli);
  try {
    return (await processManager.run(cli)).exitCode == 0;
  } catch (error) {
    return false;
  }
}

/// Run cmd and return stdout.
///
/// Throws an error if cmd exits with a non-zero value.
String runCheckedSync(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false,
  bool hideStdout: false,
  Map<String, String> environment,
}) {
  return _runWithLoggingSync(
    cmd,
    workingDirectory: workingDirectory,
    allowReentrantFlutter: allowReentrantFlutter,
    hideStdout: hideStdout,
    checked: true,
    noisyErrors: true,
    environment: environment,
  );
}

/// Run cmd and return stdout.
String runSync(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false
}) {
  return _runWithLoggingSync(
    cmd,
    workingDirectory: workingDirectory,
    allowReentrantFlutter: allowReentrantFlutter
  );
}

void _traceCommand(List<String> args, { String workingDirectory }) {
  final String argsText = args.join(' ');
  if (workingDirectory == null)
    printTrace(argsText);
  else
    printTrace('[$workingDirectory${fs.path.separator}] $argsText');
}

String _runWithLoggingSync(List<String> cmd, {
  bool checked: false,
  bool noisyErrors: false,
  bool throwStandardErrorOnError: false,
  String workingDirectory,
  bool allowReentrantFlutter: false,
  bool hideStdout: false,
  Map<String, String> environment,
}) {
  _traceCommand(cmd, workingDirectory: workingDirectory);
  final ProcessResult results = processManager.runSync(
    cmd,
    workingDirectory: workingDirectory,
    environment: _environment(allowReentrantFlutter, environment),
  );

  printTrace('Exit code ${results.exitCode} from: ${cmd.join(' ')}');

  if (results.stdout.isNotEmpty && !hideStdout) {
    if (results.exitCode != 0 && noisyErrors)
      printStatus(results.stdout.trim());
    else
      printTrace(results.stdout.trim());
  }

  if (results.exitCode != 0) {
    if (results.stderr.isNotEmpty) {
      if (noisyErrors)
        printError(results.stderr.trim());
      else
        printTrace(results.stderr.trim());
    }

    if (throwStandardErrorOnError)
      throw results.stderr.trim();

    if (checked)
      throw 'Exit code ${results.exitCode} from: ${cmd.join(' ')}';
  }

  return results.stdout.trim();
}

class ProcessExit implements Exception {
  ProcessExit(this.exitCode, {this.immediate: false});

  final bool immediate;
  final int exitCode;

  String get message => 'ProcessExit: $exitCode';

  @override
  String toString() => message;
}

class RunResult {
  RunResult(this.processResult);

  final ProcessResult processResult;

  int get exitCode => processResult.exitCode;
  String get stdout => processResult.stdout;
  String get stderr => processResult.stderr;

  @override
  String toString() {
    final StringBuffer out = new StringBuffer();
    if (processResult.stdout.isNotEmpty)
      out.writeln(processResult.stdout);
    if (processResult.stderr.isNotEmpty)
      out.writeln(processResult.stderr);
    return out.toString().trimRight();
  }
}
