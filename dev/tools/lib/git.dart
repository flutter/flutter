// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import './globals.dart';

/// A wrapper around git process calls that can be mocked for unit testing.
class Git {
  Git(this.processManager) : assert(processManager != null);

  final ProcessManager processManager;

  String getOutput(
    List<String> args,
    String explanation, {
    @required String workingDirectory,
  }) {
    final ProcessResult result = _run(args, workingDirectory);
    if (result.exitCode == 0) {
      return stdoutToString(result.stdout);
    }
    _reportFailureAndExit(args, workingDirectory, result, explanation);
    return null; // for the analyzer's sake
  }

  int run(
    List<String> args,
    String explanation, {
    bool allowNonZeroExitCode = false,
    @required String workingDirectory,
  }) {
    final ProcessResult result = _run(args, workingDirectory);
    if (result.exitCode != 0 && !allowNonZeroExitCode) {
      _reportFailureAndExit(args, workingDirectory, result, explanation);
    }
    return result.exitCode;
  }

  ProcessResult _run(List<String> args, String workingDirectory) {
    return processManager.runSync(
      <String>['git', ...args],
      workingDirectory: workingDirectory,
      environment: <String, String>{'GIT_TRACE': '1'},
    );
  }

  void _reportFailureAndExit(
    List<String> args,
    String workingDirectory,
    ProcessResult result,
    String explanation,
  ) {
    final StringBuffer message = StringBuffer();
    if (result.exitCode != 0) {
      message.writeln(
        'Command "git ${args.join(' ')}" failed in directory "$workingDirectory" to '
        '$explanation. Git exited with error code ${result.exitCode}.',
      );
    } else {
      message.writeln('Command "git ${args.join(' ')}" failed to $explanation.');
    }
    if ((result.stdout as String).isNotEmpty)
      message.writeln('stdout from git:\n${result.stdout}\n');
    if ((result.stderr as String).isNotEmpty)
      message.writeln('stderr from git:\n${result.stderr}\n');
    throw Exception(message);
  }
}
