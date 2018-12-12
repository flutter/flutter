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

Future<void> runCommand(String executable, List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectNonZeroExit = false,
  int expectedExitCode,
  String failureMessage,
  bool printOutput = true,
  bool skip = false,
  Duration timeout = _kLongTimeout,
}) async {
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
  if (printOutput) {
    await Future.wait<void>(<Future<void>>[
      stdout.addStream(process.stdout),
      stderr.addStream(process.stderr)
    ]);
  } else {
    savedStdout = process.stdout.toList();
    savedStderr = process.stderr.toList();
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
    if (!printOutput) {
      stdout.writeln(utf8.decode((await savedStdout).expand<int>((List<int> ints) => ints).toList()));
      stderr.writeln(utf8.decode((await savedStderr).expand<int>((List<int> ints) => ints).toList()));
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
