// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:process/process.dart';

import './globals.dart';

/// A wrapper around git process calls that can be mocked for unit testing.
///
/// The `Git` class is a relatively (compared to `Repository`) lightweight
/// abstraction over invocations to the `git` cli tool. The main
/// motivation for creating this class was so that it could be overridden in
/// tests. However, now that tests rely on the [FakeProcessManager] this
/// abstraction is redundant.
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
    late final ProcessResult result;
    try {
      result = await _run(args, workingDirectory);
    } on ProcessException {
      _reportFailureAndExit(args, workingDirectory, result, explanation);
    }
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
    throw GitException(message.toString(), args);
  }
}

enum GitExceptionType {
  /// Git push failed because the remote branch contained commits the local did
  /// not.
  ///
  /// Either the local branch was wrong, and needs a rebase before pushing
  /// again, or the remote branch needs to be overwritten with a force push.
  ///
  /// Example output:
  ///
  /// ```none
  /// To github.com:user/engine.git
  ///
  ///  ! [rejected]            HEAD -> cherrypicks-flutter-2.8-candidate.3 (non-fast-forward)
  /// error: failed to push some refs to 'github.com:user/engine.git'
  /// hint: Updates were rejected because the tip of your current branch is behind
  /// hint: its remote counterpart. Integrate the remote changes (e.g.
  /// hint: 'git pull ...') before pushing again.
  /// hint: See the 'Note about fast-forwards' in 'git push --help' for details.
  /// ```
  PushRejected,
}

/// An exception created because a git subprocess failed.
///
/// Known git failures will be assigned a [GitExceptionType] in the [type]
/// field. If this field is null it means and unknown git failure.
class GitException implements Exception {
  GitException(this.message, this.args) {
    if (_pushRejectedPattern.hasMatch(message)) {
      type = GitExceptionType.PushRejected;
    } else {
      // because type is late final, it must be explicitly set before it is
      // accessed.
      type = null;
    }
  }

  static final RegExp _pushRejectedPattern = RegExp(
    r'Updates were rejected because the tip of your current branch is behind',
  );

  final String message;
  final List<String> args;
  late final GitExceptionType? type;

  @override
  String toString() => 'Exception on command "${args.join(' ')}": $message';
}
