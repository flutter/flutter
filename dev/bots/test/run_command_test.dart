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

  test('checkExitCode: false skips foundError on non-zero and zero exits', () async {
    final String failingScript = writeDartScript('''
stdout.writeln('probe output');
exitCode = 7;''');
    final CommandResult nonZeroResult = await runCommand(
      io.Platform.resolvedExecutable,
      <String>[failingScript],
      checkExitCode: false,
      outputMode: OutputMode.capture,
    );
    expect(nonZeroResult.exitCode, 7, reason: log.join('\n'));
    expect(nonZeroResult.flattenedStdout, 'probe output');
    expect(nonZeroResult.flattenedStderr, isEmpty);
    expect(hasError, isFalse);

    final String passingScript = writeDartScript("stdout.writeln('ok');");
    final CommandResult zeroResult = await runCommand(
      io.Platform.resolvedExecutable,
      <String>[passingScript],
      checkExitCode: false,
      outputMode: OutputMode.capture,
    );
    expect(zeroResult.exitCode, 0, reason: log.join('\n'));
    expect(zeroResult.flattenedStdout, 'ok');
    expect(hasError, isFalse);

    await expectLater(
      runCommand(
        io.Platform.resolvedExecutable,
        <String>[passingScript],
        checkExitCode: false,
        expectNonZeroExit: true,
      ),
      throwsA(isA<AssertionError>()),
    );
    await expectLater(
      runCommand(
        io.Platform.resolvedExecutable,
        <String>[passingScript],
        checkExitCode: false,
        expectedExitCode: 7,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('decodes malformed UTF-8 bytes on stdout and stderr without FormatException', () async {
    final String script = writeDartScript(r'''
stdout.add(<int>[...'ok'.codeUnits, 0xFF, 0xFE, ...'-tail\nline2\n'.codeUnits]);
stderr.add(<int>[...'err'.codeUnits, 0x80, ...'-tail\nerr2\n'.codeUnits]);''');
    final CommandResult result = await runCommand(io.Platform.resolvedExecutable, <String>[
      script,
    ], outputMode: OutputMode.capture);
    expect(result.exitCode, 0, reason: log.join('\n'));
    expect(result.flattenedStdout, 'ok\uFFFD\uFFFD-tail\nline2');
    expect(result.flattenedStderr, 'err\uFFFD-tail\nerr2');
    expect(hasError, isFalse);
  });

  test(
    'outputListener and stderrListener receive stream lines alongside captured output',
    () async {
      final String script = writeDartScript('''
stdout.writeln('out-line');
stderr.writeln('err-line-1');
stderr.writeln('err-line-2');''');
      final stdoutLines = <String>[];
      final stderrLines = <String>[];
      io.Process? stdoutProcess;
      io.Process? stderrProcess;
      final CommandResult result = await runCommand(
        io.Platform.resolvedExecutable,
        <String>[script],
        outputMode: OutputMode.capture,
        outputListener: (String line, io.Process process) {
          stdoutProcess = process;
          stdoutLines.add(line);
        },
        stderrListener: (String line, io.Process process) {
          stderrProcess = process;
          stderrLines.add(line);
        },
      );
      expect(result.exitCode, 0, reason: log.join('\n'));
      expect(stdoutLines, <String>['out-line\n']);
      expect(stderrLines, <String>['err-line-1\n', 'err-line-2\n']);
      expect(result.flattenedStdout, 'out-line');
      expect(result.flattenedStderr, 'err-line-1\nerr-line-2');
      expect(stdoutProcess?.pid, greaterThan(0));
      expect(stdoutProcess, same(stderrProcess));
      expect(hasError, isFalse);
    },
  );

  test('stderrListener can terminate a running process on stderr output', () async {
    final String script = writeDartScript('''
stderr.writeln('hang-sentinel');
Timer(const Duration(minutes: 1), () {});''');
    var killedFromStderr = false;
    final CommandResult result = await runCommand(
      io.Platform.resolvedExecutable,
      <String>[script],
      checkExitCode: false,
      outputMode: OutputMode.capture,
      stderrListener: (String line, io.Process process) {
        if (!killedFromStderr && line.contains('hang-sentinel')) {
          killedFromStderr = true;
          process.kill();
        }
      },
    );
    expect(killedFromStderr, isTrue, reason: log.join('\n'));
    expect(result.exitCode, isNot(0));
    expect(hasError, isFalse);
  });
}
