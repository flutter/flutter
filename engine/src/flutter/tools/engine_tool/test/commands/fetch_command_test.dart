// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' as ffi show Abi;
import 'dart:io' as io;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

void main() {
  final configs = <String, BuilderConfig>{};

  // An engine of the test's own, so that the tests do not depend on how the
  // checkout they run in was made: with a `.gclient` beside it, as `gclient
  // sync` needs one, or without, as a plain clone is (which is all the Bazel
  // build needs).
  late io.Directory root;
  late Engine engine;

  setUp(() {
    root = io.Directory.systemTemp.createTempSync('et_fetch_test');
    engine = TestEngine.createTemp(rootDir: root);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  void writeDotGclient() {
    io.File(path.join(root.path, '.gclient')).writeAsStringSync('');
  }

  (Environment, List<FakeCommandLogEntry>) linuxEnv(
    Logger logger, {
    Map<String, String>? environment,
    bool gclientOnPath = true,
  }) {
    final runHistory = <FakeCommandLogEntry>[];
    return (
      Environment(
        abi: ffi.Abi.linuxX64,
        engine: engine,
        platform: FakePlatform(
          operatingSystem: Platform.linux,
          resolvedExecutable: io.Platform.resolvedExecutable,
          pathSeparator: '/',
          environment: environment,
        ),
        processRunner: ProcessRunner(
          processManager: FakeProcessManager(
            onStart: (FakeCommandLogEntry entry) {
              runHistory.add(entry);
              return FakeProcess();
            },
            onRun: (FakeCommandLogEntry entry) {
              runHistory.add(entry);
              return io.ProcessResult(81, 0, '', '');
            },
            canRun: (Object? executable, {String? workingDirectory}) => gclientOnPath,
          ),
        ),
        logger: logger,
      ),
      runHistory,
    );
  }

  test('fetch command invokes gclient sync -D', () async {
    writeDotGclient();
    final logger = Logger.test((_) {});
    final (Environment env, List<FakeCommandLogEntry> runHistory) = linuxEnv(logger);
    final runner = ToolCommandRunner(environment: env, configs: configs);
    final int result = await runner.run(<String>['fetch']);
    expect(result, equals(0));
    expect(runHistory.length, greaterThanOrEqualTo(1));
    expect(runHistory[0].command, containsAllInOrder(<String>['gclient', 'sync', '-D']));
  });

  test('fetch command has sync alias', () async {
    writeDotGclient();
    final logger = Logger.test((_) {});
    final (Environment env, List<FakeCommandLogEntry> runHistory) = linuxEnv(logger);
    final runner = ToolCommandRunner(environment: env, configs: configs);
    final int result = await runner.run(<String>['sync']);
    expect(result, equals(0));
    expect(runHistory.length, greaterThanOrEqualTo(1));
    expect(runHistory[0].command, containsAllInOrder(<String>['gclient', 'sync', '-D']));
    // gclient runs from the directory of .gclient.
    expect(runHistory[0].workingDirectory, root.path);
  });

  test('fetch command fails in a checkout without .gclient', () async {
    final logs = <LogRecord>[];
    final (Environment env, List<FakeCommandLogEntry> runHistory) = linuxEnv(Logger.test(logs.add));
    final runner = ToolCommandRunner(environment: env, configs: configs);
    final int result = await runner.run(<String>['fetch']);
    expect(result, equals(1));
    expect(runHistory, isEmpty);
    expect(logs.map((LogRecord record) => record.message).join(), contains('.gclient'));
  });

  // The Bazel build fetches what it reads itself: neither gclient nor a
  // .gclient is looked for, and neither is there in these tests.
  group('with the Bazel backend, fetch looks for no gclient', () {
    Future<void> expectNothingToFetch(
      List<String> arguments, {
      Map<String, String>? environment,
    }) async {
      final logs = <LogRecord>[];
      final (Environment env, List<FakeCommandLogEntry> runHistory) = linuxEnv(
        Logger.test(logs.add),
        environment: environment,
        gclientOnPath: false,
      );
      final runner = ToolCommandRunner(environment: env, configs: configs);
      final int result = await runner.run(arguments);
      expect(result, equals(0));
      expect(runHistory, isEmpty);
      final String output = logs.map((LogRecord record) => record.message).join();
      expect(output, contains('Bazel'));
      expect(output, isNot(contains('gclient')));
    }

    test('--backend bazel', () async {
      await expectNothingToFetch(<String>['fetch', '--backend', 'bazel']);
    });

    test('the sync alias', () async {
      await expectNothingToFetch(<String>['sync', '--backend=bazel']);
    });

    test('ET_BACKEND=bazel', () async {
      await expectNothingToFetch(
        <String>['fetch'],
        environment: <String, String>{'ET_BACKEND': 'bazel'},
      );
    });
  });

  test('--backend gn fetches with gclient where ET_BACKEND says bazel', () async {
    writeDotGclient();
    final logger = Logger.test((_) {});
    final (Environment env, List<FakeCommandLogEntry> runHistory) = linuxEnv(
      logger,
      environment: <String, String>{'ET_BACKEND': 'bazel'},
    );
    final runner = ToolCommandRunner(environment: env, configs: configs);
    final int result = await runner.run(<String>['fetch', '--backend', 'gn']);
    expect(result, equals(0));
    expect(runHistory.length, greaterThanOrEqualTo(1));
    expect(runHistory[0].command, containsAllInOrder(<String>['gclient', 'sync', '-D']));
  });
}
