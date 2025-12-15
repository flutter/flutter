// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ffi' show Abi;
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:engine_tool/src/commands/command.dart';
import 'package:engine_tool/src/commands/stamp_command.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

void main() {
  late io.Directory tempRoot;
  late TestEngine testEngine;

  setUp(() {
    tempRoot = io.Directory.systemTemp.createTempSync('engine_tool_test');
    testEngine = TestEngine.createTemp(rootDir: tempRoot);
    print('test root: $tempRoot');
  });

  tearDown(() {
    tempRoot.deleteSync(recursive: true);
  });

  group('creates stamp', () {
    late CommandRunner<int> et;

    var commandsRun = <List<String>>[];
    var testLogs = <LogRecord>[];
    var interceptCommands = <(String, FakeProcess? Function(List<String>))>[];

    setUp(() {
      // Be very permissive on process execution, and check usage below instead.
      final permissiveProcessManager = FakeProcessManager(
        canRun: (_, {workingDirectory}) => true,
        onRun: (FakeCommandLogEntry entry) {
          commandsRun.add(entry.command);
          return io.ProcessResult(81, 0, '', '');
        },
        onStart: (FakeCommandLogEntry entry) {
          commandsRun.add(entry.command);
          for (final intercept in interceptCommands) {
            if (entry.command.first.endsWith(intercept.$1)) {
              final FakeProcess? result = intercept.$2(entry.command);
              if (result != null) {
                return result;
              }
            }
          }
          switch (entry.command) {
            case ['git', 'rev-parse', 'HEAD']:
              return FakeProcess(stdout: 'a' * 40);
            case ['git', 'show', '-s', '--pretty=format:%ad', '--date=iso-strict']:
              return FakeProcess(stdout: '2025-06-27T17:11:53-07:00');
            default:
              if (entry.command.first.endsWith('content_aware_hash.sh')) {
                return FakeProcess(stdout: '1' * 40);
              }
              return FakeProcess();
          }
        },
      );

      // Set up the environment for the test.
      final testEnvironment = Environment(
        abi: Abi.linuxX64,
        engine: testEngine,
        logger: Logger.test((log) {
          testLogs.add(log);
        }),
        platform: _fakePlatform(Platform.linux),
        processRunner: ProcessRunner(
          defaultWorkingDirectory: tempRoot,
          processManager: permissiveProcessManager,
        ),
        now: () => DateTime.utc(2025, 6, 27, 12, 30),
      );

      // Set up the Flutter tool for the test.
      et = _engineTool(StampCommand(environment: testEnvironment));

      // Reset logs.
      commandsRun = [];
      testLogs = [];
      interceptCommands = [];
    });

    tearDown(() {
      printOnFailure('Commands run:\n${commandsRun.map((c) => c.join('\n'))}');
      printOnFailure('Logs:\n${testLogs.map((l) => l.message).join('\n')}');
    });

    test('dry-run output', () async {
      await et.run(['stamp', '--dry-run']);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder(['git', contains('rev-parse'), contains('HEAD')]),
          containsAllInOrder([
            'git',
            contains('show'),
            contains('-s'),
            contains('--pretty=format:%ad'),
            contains('--date=iso'),
          ]),
          containsAllInOrder([endsWith('content_aware_hash.sh')]),
        ]),
      );
      final List<String> logStrings = [for (final log in testLogs) log.message.trim()];

      expect(
        logStrings,
        containsAllInOrder([
          endsWith('src/out/engine_stamp.json:'),
          contains(
            '{"build_date":"2025-06-27T12:30:00.000Z","build_time_ms":1751027400000,"git_revision":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","git_revision_date":"2025-06-27T17:11:53-07:00","content_hash":"1111111111111111111111111111111111111111"}',
          ),
        ]),
      );
    });

    test('writes to engine_stamp.json', () async {
      await et.run(['stamp']);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder(['git', contains('rev-parse'), contains('HEAD')]),
          containsAllInOrder([
            'git',
            contains('show'),
            contains('-s'),
            contains('--pretty=format:%ad'),
            contains('--date=iso'),
          ]),
          containsAllInOrder([endsWith('content_aware_hash.sh')]),
        ]),
      );
      expect(testLogs, isEmpty);
      expect(io.File(p.join(tempRoot.path, 'src/out/engine_stamp.json')).existsSync(), isTrue);
      expect(
        io.File(p.join(tempRoot.path, 'src/out/engine_stamp.json')).readAsStringSync().trim(),
        '{"build_date":"2025-06-27T12:30:00.000Z","build_time_ms":1751027400000,"git_revision":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","git_revision_date":"2025-06-27T17:11:53-07:00","content_hash":"1111111111111111111111111111111111111111"}',
      );
    });
  });
}

CommandRunner<int> _engineTool(CommandBase command) {
  return CommandRunner<int>('et', 'Fake tool with a single instrumented command.')
    ..addCommand(command);
}

Platform _fakePlatform(String os, {int numberOfProcessors = 32, String pathSeparator = '/'}) {
  return FakePlatform(
    operatingSystem: os,
    resolvedExecutable: io.Platform.resolvedExecutable,
    numberOfProcessors: numberOfProcessors,
    pathSeparator: pathSeparator,
  );
}
