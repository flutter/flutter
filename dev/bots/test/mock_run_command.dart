// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import '../run_command.dart';
import '../utils.dart';

class FakeCommandResult implements CommandResult {
  FakeCommandResult({
    this.exitCode = 0,
    this.elapsedTime = Duration.zero,
    this.flattenedStdout = '',
    this.flattenedStderr = '',
  });

  @override
  final int exitCode;

  @override
  final Duration elapsedTime;

  @override
  final String? flattenedStdout;

  @override
  final String? flattenedStderr;
}

class MockProcessRunner {
  final List<CommandResult> _mockResultsQueue = <CommandResult>[];
  final List<String> _commandsCalled = <String>[];

  void addMockResult(CommandResult result) {
    _mockResultsQueue.add(result);
  }

  void addMockResults(List<CommandResult> results) {
    _mockResultsQueue.addAll(results);
  }

  Future<CommandResult> mockRunCommand(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool expectNonZeroExit = false,
    int? expectedExitCode,
    String? failureMessage,
    OutputMode outputMode = OutputMode.print,
    bool Function(String line)? removeLine,
    void Function(String line, io.Process process)? outputListener,
  }) async {
    _commandsCalled.add('$executable ${arguments.join(' ')}');
    if (_mockResultsQueue.isEmpty) {
      throw StateError('Mock runCommand called more times than results provided.');
    }
    final CommandResult result = _mockResultsQueue.removeAt(0);

    bool shouldReportError = false;
    String expectedExitCodeMessage = '';

    if (expectedExitCode != null) {
      if (result.exitCode != expectedExitCode) {
        shouldReportError = true;
        expectedExitCodeMessage = '$expectedExitCode';
      }
    } else {
      if (expectNonZeroExit) {
        if (result.exitCode == 0) {
          shouldReportError = true;
          expectedExitCodeMessage = 'non-zero';
        }
      } else {
        if (result.exitCode != 0) {
          shouldReportError = true;
          expectedExitCodeMessage = 'zero';
        }
      }
    }

    if (shouldReportError) {
      foundError(<String>[
        'Mock for "$executable ${arguments.join(' ')}" failed.',
        'Exit code ${result.exitCode}, but expected $expectedExitCodeMessage.',
        if (result.flattenedStdout?.isNotEmpty ?? false) 'stdout: ${result.flattenedStdout}',
        if (result.flattenedStderr?.isNotEmpty ?? false) 'stderr: ${result.flattenedStderr}',
      ]);
    }
    return result;
  }
}
