// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : '';
final String red = hasColor ? '\x1B[31m' : '';
final String green = hasColor ? '\x1B[32m' : '';
final String yellow = hasColor ? '\x1B[33m' : '';
final String cyan = hasColor ? '\x1B[36m' : '';
final String reset = hasColor ? '\x1B[0m' : '';
final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';
const String arrow = '⏩';
const String clock = '🕐';

const Duration _kLongTimeout = Duration(minutes: 45);

String elapsedTime(DateTime start) {
  return DateTime.now().difference(start).toString();
}

void printProgress(String action, String workingDir, String command) {
  print('$arrow $action: cd $cyan$workingDir$reset; $yellow$command$reset');
}

Stream<String> runAndGetStdout(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectNonZeroExit = false,
  int expectedExitCode,
  String failureMessage,
  Duration timeout = _kLongTimeout,
  Function beforeExit,
}) async* {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);

  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final DateTime start = DateTime.now();
  final Process process = await Process.start(executable, arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  stderr.addStream(process.stderr);
  final Stream<String> lines = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
  await for (String line in lines) {
    yield line;
  }

  final int exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
    stderr.writeln('Process timed out after $timeout');
    return expectNonZeroExit ? 0 : 1;
  });
  print('$clock ELAPSED TIME: $bold${elapsedTime(start)}$reset for $commandDescription in $relativeWorkingDir: ');
  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    if (failureMessage != null) {
      print(failureMessage);
    }
    print(
        '$redLine\n'
            '${bold}ERROR:$red Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset\n'
            '${bold}Command:$cyan $commandDescription$reset\n'
            '${bold}Relative working directory:$red $relativeWorkingDir$reset\n'
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
  bool expectFlaky = false,
  Duration timeout = _kLongTimeout,
  bool Function(String) removeLine,
}) async {
  assert((outputMode == OutputMode.capture) == (output != null));

  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return;
  }
  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final DateTime start = DateTime.now();
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
  if (outputMode == OutputMode.print) {
    await Future.wait<void>(<Future<void>>[
      stdout.addStream(stdoutSource),
      stderr.addStream(process.stderr),
    ]);
  } else {
    savedStdout = stdoutSource.toList();
    savedStderr = process.stderr.toList();
  }

  final int exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
    stderr.writeln('Process timed out after $timeout');
    return (expectNonZeroExit || expectFlaky) ? 0 : 1;
  });
  print('$clock ELAPSED TIME: $bold${elapsedTime(start)}$reset for $commandDescription in $relativeWorkingDir: ');

  if (output != null) {
    output.stdout = flattenToString(await savedStdout);
    output.stderr = flattenToString(await savedStderr);
  }

  // If the test is flaky we don't care about the actual exit.
  if (expectFlaky) {
    return;
  }
  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    if (failureMessage != null) {
      print(failureMessage);
    }

    // Print the output when we get unexpected results (unless output was
    // printed already).
    if (outputMode != OutputMode.print) {
      stdout.writeln(flattenToString(await savedStdout));
      stderr.writeln(flattenToString(await savedStderr));
    }
    print(
        '$redLine\n'
            '${bold}ERROR:$red Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset\n'
            '${bold}Command:$cyan $commandDescription$reset\n'
            '${bold}Relative working directory:$red $relativeWorkingDir$reset\n'
            '$redLine'
    );
    exit(1);
  }
}

T identity<T>(T x) => x;

/// Flattens a nested list of UTF-8 code units into a single string.
String flattenToString(List<List<int>> chunks) =>
  utf8.decode(chunks.expand<int>(identity).toList(growable: false));

/// Specifies what to do with command output from [runCommand].
enum OutputMode { print, capture, discard }

/// Stores command output from [runCommand] when used with [OutputMode.capture].
class CapturedOutput {
  String stdout;
  String stderr;
}
