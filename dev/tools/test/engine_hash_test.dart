// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: always_specify_types

import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../bin/engine_hash.dart' show GitRevisionStrategy, engineHash;

void main() {
  test('Produces an engine hash for merge-base', () async {
    final runProcess = _fakeProcesses(processes: <FakeProcess>[
      (
        exe: 'git',
        command: 'merge-base',
        rest: ['upstream/main', 'HEAD'],
        exitCode: 0,
        stdout: 'abcdef1234',
        stderr: null
      ),
      (
        exe: 'git',
        command: 'ls-tree',
        rest: ['-r', 'abcdef1234', 'engine', 'DEPS'],
        exitCode: 0,
        stdout: 'one\r\ntwo\r\n',
        stderr: null
      ),
    ]);

    final result = await engineHash(runProcess);

    expect(result,
        (result: 'c708d7ef841f7e1748436b8ef5670d0b2de1a227', error: null));
  });

  test('Produces an engine hash for HEAD', () async {
    final runProcess = _fakeProcesses(processes: <FakeProcess>[
      (
        exe: 'git',
        command: 'ls-tree',
        rest: ['-r', 'HEAD', 'engine', 'DEPS'],
        exitCode: 0,
        stdout: 'one\ntwo\n',
        stderr: null
      ),
    ]);

    final result = await engineHash(runProcess,
        revisionStrategy: GitRevisionStrategy.head);

    expect(result,
        (result: 'c708d7ef841f7e1748436b8ef5670d0b2de1a227', error: null));
  });

  test('Returns error in non-monorepo', () async {
    final runProcess = _fakeProcesses(processes: <FakeProcess>[
      (
        exe: 'git',
        command: 'ls-tree',
        rest: ['-r', 'HEAD', 'engine', 'DEPS'],
        exitCode: 0,
        stdout: '',
        stderr: null
      ),
    ]);

    final result = await engineHash(runProcess,
        revisionStrategy: GitRevisionStrategy.head);

    expect(result, (result: '', error: 'Not in a monorepo'));
  });
}

typedef FakeProcess = ({
  String exe,
  String command,
  List<String> rest,
  dynamic stdout,
  dynamic stderr,
  int exitCode
});

Future<io.ProcessResult> Function(List<String>) _fakeProcesses({
  required List<FakeProcess> processes,
}) =>
    (List<String> cmd) async {
      for (final process in processes) {
        if (process.exe.endsWith(cmd[0]) &&
            process.command.endsWith(cmd[1]) &&
            process.rest.equals(cmd.sublist(2))) {
          return io.ProcessResult(
              1, process.exitCode, process.stdout, process.stderr);
        }
      }
      return io.ProcessResult(1, -42, '', '404 command not found: $cmd');
    };
