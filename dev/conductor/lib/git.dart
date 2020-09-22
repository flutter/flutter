// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// A wrapper around git process calls that can be mocked for unit testing.
class Git {
  const Git();

  String getOutput(String command, String explanation) {
    final ProcessResult result = _run(command);
    if ((result.stderr as String).isEmpty && result.exitCode == 0)
      return (result.stdout as String).trim();
    _reportFailureAndExit(result, explanation);
    return null; // for the analyzer's sake
  }

  void run(String command, String explanation) {
    final ProcessResult result = _run(command);
    if (result.exitCode != 0) {
      _reportFailureAndExit(result, explanation);
    }
  }

  // TODO: this should not be a [Git] method.
  /// Obtain the version tag of the previous dev release.
  String getFullTag(String remote) {
    const String glob = '*.*.*-*.*.pre';
    // describe the latest dev release
    final String ref = 'refs/remotes/$remote/dev';
    return getOutput(
        'describe --match $glob --exact-match --tags $ref',
        'obtain last released version number',
    );
  }

  ProcessResult _run(String command) {
    return Process.runSync('git', command.split(' '));
  }

  void _reportFailureAndExit(ProcessResult result, String explanation) {
    final StringBuffer message = StringBuffer();
    if (result.exitCode != 0) {
      message.writeln('Failed to $explanation. Git exited with error code ${result.exitCode}.');
    } else {
      message.writeln('Failed to $explanation.');
    }
    if ((result.stdout as String).isNotEmpty)
      message.writeln('stdout from git:\n${result.stdout}\n');
    if ((result.stderr as String).isNotEmpty)
      message.writeln('stderr from git:\n${result.stderr}\n');
    throw Exception(message);
  }
}
