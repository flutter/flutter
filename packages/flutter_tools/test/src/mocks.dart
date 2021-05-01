// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'fakes.dart';

/// A strategy for creating Process objects from a list of commands.
typedef _ProcessFactory = Process Function(List<String> command);

/// A ProcessManager that starts Processes by delegating to a ProcessFactory.
class MockProcessManager extends Mock implements ProcessManager {
  _ProcessFactory processFactory = _defaulProcessFactory;
  bool canRunSucceeds = true;
  bool runSucceeds = true;
  List<String> commands;

  static Process _defaulProcessFactory(List<String> commands) => FakeProcess();

  @override
  bool canRun(dynamic command, { String workingDirectory }) => canRunSucceeds;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    final List<String> commands = command.cast<String>();
    if (!runSucceeds) {
      final String executable = commands[0];
      final List<String> arguments = commands.length > 1 ? commands.sublist(1) : <String>[];
      throw ProcessException(executable, arguments);
    }

    this.commands = commands;
    return Future<Process>.value(processFactory(commands));
  }
}

/// A function that generates a process factory that gives processes that fail
/// a given number of times before succeeding. The returned processes will
/// fail after a delay if one is supplied.
_ProcessFactory flakyProcessFactory({
  int flakes,
  bool Function(List<String> command) filter,
  Duration delay,
  Stream<List<int>> Function() stdout,
  Stream<List<int>> Function() stderr,
}) {
  int flakesLeft = flakes;
  stdout ??= () => const Stream<List<int>>.empty();
  stderr ??= () => const Stream<List<int>>.empty();
  return (List<String> command) {
    if (filter != null && !filter(command)) {
      return FakeProcess();
    }
    if (flakesLeft == 0) {
      return FakeProcess(
        exitCode: Future<int>.value(0),
        stdout: stdout(),
        stderr: stderr(),
      );
    }
    flakesLeft = flakesLeft - 1;
    Future<int> exitFuture;
    if (delay == null) {
      exitFuture = Future<int>.value(-9);
    } else {
      exitFuture = Future<int>.delayed(delay, () => Future<int>.value(-9));
    }
    return FakeProcess(
      exitCode: exitFuture,
      stdout: stdout(),
      stderr: stderr(),
    );
  };
}
