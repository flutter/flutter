// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:process/process.dart';

import './globals.dart';

/// A wrapper around git process calls that can be mocked for unit testing.
class Git {
  const Git(this.processManager);

  final ProcessManager processManager;

  Future<String> getOutput(
    List<String> args,
    String explanation, {
    required String workingDirectory,
    bool allowFailures = false,
  }) async {
    final ProcessResult result = await _run(args, workingDirectory);
    if (result.exitCode == 0) {
      return stdoutToString(result.stdout);
    }
    _reportFailureAndExit(args, workingDirectory, result, explanation);
  }

  Future<int> run(
    List<String> args,
    String explanation, {
    bool allowNonZeroExitCode = false,
    required String workingDirectory,
  }) async {
    final ProcessResult result = await _run(args, workingDirectory);
    if (result.exitCode != 0 && !allowNonZeroExitCode) {
      _reportFailureAndExit(args, workingDirectory, result, explanation);
    }
    return result.exitCode;
  }

  Future<ProcessResult> _run(List<String> args, String workingDirectory) async {
    return processManager.run(
      <String>['git', ...args],
      workingDirectory: workingDirectory,
      environment: <String, String>{'GIT_TRACE': '1'},
    );
  }

  Never _reportFailureAndExit(
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
    if ((result.stdout as String).isNotEmpty) {
      message.writeln('stdout from git:\n${result.stdout}\n');
    }
    if ((result.stderr as String).isNotEmpty) {
      message.writeln('stderr from git:\n${result.stderr}\n');
    }
    throw GitException(message.toString());
  }
}

class GitException implements Exception {
  GitException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}
