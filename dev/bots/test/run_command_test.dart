// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import '../run_command.dart';
import '../utils.dart';

import 'common.dart';

void main() {
  // These tests only run on Linux. They test platform-agnostic code that is
  // triggered by platform-sensitive code. To avoid having to complicate our
  // test harness by using a mockable process manager, the tests rely on one
  // platform's conventions (Linux having `sh`). The logic being tested is not
  // so critical that it matters that we're only testing it on one platform.

  test('short output on runCommand failure', () async {
    final List<Object?> log = <String>[];
    final PrintCallback oldPrint = print;
    print = log.add;
    try {
      await runCommand('/usr/bin/sh', <String>['-c', 'echo test; false']);
      expect(log, <Object>[
        startsWith('RUNNING:'),
        'workingDirectory: null, executable: /usr/bin/sh, arguments: [-c, echo test; false]',
        'test',
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        startsWith('║ Command: '),
        '║ Command exited with exit code 1 but expected zero exit code.',
        startsWith('║ Working directory: '),
        '║ stdout and stderr output:',
        '║ test',
        '║ ',
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ]);
    } finally {
      print = oldPrint;
      resetErrorStatus();
    }
  }, skip: !io.Platform.isLinux); // [intended] See comments above.

  test('long output on runCommand failure', () async {
    final List<Object?> log = <String>[];
    final PrintCallback oldPrint = print;
    print = log.add;
    try {
      await runCommand('/usr/bin/sh', <String>['-c', 'echo ${"meow" * 1024}; false']);
      expect(log, <Object>[
        startsWith('RUNNING:'),
        'workingDirectory: null, executable: /usr/bin/sh, arguments: [-c, echo ${"meow" * 1024}; false]',
        'meow' * 1024,
        '╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════',
        startsWith('║ Command: '),
        '║ Command exited with exit code 1 but expected zero exit code.',
        startsWith('║ Working directory: '),
        '╚═══════════════════════════════════════════════════════════════════════════════',
      ]);
    } finally {
      print = oldPrint;
      resetErrorStatus();
    }
  }, skip: !io.Platform.isLinux); // [intended] See comments above.

  test('allowNonZeroExit does not record error on non-zero or zero exit', () async {
    final List<Object?> log = <String>[];
    final PrintCallback oldPrint = print;
    print = log.add;
    try {
      final CommandResult failed = await runCommand(
        '/bin/sh',
        <String>['-c', 'exit 1'],
        allowNonZeroExit: true,
        outputMode: OutputMode.capture,
      );
      expect(failed.exitCode, 1);
      expect(hasError, isFalse);

      final CommandResult succeeded = await runCommand(
        '/bin/sh',
        <String>['-c', 'exit 0'],
        allowNonZeroExit: true,
        outputMode: OutputMode.capture,
      );
      expect(succeeded.exitCode, 0);
      expect(hasError, isFalse);
    } finally {
      print = oldPrint;
      resetErrorStatus();
    }
  }, skip: io.Platform.isWindows); // [intended] Relies on POSIX /bin/sh.

  test('stderrListener receives stderr lines and can interrupt hung process', () async {
    final List<Object?> log = <String>[];
    final PrintCallback oldPrint = print;
    print = log.add;
    final stderrLines = <String>[];
    try {
      final CommandResult result = await runCommand(
        '/bin/sh',
        <String>['-c', 'echo "hung-on-stderr" >&2; read _'],
        allowNonZeroExit: true,
        outputMode: OutputMode.capture,
        stderrListener: (String line, io.Process process) {
          stderrLines.add(line);
          if (line.contains('hung-on-stderr')) {
            process.kill();
          }
        },
      );
      expect(stderrLines, <String>['hung-on-stderr\n']);
      expect(result.exitCode, isNot(0));
      expect(hasError, isFalse);
    } finally {
      print = oldPrint;
      resetErrorStatus();
    }
  }, skip: io.Platform.isWindows); // [intended] Relies on POSIX /bin/sh.

  test('tolerates malformed UTF-8 bytes in subprocess output', () async {
    final List<Object?> log = <String>[];
    final PrintCallback oldPrint = print;
    print = log.add;
    try {
      final CommandResult result = await runCommand('/bin/sh', <String>[
        '-c',
        r"printf 'prefix\377suffix\n'",
      ], outputMode: OutputMode.capture);
      expect(result.exitCode, 0);
      expect(result.flattenedStdout, contains('prefix'));
      expect(result.flattenedStdout, contains('suffix'));
      expect(hasError, isFalse);
    } finally {
      print = oldPrint;
      resetErrorStatus();
    }
  }, skip: io.Platform.isWindows); // [intended] Relies on POSIX /bin/sh.
}
