// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core' hide print;
import 'dart:io' hide exit;

import 'package:path/path.dart' as path;

import 'utils.dart';

// TODO(ianh): These two functions should be refactored into something that avoids all this code duplication.

Stream<String> runAndGetStdout(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectNonZeroExit = false,
  int expectedExitCode,
  String failureMessage,
  bool skip = false,
}) async* {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return;
  }
  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Stopwatch time = Stopwatch()..start();
  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  stderr.addStream(process.stderr);
  final Stream<String> lines = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
  yield* lines;

  final int exitCode = await process.exitCode;
  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    exitWithError(<String>[
      if (failureMessage != null)
        failureMessage
      else
        '${bold}ERROR: ${red}Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset',
      '${bold}Command: $green$commandDescription$reset',
      '${bold}Relative working directory: $cyan$relativeWorkingDir$reset',
    ]);
  }
  print('$clock ELAPSED TIME: ${prettyPrintDuration(time.elapsed)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');
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
Future<void> runCommand(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectNonZeroExit = false,
  int expectedExitCode,
  String failureMessage,
  OutputMode outputMode = OutputMode.print,
  CapturedOutput output,
  bool skip = false,
  bool Function(String) removeLine,
  void Function(String, Process) outputListener,
}) async {
  assert(
    (outputMode == OutputMode.capture) == (output != null),
    'The output parameter must be non-null with and only with OutputMode.capture',
  );

  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory ?? Directory.current.path);
  if (skip) {
    printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return;
  }
  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Stopwatch time = Stopwatch()..start();
  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  Future<List<List<int>>> savedStdout, savedStderr;
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
      await Future.wait<void>(<Future<void>>[
        stdout.addStream(stdoutSource),
        stderr.addStream(process.stderr),
      ]);
      break;
    case OutputMode.capture:
    case OutputMode.discard:
      savedStdout = stdoutSource.toList();
      savedStderr = process.stderr.toList();
      break;
  }

  final int exitCode = await process.exitCode;
  if (output != null) {
    output.stdout = _flattenToString(await savedStdout);
    output.stderr = _flattenToString(await savedStderr);
  }

  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    // Print the output when we get unexpected results (unless output was
    // printed already).
    switch (outputMode) {
      case OutputMode.print:
        break;
      case OutputMode.capture:
      case OutputMode.discard:
        stdout.writeln(_flattenToString(await savedStdout));
        stderr.writeln(_flattenToString(await savedStderr));
        break;
    }
    exitWithError(<String>[
      if (failureMessage != null)
        failureMessage
      else
        '${bold}ERROR: ${red}Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset',
      '${bold}Command: $green$commandDescription$reset',
      '${bold}Relative working directory: $cyan$relativeWorkingDir$reset',
    ]);
  }
  print('$clock ELAPSED TIME: ${prettyPrintDuration(time.elapsed)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');
}

/// Flattens a nested list of UTF-8 code units into a single string.
String _flattenToString(List<List<int>> chunks) =>
  utf8.decode(chunks.expand<int>((List<int> ints) => ints).toList());

/// Specifies what to do with command output from [runCommand].
enum OutputMode { print, capture, discard }

/// Stores command output from [runCommand] when used with [OutputMode.capture].
class CapturedOutput {
  String stdout;
  String stderr;
}
