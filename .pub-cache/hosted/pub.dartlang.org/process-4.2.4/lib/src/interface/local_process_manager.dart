// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io'
    show
        Process,
        ProcessResult,
        ProcessSignal,
        ProcessStartMode,
        ProcessException,
        systemEncoding;

import 'common.dart';
import 'exceptions.dart';
import 'process_manager.dart';

/// Local implementation of the `ProcessManager` interface.
///
/// This implementation delegates directly to the corresponding static methods
/// in `dart:io`.
///
/// All methods that take a `command` will run `toString()` on the command
/// elements to derive the executable and arguments that should be passed to
/// the underlying `dart:io` methods. Thus, the degenerate case of
/// `List<String>` will trivially work as expected.
class LocalProcessManager implements ProcessManager {
  /// Creates a new `LocalProcessManager`.
  const LocalProcessManager();

  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    try {
      return Process.start(
        sanitizeExecutablePath(_getExecutable(
          command,
          workingDirectory,
          runInShell,
        )),
        _getArguments(command),
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        mode: mode,
      );
    } on ProcessException catch (exception) {
      throw ProcessPackageException.fromProcessException(exception,
          workingDirectory: workingDirectory);
    }
  }

  @override
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    try {
      return Process.run(
        sanitizeExecutablePath(_getExecutable(
          command,
          workingDirectory,
          runInShell,
        )),
        _getArguments(command),
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      );
    } on ProcessException catch (exception) {
      throw ProcessPackageException.fromProcessException(exception,
          workingDirectory: workingDirectory);
    }
  }

  @override
  ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) {
    try {
      return Process.runSync(
        sanitizeExecutablePath(_getExecutable(
          command,
          workingDirectory,
          runInShell,
        )),
        _getArguments(command),
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      );
    } on ProcessException catch (exception) {
      throw ProcessPackageException.fromProcessException(exception,
          workingDirectory: workingDirectory);
    }
  }

  @override
  bool canRun(covariant String executable, {String? workingDirectory}) =>
      getExecutablePath(executable, workingDirectory, throwOnFailure: false) !=
      null;

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
    return Process.killPid(pid, signal);
  }
}

String _getExecutable(
    List<dynamic> command, String? workingDirectory, bool runInShell) {
  String commandName = command.first.toString();
  if (runInShell) {
    return commandName;
  }
  return getExecutablePath(
    commandName,
    workingDirectory,
    throwOnFailure: true,
  )!;
}

List<String> _getArguments(List<Object> command) =>
    // Adding a specific type to map in order to workaround dart issue
    // https://github.com/dart-lang/sdk/issues/32414
    command
        .skip(1)
        .map<String>((dynamic element) => element.toString())
        .toList();
