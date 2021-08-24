// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core' hide print;
import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'utils.dart';

/// Runs the `executable` and returns standard output as a stream of lines.
///
/// The returned stream reaches its end immediately after the command exits.
///
/// If `expectNonZeroExit` is false and the process exits with a non-zero exit
/// code fails the test immediately by exiting the test process with exit code
/// 1.
Stream<String> runAndGetStdout(String executable, List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool expectNonZeroExit = false,
}) async* {
  final StreamController<String> output = StreamController<String>();
  final Future<CommandResult?> command = runCommand(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    expectNonZeroExit: expectNonZeroExit,
    // Capture the output so it's not printed to the console by default.
    outputMode: OutputMode.capture,
    outputListener: (String line, io.Process process) {
      output.add(line);
    },
  );

  // Close the stream controller after the command is complete. Otherwise,
  // the yield* will never finish.
  command.whenComplete(output.close);

  yield* output.stream;
}

/// Represents a running process launched using [startCommand].
class Command {
  Command._(this.process, this._time, this._savedStdout, this._savedStderr);

  /// The raw process that was launched for this command.
  final io.Process process;

  final Stopwatch _time;
  final Future<List<List<int>>>? _savedStdout;
  final Future<List<List<int>>>? _savedStderr;

  /// Evaluates when the [process] exits.
  ///
  /// Returns the result of running the command.
  Future<CommandResult> get onExit async {
    final int exitCode = await process.exitCode;
    _time.stop();

    // Saved output is null when OutputMode.print is used.
    final String? flattenedStdout = _savedStdout != null ? _flattenToString((await _savedStdout)!) : null;
    final String? flattenedStderr = _savedStderr != null ? _flattenToString((await _savedStderr)!) : null;
    return CommandResult._(exitCode, _time.elapsed, flattenedStdout, flattenedStderr);
  }
}

/// The result of running a command using [startCommand] and [runCommand];
class CommandResult {
  CommandResult._(this.exitCode, this.elapsedTime, this.flattenedStdout, this.flattenedStderr);

  /// The exit code of the process.
  final int exitCode;

  /// The amount of time it took the process to complete.
  final Duration elapsedTime;

  /// Standard output decoded as a string using UTF8 decoder.
  final String? flattenedStdout;

  /// Standard error output decoded as a string using UTF8 decoder.
  final String? flattenedStderr;
}

/// Starts the `executable` and returns a command object representing the
/// running process.
///
/// `outputListener` is called for every line of standard output from the
/// process, and is given the [Process] object. This can be used to interrupt
/// an indefinitely running process, for example, by waiting until the process
/// emits certain output.
///
/// `outputMode` controls where the standard output from the command process
/// goes. See [OutputMode].
Future<Command> startCommand(String executable, List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  OutputMode outputMode = OutputMode.print,
  bool Function(String)? removeLine,
  void Function(String, io.Process)? outputListener,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory ?? io.Directory.current.path);
  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Stopwatch time = Stopwatch()..start();
  final io.Process process = await io.Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  Future<List<List<int>>> savedStdout = Future<List<List<int>>>.value(<List<int>>[]);
  Future<List<List<int>>> savedStderr = Future<List<List<int>>>.value(<List<int>>[]);
  final Stream<List<int>> stdoutSource = process.stdout
    .transform<String>(const Utf8Decoder())
    .transform(const LineSplitter())
    .where((String line) => removeLine == null || !removeLine(line))
    .map((String line) {
      final String formattedLine = '$line\n';
      if (outputListener != null) {
        outputListener(formattedLine, process);
      }
      return formattedLine;
    })
    .transform(const Utf8Encoder());
  switch (outputMode) {
    case OutputMode.print:
      stdoutSource.listen((List<int> output) {
        io.stdout.add(output);
        savedStdout.then((List<List<int>> list) => list.add(output));
      });
      process.stderr.listen((List<int> output) {
        io.stdout.add(output);
        savedStdout.then((List<List<int>> list) => list.add(output));
      });
      break;
    case OutputMode.capture:
      savedStdout = stdoutSource.toList();
      savedStderr = process.stderr.toList();
      break;
  }

  return Command._(process, time, savedStdout, savedStderr);
}

/// Runs the `executable` and waits until the process exits.
///
/// If the process exits with a non-zero exit code, exits this process with
/// exit code 1, unless `expectNonZeroExit` is set to true.
///
/// `outputListener` is called for every line of standard output from the
/// process, and is given the [Process] object. This can be used to interrupt
/// an indefinitely running process, for example, by waiting until the process
/// emits certain output.
///
/// Returns the result of the finished process.
///
/// `outputMode` controls where the standard output from the command process
/// goes. See [OutputMode].
Future<CommandResult> runCommand(String executable, List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool expectNonZeroExit = false,
  int? expectedExitCode,
  String? failureMessage,
  OutputMode outputMode = OutputMode.print,
  bool Function(String)? removeLine,
  void Function(String, io.Process)? outputListener,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory ?? io.Directory.current.path);

  final Command command = await startCommand(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    outputMode: outputMode,
    removeLine: removeLine,
    outputListener: outputListener,
  );

  final CommandResult result = await command.onExit;

  if ((result.exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && result.exitCode != expectedExitCode)) {
    // Print the output when we get unexpected results (unless output was
    // printed already).
    switch (outputMode) {
      case OutputMode.print:
        break;
      case OutputMode.capture:
        io.stdout.writeln(result.flattenedStdout);
        io.stdout.writeln(result.flattenedStderr);
        break;
    }
    exitWithError(<String>[
      if (failureMessage != null)
        failureMessage
      else
        '${bold}ERROR: ${red}Last command exited with ${result.exitCode} (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset',
      '${bold}Command: $green$commandDescription$reset',
      '${bold}Relative working directory: $cyan$relativeWorkingDir$reset',
    ]);
  }
  print('$clock ELAPSED TIME: ${prettyPrintDuration(result.elapsedTime)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');
  return result;
}

/// Flattens a nested list of UTF-8 code units into a single string.
String _flattenToString(List<List<int>> chunks) =>
  utf8.decode(chunks.expand<int>((List<int> ints) => ints).toList());

/// Specifies what to do with the command output from [runCommand] and [startCommand].
enum OutputMode {
  /// Forwards standard output and standard error streams to the test process'
  /// standard output stream (i.e. stderr is redirected to stdout).
  ///
  /// Use this mode if all you want is print the output of the command to the
  /// console. The output is no longer available after the process exits.
  print,

  /// Saves standard output and standard error streams in memory.
  ///
  /// Captured output can be retrieved from the [CommandResult] object.
  ///
  /// Use this mode in tests that need to inspect the output of a command, or
  /// when the output should not be printed to console.
  capture,
}
