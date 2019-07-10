// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String green = hasColor ? '\x1B[32m' : ''; // used for section titles, commands
final String yellow = hasColor ? '\x1B[33m' : ''; // unused
final String cyan = hasColor ? '\x1B[36m' : ''; // used for paths
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks
final String reset = hasColor ? '\x1B[0m' : '';
final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';

String get clock {
  final DateTime now = DateTime.now();
  return '$reverse▌'
         '${now.hour.toString().padLeft(2, "0")}:'
         '${now.minute.toString().padLeft(2, "0")}:'
         '${now.second.toString().padLeft(2, "0")}'
         '▐$reset';
}

String prettyPrintDuration(Duration duration) {
  String result = '';
  final int minutes = duration.inMinutes;
  if (minutes > 0)
    result += '${minutes}min ';
  final int seconds = duration.inSeconds - minutes * 60;
  final int milliseconds = duration.inMilliseconds - (seconds * 1000 + minutes * 60 * 1000);
  result += '$seconds.${milliseconds.toString().padLeft(3, "0")}s';
  return result;
}

void printProgress(String action, String workingDir, String command) {
  print('$clock $action: cd $cyan$workingDir$reset; $green$command$reset');
}

Stream<String> runAndGetStdout(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectNonZeroExit = false,
  int expectedExitCode,
  String failureMessage,
  Function beforeExit,
}) async* {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);

  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Stopwatch time = Stopwatch()..start();
  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  stderr.addStream(process.stderr);
  final Stream<String> lines = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
  await for (String line in lines) {
    yield line;
  }

  final int exitCode = await process.exitCode;
  print('$clock ELAPSED TIME: ${prettyPrintDuration(time.elapsed)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');
  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    if (failureMessage != null) {
      print(failureMessage);
    }
    print(
        '$redLine\n'
        '${bold}ERROR: ${red}Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset\n'
        '${bold}Command: $green$commandDescription$reset\n'
        '${bold}Relative working directory: $cyan$relativeWorkingDir$reset\n'
        '$redLine'
    );
    beforeExit?.call();
    exit(1);
  }
}

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
}) async {
  assert((outputMode == OutputMode.capture) == (output != null),
      'The output parameter must be non-null with and only with '
      'OutputMode.capture');

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

  Future<List<List<int>>> savedStdout, savedStderr;
  final Stream<List<int>> stdoutSource = process.stdout
    .transform<String>(const Utf8Decoder())
    .transform(const LineSplitter())
    .where((String line) => removeLine == null || !removeLine(line))
    .map((String line) => '$line\n')
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
  print('$clock ELAPSED TIME: ${prettyPrintDuration(time.elapsed)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');

  if (output != null) {
    output.stdout = _flattenToString(await savedStdout);
    output.stderr = _flattenToString(await savedStderr);
  }

  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    if (failureMessage != null) {
      print(failureMessage);
    }

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
    print(
        '$redLine\n'
        '${bold}ERROR: ${red}Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset\n'
        '${bold}Command: $green$commandDescription$reset\n'
        '${bold}Relative working directory: $cyan$relativeWorkingDir$reset\n'
        '$redLine'
    );
    exit(1);
  }
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
