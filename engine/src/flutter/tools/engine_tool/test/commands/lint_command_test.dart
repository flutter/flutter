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

import '../src/test_build_configs.dart';
import '../src/utils.dart';

void main() {
  final engine = Engine.findWithin();

  (Environment, List<List<String>>) macEnv(Logger logger) {
    final runHistory = <List<String>>[];
    return (
      Environment(
        abi: ffi.Abi.macosArm64,
        engine: engine,
        platform: FakePlatform(
          operatingSystem: Platform.macOS,
          resolvedExecutable: io.Platform.resolvedExecutable,
          pathSeparator: '/',
        ),
        processRunner: ProcessRunner(
          processManager: FakeProcessManager(
            onStart: (FakeCommandLogEntry entry) {
              runHistory.add(entry.command);
              return FakeProcess();
            },
            onRun: (_) {
              // Should not be executed.
              assert(false);
              return io.ProcessResult(81, 1, '', '');
            },
          ),
        ),
        logger: logger,
      ),
      runHistory,
    );
  }

  test('invoked linters', () async {
    final logger = Logger.test((_) {});
    final (Environment env, List<List<String>> runHistory) = macEnv(logger);
    final runner = ToolCommandRunner(environment: env, configs: {});
    final int result = await runner.run(<String>['lint']);
    expect(result, equals(0));
    expect(runHistory.length, greaterThanOrEqualTo(4));
    expect(runHistory[0].firstOrNull, contains('analyze.sh'));
  });

  test("--backend bazel writes the build's compile_commands.json and lints against it", () async {
    // A Linux host build of a builder file: the kind the converter gives a
    // Bazel configuration (tools/gn_to_bazel/lib/src/builders.dart).
    final builder = TestBuilderConfig();
    builder.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
      enableLto: false,
      targetDir: 'host_debug',
    );
    final Map<String, Object?> json = builder.buildJson();
    final build = (json['builds']! as List<Object?>).single! as Map<String, Object?>;
    (build['ninja']! as Map<String, Object?>)['targets'] = <String>[];
    final configs = {
      'local_engine': BuilderConfig.fromJson(map: json, path: 'ci/builders/local_engine.json'),
    };

    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: [
        CannedProcess(
          (command) => command.any((String arg) => arg.endsWith('compile_commands.py')),
          stdout: '4,281 compile commands into out/host_debug/compile_commands.json\n',
        ),
      ],
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(environment: testEnv.environment, configs: configs);
    final int result = await runner.run(<String>[
      'lint',
      '--config',
      'host_debug',
      '--backend',
      'bazel',
    ]);

    printOnFailure(testEnv.testLogs.map((r) => r.message).join('\n'));
    expect(result, equals(0));
    final List<List<String>> commands = testEnv.processHistory
        .map((ExecutedProcess p) => p.command)
        .toList();
    // The compile database first, from the tool, for the build's directory.
    final List<String> tool = commands.firstWhere(
      (List<String> c) => c.any((String arg) => arg.endsWith('compile_commands.py')),
    );
    expect(tool.first, 'python3');
    expect(tool[1], endsWith('tools/gn_to_bazel/tool/compile_commands.py'));
    expect(tool.sublist(2), <String>[
      '--out=${path.join(testEnv.environment.engine.outDir.path, 'host_debug')}',
      '--config=host_debug',
      '--bazel=bazelisk',
    ]);
    // The C linter reads it.
    final List<String> clangTidy = commands.firstWhere(
      (List<String> c) => c.first.endsWith('clang_tidy.sh'),
    );
    expect(clangTidy.sublist(1), <String>['--variant', 'host_debug']);
    // The others are unchanged.
    expect(commands.where((List<String> c) => c.first.endsWith('analyze.sh')), hasLength(1));
    expect(commands.where((List<String> c) => c.first.endsWith('pylint.sh')), hasLength(1));
  });

  test('--backend bazel refuses a build the Bazel build has no configuration for', () async {
    // A GN argument the Bazel build has no flag for (tools/gn's --gn-args:
    // builders.dart's gnArguments names the few the builder files pass).
    final builder = TestBuilderConfig();
    builder.addBuild(
      name: 'ci/host_debug_experimental',
      dimension: TestDroneDimension.linux,
      enableLto: false,
      targetDir: 'ci/host_debug_experimental',
    );
    final Map<String, Object?> json = builder.buildJson();
    final build = (json['builds']! as List<Object?>).single! as Map<String, Object?>;
    (build['gn']! as List<Object?>).add('--gn-args=dart_use_tcmalloc=true');
    final configs = {
      'linux_unopt': BuilderConfig.fromJson(map: json, path: 'ci/builders/linux_unopt.json'),
    };

    final testEnv = TestEnvironment.withTestEngine(verbose: true);
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(environment: testEnv.environment, configs: configs);
    final int result = await runner.run(<String>[
      'lint',
      '--config',
      'ci/host_debug_experimental',
      '--backend',
      'bazel',
    ]);

    printOnFailure(testEnv.testLogs.map((r) => r.message).join('\n'));
    expect(result, equals(1));
    expect(testEnv.processHistory, isEmpty);
    expect(
      testEnv.testLogs.map((r) => r.message).join(),
      contains('cannot express ci/host_debug_experimental'),
    );
  });
}
