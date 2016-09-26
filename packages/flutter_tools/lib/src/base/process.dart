// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../globals.dart';

typedef String StringConverter(String string);

// TODO(ianh): We have way too many ways to run subprocesses in this project.

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
}) async {
  _traceCommand(cmd, workingDirectory: workingDirectory);
  String executable = cmd[0];
  List<String> arguments = cmd.length > 1 ? cmd.sublist(1) : <String>[];
  Process process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: _environment(allowReentrantFlutter, environment)
  );
  return process;
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
  Process process = await runCommand(
    cmd,
    workingDirectory: workingDirectory,
    allowReentrantFlutter: allowReentrantFlutter,
    environment: environment
  );
  StreamSubscription<String> subscription = process.stdout
    .transform(UTF8.decoder)
    .transform(const LineSplitter())
    .where((String line) => filter == null ? true : filter.hasMatch(line))
    .listen((String line) {
      if (mapFunction != null)
        line = mapFunction(line);
      if (line != null) {
        String message = '$prefix$line';
        if (trace)
          printTrace(message);
        else
          printStatus(message);
      }
    });
  process.stderr
    .transform(UTF8.decoder)
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
  await subscription.asFuture();
  subscription.cancel();

  return await process.exitCode;
}

Future<Null> runAndKill(List<String> cmd, Duration timeout) {
  Future<Process> proc = runDetached(cmd);
  return new Future<Null>.delayed(timeout, () async {
    printTrace('Intentionally killing ${cmd[0]}');
    Process.killPid((await proc).pid);
  });
}

Future<Process> runDetached(List<String> cmd) {
  _traceCommand(cmd);
  Future<Process> proc = Process.start(
    cmd[0], cmd.getRange(1, cmd.length).toList(),
    mode: ProcessStartMode.DETACHED
  );
  return proc;
}

Future<RunResult> runAsync(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false
}) async {
  _traceCommand(cmd, workingDirectory: workingDirectory);
  ProcessResult results = await Process.run(
    cmd[0],
    cmd.getRange(1, cmd.length).toList(),
    workingDirectory: workingDirectory,
    environment: _environment(allowReentrantFlutter)
  );
  RunResult runResults = new RunResult(results);
  printTrace(runResults.toString());
  return runResults;
}

bool exitsHappy(List<String> cli) {
  _traceCommand(cli);
  try {
    return Process.runSync(cli.first, cli.sublist(1)).exitCode == 0;
  } catch (error) {
    return false;
  }
}

/// Run cmd and return stdout.
///
/// Throws an error if cmd exits with a non-zero value.
String runCheckedSync(List<String> cmd, {
  String workingDirectory,
  bool allowReentrantFlutter: false
}) {
  return _runWithLoggingSync(
    cmd,
    workingDirectory: workingDirectory,
    allowReentrantFlutter: allowReentrantFlutter,
    checked: true,
    noisyErrors: true
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
  String argsText = args.join(' ');
  if (workingDirectory == null)
    printTrace(argsText);
  else
    printTrace("[$workingDirectory${Platform.pathSeparator}] $argsText");
}

String _runWithLoggingSync(List<String> cmd, {
  bool checked: false,
  bool noisyErrors: false,
  String workingDirectory,
  bool allowReentrantFlutter: false
}) {
  _traceCommand(cmd, workingDirectory: workingDirectory);
  ProcessResult results = Process.runSync(
    cmd[0],
    cmd.getRange(1, cmd.length).toList(),
    workingDirectory: workingDirectory,
    environment: _environment(allowReentrantFlutter)
  );

  printTrace('Exit code ${results.exitCode} from: ${cmd.join(' ')}');

  if (results.stdout.isNotEmpty) {
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

    if (checked)
      throw 'Exit code ${results.exitCode} from: ${cmd.join(' ')}';
  }

  return results.stdout.trim();
}

class ProcessExit implements Exception {
  ProcessExit(this.exitCode);

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
    StringBuffer out = new StringBuffer();
    if (processResult.stdout.isNotEmpty)
      out.writeln(processResult.stdout);
    if (processResult.stderr.isNotEmpty)
      out.writeln(processResult.stderr);
    return out.toString().trimRight();
  }
}
