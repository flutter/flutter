// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

/// The local engine to use for [flutter] and [evalFlutter], if any.
String get localEngine {
  // Use two distinct `defaultValue`s to determine whether a 'localEngine'
  // declaration exists in the environment.
  const bool isDefined =
      String.fromEnvironment('localEngine', defaultValue: 'a') ==
          String.fromEnvironment('localEngine', defaultValue: 'b');
  return isDefined ? const String.fromEnvironment('localEngine') : null;
}

/// The local engine source path to use if a local engine is used for [flutter]
/// and [evalFlutter].
String get localEngineSrcPath {
  // Use two distinct `defaultValue`s to determine whether a
  // 'localEngineSrcPath' declaration exists in the environment.
  const bool isDefined =
      String.fromEnvironment('localEngineSrcPath', defaultValue: 'a') ==
          String.fromEnvironment('localEngineSrcPath', defaultValue: 'b');
  return isDefined ? const String.fromEnvironment('localEngineSrcPath') : null;
}

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];
ProcessManager _processManager = const LocalProcessManager();

class ProcessInfo {
  ProcessInfo(this.command, this.process);

  final DateTime startTime = DateTime.now();
  final String command;
  final Process process;

  @override
  String toString() {
    return '''
  command : $command
  started : $startTime
  pid     : ${process.pid}
'''
        .trim();
  }
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

void fail(String message) {
  throw BuildFailedError(message);
}

Directory dir(String path) => Directory(path);

/// Starts a subprocess.
///
/// The first argument is the full path to the executable to run.
///
/// The second argument is the list of arguments to provide on the command line.
/// This argument can be null, indicating no arguments (same as the empty list).
///
/// The `environment` argument can be provided to configure environment variables
/// that will be made available to the subprocess. The `BOT` environment variable
/// is always set and overrides any value provided in the `environment` argument.
/// The `isBot` argument controls the value of the `BOT` variable. It will either
/// be "true", if `isBot` is true (the default), or "false" if it is false.
///
/// The `BOT` variable is in particular used by the `flutter` tool to determine
/// how verbose to be and whether to enable analytics by default.
///
/// The working directory can be provided using the `workingDirectory` argument.
/// By default it will default to the current working directory (see [cwd]).
///
/// Information regarding the execution of the subprocess is printed to the
/// console.
///
/// The actual process executes asynchronously. A handle to the subprocess is
/// returned in the form of a [Future] that completes to a [Process] object.
Future<Process> startProcess(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool isBot = true, // set to false to pretend not to be on a bot (e.g. to test user-facing outputs)
  String workingDirectory,
}) async {
  assert(isBot != null);
  final String command = '$executable ${arguments?.join(" ") ?? ""}';
  final String finalWorkingDirectory = workingDirectory ?? cwd;
  print('\nExecuting: $command in $finalWorkingDirectory'
      + (environment != null ? ' with environment $environment' : ''));
  environment ??= <String, String>{};
  environment['BOT'] = isBot ? 'true' : 'false';
  final Process process = await _processManager.start(
    <String>[executable, ...arguments],
    environment: environment,
    workingDirectory: finalWorkingDirectory,
  );
  final ProcessInfo processInfo = ProcessInfo(command, process);
  _runningProcesses.add(processInfo);

  process.exitCode.then<void>((int exitCode) {
    print('"$executable" exit code: $exitCode');
    _runningProcesses.remove(processInfo);
  });

  return process;
}

Future<int> _execute(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  String workingDirectory,
  StringBuffer output, // if not null, the stdout will be written here
  StringBuffer stderr, // if not null, the stderr will be written here
  bool printStdout = true,
  bool printStderr = true,
}) async {
  final Process process = await startProcess(
    executable,
    arguments,
    environment: environment,
    workingDirectory: workingDirectory,
  );
  await forwardStandardStreams(
    process,
    output: output,
    stderr: stderr,
    printStdout: printStdout,
    printStderr: printStderr,
  );
  final int exitCode = await process.exitCode;

  if (exitCode != 0 && !canFail) {
    fail('Executable "$executable" failed with exit code $exitCode.');
  }

  return exitCode;
}

/// Forwards standard out and standard error from [process] to this process'
/// respective outputs. Also writes stdout to [output] and stderr to [stderr]
/// if they are not null.
///
/// Returns a future that completes when both out and error streams a closed.
Future<void> forwardStandardStreams(
  Process process, {
  StringBuffer output,
  StringBuffer stderr,
  bool printStdout = true,
  bool printStderr = true,
  }) {
  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();
  process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        if (printStdout) {
          print('stdout: $line');
        }
        output?.writeln(line);
      }, onDone: () { stdoutDone.complete(); });
  process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        if (printStderr) {
          print('stderr: $line');
        }
        stderr?.writeln(line);
      }, onDone: () { stderrDone.complete(); });

  return Future.wait<void>(<Future<void>>[
    stdoutDone.future,
    stderrDone.future,
  ]);
}

/// Executes a command and returns its standard output as a String.
///
/// For logging purposes, the command's output is also printed out by default.
Future<String> eval(
  String executable,
  List<String> arguments, {
  Map<String, String> environment,
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  String workingDirectory,
  StringBuffer stderr, // if not null, the stderr will be written here
  bool printStdout = true,
  bool printStderr = true,
}) async {
  final StringBuffer output = StringBuffer();
  await _execute(
    executable,
    arguments,
    environment: environment,
    canFail: canFail,
    workingDirectory: workingDirectory,
    output: output,
    stderr: stderr,
    printStdout: printStdout,
    printStderr: printStderr,
  );
  return output.toString().trimRight();
}

List<String> flutterCommandArgs(String command, List<String> options) {
  return <String>[
    command,
    if (localEngine != null) ...<String>['--local-engine', localEngine],
    if (localEngineSrcPath != null) ...<String>['--local-engine-src-path', localEngineSrcPath],
    ...options,
  ];
}

const String flutterCommand = 'flutter';

/// Runs a `flutter` command and returns the standard output as a string.
Future<String> evalFlutter(String command, {
  List<String> options = const <String>[],
  bool canFail = false, // as in, whether failures are ok. False means that they are fatal.
  Map<String, String> environment,
  StringBuffer stderr, // if not null, the stderr will be written here.
}) {
  final List<String> args = flutterCommandArgs(command, options);
  return eval(flutterCommand, args,
      canFail: canFail, environment: environment, stderr: stderr);
}

Future<T> inDirectory<T>(dynamic directory, Future<T> action()) async {
  final String previousCwd = cwd;
  try {
    cd(directory);
    return await action();
  } finally {
    cd(previousCwd);
  }
}

void cd(dynamic directory) {
  Directory d;
  if (directory is String) {
    cwd = directory;
    d = dir(directory);
  } else if (directory is Directory) {
    cwd = directory.path;
    d = directory;
  } else {
    throw FileSystemException('Unsupported directory type ${directory.runtimeType}', directory.toString());
  }

  if (!d.existsSync())
    throw FileSystemException('Cannot cd into directory that does not exist', d.toString());
}
