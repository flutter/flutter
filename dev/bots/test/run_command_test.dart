// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';

import 'common.dart';

void main() {
  late PrintCallback oldPrint;
  late List<Object?> log;

  setUp(() {
    oldPrint = print;
    log = <Object?>[];
    print = log.add;
  });

  tearDown(() {
    print = oldPrint;
    resetErrorStatus();
  });

  String writeDartScript(String mainBody) {
    final io.Directory tempDir = io.Directory.systemTemp.createTempSync('run_command_test.');
    addTearDown(() => tryToDelete(tempDir));
    final script = io.File(path.join(tempDir.path, 'script.dart'))
      ..writeAsStringSync("import 'dart:async';\nimport 'dart:io';\nvoid main() {\n$mainBody\n}\n");
    return script.path;
  }

  // The first two tests only run on Linux. They test platform-agnostic code that
  // is triggered by platform-sensitive code. To avoid having to complicate our
  // test harness by using a mockable process manager, those two tests rely on one
  // platform's conventions (Linux having `/usr/bin/sh`). The logic being tested
  // is not so critical that it matters that we're only testing it on one platform.

  test('short output on runCommand failure', () async {
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
  }, skip: !io.Platform.isLinux); // [intended] See comments above.

  test('long output on runCommand failure', () async {
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
  }, skip: !io.Platform.isLinux); // [intended] See comments above.

  test('an accepted exit code is not a failure', () async {
    final List<Object?> log = <String>[];
    final PrintCallback oldPrint = print;
    print = log.add;
    try {
      final CommandResult result = await runCommand(
        '/usr/bin/sh',
        <String>['-c', 'exit $kNoTestsRanExitCode'],
        acceptedExitCodes: const <int>{kNoTestsRanExitCode},
      );
      expect(result.exitCode, kNoTestsRanExitCode);
      expect(hasError, isFalse);
      expect(log, <Object>[
        startsWith('RUNNING:'),
        'workingDirectory: null, executable: /usr/bin/sh, arguments: [-c, exit $kNoTestsRanExitCode]',
        startsWith('ELAPSED TIME:'),
      ]);
      await runCommand(
        '/usr/bin/sh',
        <String>['-c', 'exit 1'],
        acceptedExitCodes: const <int>{kNoTestsRanExitCode},
      );
      expect(hasError, isTrue);
    } finally {
      print = oldPrint;
      resetErrorStatus();
    }
  }, skip: !io.Platform.isLinux); // [intended] See comments above.
}
