// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:ffi' as ffi;
import 'dart:io' as io;

import 'package:engine_build_configs/src/build_config.dart';
import 'package:engine_build_configs/src/build_config_runner.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:litetest/litetest.dart';
import 'package:platform/platform.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';

import 'fixtures.dart' as fixtures;

void main() {
  // Find the engine repo.
  final Engine engine;
  try {
    engine = Engine.findWithin();
  } catch (e) {
    io.stderr.writeln(e);
    io.exitCode = 1;
    return;
  }

  final BuilderConfig buildConfig = BuilderConfig.fromJson(
    path: 'linux_test_config',
    map: convert.jsonDecode(fixtures.buildConfigJson) as Map<String, Object?>,
  );

  test('BuildTaskRunner runs the right commands', () async {
    final BuildTask generator = buildConfig.builds[0].generators[0];
    final BuildTaskRunner taskRunner = BuildTaskRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      task: generator,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await taskRunner.run(handler);

    expect(runResult, isTrue);
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('generator_task'));
    expect(events[0].command[0], contains('python3'));
    expect(events[0].command[1], contains('gen/script.py'));
    expect(events[0].command[2], contains('--gen-param'));
    expect(events[1] is RunnerResult, isTrue);
    expect(events[1].name, equals('generator_task'));
  });

  test('BuildTestRunner runs the right commands', () async {
    final BuildTest test = buildConfig.builds[0].tests[0];
    final BuildTestRunner testRunner = BuildTestRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      test: test,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await testRunner.run(handler);

    expect(runResult, isTrue);

    // Check that the events for the tests are correct.
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('build_name tests'));
    expect(events[0].command[0], contains('python3'));
    expect(events[0].command[1], contains('test/script.py'));
    expect(events[0].command[2], contains('--test-params'));
    expect(events[1] is RunnerResult, isTrue);
    expect(events[1].name, equals('build_name tests'));
  });

  test('GlobalBuildRunner runs the right commands', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the GN command are correct.
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('$buildName: GN'));
    expect(events[0].command[0], contains('flutter/tools/gn'));
    for (final String gnArg in targetBuild.gn) {
      expect(events[0].command.contains(gnArg), isTrue);
    }
    expect(events[1] is RunnerResult, isTrue);
    expect(events[1].name, equals('$buildName: GN'));

    // Check that the events for the Ninja command are correct.
    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: ninja'));
    expect(events[2].command[0], contains('ninja'));
    final String configPath =
        '${engine.srcDir.path}/out/${targetBuild.ninja.config}';
    expect(events[2].command.contains(configPath), isTrue);
    for (final String target in targetBuild.ninja.targets) {
      expect(events[2].command.contains(target), isTrue);
    }
    expect(events[3] is RunnerResult, isTrue);
    expect(events[3].name, equals('$buildName: ninja'));

    // Check that the events for generators are correct.
    expect(events[4] is RunnerStart, isTrue);
    expect(events[4].name, equals('generator_task'));
    expect(events[4].command[0], contains('python3'));
    expect(events[4].command[1], contains('gen/script.py'));
    expect(events[4].command[2], contains('--gen-param'));
    expect(events[5] is RunnerResult, isTrue);
    expect(events[5].name, equals('generator_task'));

    // Check that the events for the tests are correct.
    expect(events[6] is RunnerStart, isTrue);
    expect(events[6].name, equals('$buildName tests'));
    expect(events[6].command[0], contains('python3'));
    expect(events[6].command[1], contains('test/script.py'));
    expect(events[6].command[2], contains('--test-params'));
    expect(events[7] is RunnerResult, isTrue);
    expect(events[7].name, equals('$buildName tests'));
  });

  test('GlobalBuildRunner extra args are propagated correctly', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--extra-gn-arg'],
      extraNinjaArgs: <String>['--extra-ninja-arg'],
      extraTestArgs: <String>['--extra-test-arg'],
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the GN command are correct.
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('$buildName: GN'));
    expect(events[0].command.contains('--extra-gn-arg'), isTrue);

    // Check that the events for the Ninja command are correct.
    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: ninja'));
    expect(events[2].command.contains('--extra-ninja-arg'), isTrue);

    // Check that the events for the tests are correct.
    expect(events[6] is RunnerStart, isTrue);
    expect(events[6].name, equals('$buildName tests'));
    expect(events[6].command.contains('--extra-test-arg'), isTrue);
  });

  test('GlobalBuildRunner passes large -j for a goma build', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--goma'],
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the Ninja command are correct.
    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: ninja'));
    expect(events[2].command.contains('-j'), isTrue);
    expect(events[2].command.contains('200'), isTrue);
  });

  test('GlobalBuildRunner passes large -j for an rbe build', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--rbe'],
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the RBE bootstrap command are correct.
    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: RBE startup'));
    expect(events[3] is RunnerResult, isTrue);
    expect(events[3].name, equals('$buildName: RBE startup'));

    // Check that the events for the Ninja command are correct.
    expect(events[4] is RunnerStart, isTrue);
    expect(events[4].name, equals('$buildName: ninja'));
    expect(events[4].command.contains('-j'), isTrue);
    expect(events[4].command.contains('200'), isTrue);
    expect(events[5] is RunnerResult, isTrue);
    expect(events[5].name, equals('$buildName: ninja'));

    expect(events[6] is RunnerStart, isTrue);
    expect(events[6].name, equals('$buildName: RBE shutdown'));
    expect(events[7] is RunnerResult, isTrue);
    expect(events[7].name, equals('$buildName: RBE shutdown'));
  });

  test('GlobalBuildRunner skips GN when runGn is false', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      runGn: false,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the Ninja command are correct.
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('$buildName: ninja'));
    expect(events[0].command[0], contains('ninja'));
    final String configPath =
        '${engine.srcDir.path}/out/${targetBuild.ninja.config}';
    expect(events[0].command.contains(configPath), isTrue);
    for (final String target in targetBuild.ninja.targets) {
      expect(events[0].command.contains(target), isTrue);
    }
    expect(events[1] is RunnerResult, isTrue);
    expect(events[1].name, equals('$buildName: ninja'));
  });

  test('GlobalBuildRunner skips Ninja when runNinja is false', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      runNinja: false,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the GN command are correct.
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('$buildName: GN'));
    expect(events[0].command[0], contains('flutter/tools/gn'));
    for (final String gnArg in targetBuild.gn) {
      expect(events[0].command.contains(gnArg), isTrue);
    }
    expect(events[1] is RunnerResult, isTrue);
    expect(events[1].name, equals('$buildName: GN'));

    // Check that the events for generators are correct.
    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('generator_task'));
    expect(events[2].command[0], contains('python3'));
    expect(events[2].command[1], contains('gen/script.py'));
    expect(events[2].command[2], contains('--gen-param'));
    expect(events[3] is RunnerResult, isTrue);
    expect(events[3].name, equals('generator_task'));
  });

  test('GlobalBuildRunner skips generators when runGenerators is false',
      () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      runGenerators: false,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the Ninja command are correct.
    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: ninja'));
    expect(events[2].command[0], contains('ninja'));
    final String configPath =
        '${engine.srcDir.path}/out/${targetBuild.ninja.config}';
    expect(events[2].command.contains(configPath), isTrue);
    for (final String target in targetBuild.ninja.targets) {
      expect(events[2].command.contains(target), isTrue);
    }
    expect(events[3] is RunnerResult, isTrue);
    expect(events[3].name, equals('$buildName: ninja'));

    // Check that the events for the tests are correct.
    expect(events[4] is RunnerStart, isTrue);
    expect(events[4].name, equals('$buildName tests'));
    expect(events[4].command[0], contains('python3'));
    expect(events[4].command[1], contains('test/script.py'));
    expect(events[4].command[2], contains('--test-params'));
    expect(events[5] is RunnerResult, isTrue);
    expect(events[5].name, equals('$buildName tests'));
  });

  test('GlobalBuildRunner skips tests when runTests is false', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      runTests: false,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    expect(runResult, isTrue);

    // Check that the events for generators are correct.
    expect(events[4] is RunnerStart, isTrue);
    expect(events[4].name, equals('generator_task'));
    expect(events[4].command[0], contains('python3'));
    expect(events[4].command[1], contains('gen/script.py'));
    expect(events[4].command[2], contains('--gen-param'));
    expect(events[5] is RunnerResult, isTrue);
    expect(events[5].name, equals('generator_task'));

    expect(events.length, equals(6));
  });

  test('GlobalBuildRunner extraGnArgs overrides build config args', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--no-lto', '--no-goma', '--rbe'],
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isTrue);

    // Check that the events for the GN command are correct.
    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('$buildName: GN'));
    expect(events[0].command[0], contains('flutter/tools/gn'));
    expect(events[0].command.contains('--no-lto'), isTrue);
    expect(events[0].command.contains('--no-goma'), isTrue);
    expect(events[0].command.contains('--rbe'), isTrue);
    expect(events[0].command.contains('--lto'), isFalse);
    expect(events[0].command.contains('--goma'), isFalse);
    expect(events[0].command.contains('--no-rbe'), isFalse);
    expect(events[1] is RunnerResult, isTrue);
    expect(events[1].name, equals('$buildName: GN'));
  });

  test('GlobalBuildRunner canRun returns false on OS mismatch', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.macOS),
      processRunner: ProcessRunner(
        // dryRun should not try to spawn any processes.
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      dryRun: true,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    expect(runResult, isFalse);
    expect(events[0] is RunnerError, isTrue);
  });

  test('GlobalBuildRunner fails when gn fails', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(
          gnResult: io.ProcessResult(1, 1, '', ''),
        ),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isFalse);

    expect(events[0] is RunnerStart, isTrue);
    expect(events[0].name, equals('$buildName: GN'));
    expect(events[1] is RunnerResult, isTrue);
    expect((events[1] as RunnerResult).ok, isFalse);
  });

  test('GlobalBuildRunner fails when ninja fails', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(
          ninjaResult: io.ProcessResult(1, 1, '', ''),
        ),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isFalse);

    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: ninja'));
    expect(events[3] is RunnerResult, isTrue);
    expect((events[3] as RunnerResult).ok, isFalse);
  });

  test('GlobalBuildRunner fails an RBE build when bootstrap fails', () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(
          bootstrapResult: io.ProcessResult(1, 1, '', ''),
        ),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--rbe'],
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    final String buildName = targetBuild.name;

    expect(runResult, isFalse);

    expect(events[2] is RunnerStart, isTrue);
    expect(events[2].name, equals('$buildName: RBE startup'));
    expect(events[3] is RunnerResult, isTrue);
    expect(events[3].name, equals('$buildName: RBE startup'));
    expect((events[3] as RunnerResult).ok, isFalse);
  });

  test('GlobalBuildRunner fails an RBE build when bootstrap does not exist',
      () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(
          canRun: (Object? exe, {String? workingDirectory}) {
            if (exe is String? && exe != null && exe.endsWith('bootstrap')) {
              return false;
            }
            return true;
          },
        ),
      ),
      abi: ffi.Abi.linuxX64,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--rbe'],
    );
    final List<RunnerEvent> events = <RunnerEvent>[];
    void handler(RunnerEvent event) => events.add(event);
    final bool runResult = await buildRunner.run(handler);

    expect(runResult, isFalse);

    expect(events[2] is RunnerError, isTrue);
  });

  test('GlobalBuildRunner throws a StateError on an unsupported host cpu',
      () async {
    final Build targetBuild = buildConfig.builds[0];
    final BuildRunner buildRunner = BuildRunner(
      platform: FakePlatform(operatingSystem: Platform.linux),
      processRunner: ProcessRunner(
        processManager: _fakeProcessManager(),
      ),
      abi: ffi.Abi.linuxRiscv32,
      engineSrcDir: engine.srcDir,
      build: targetBuild,
      extraGnArgs: <String>['--rbe'],
    );

    bool caughtError = false;
    try {
      await buildRunner.run((RunnerEvent event) {});
    } on StateError catch (_) {
      caughtError = true;
    }
    expect(caughtError, isTrue);
  });
}

FakeProcessManager _fakeProcessManager({
  io.ProcessResult? bootstrapResult,
  io.ProcessResult? gnResult,
  io.ProcessResult? ninjaResult,
  bool Function(Object?, {String? workingDirectory})? canRun,
  bool failUnknown = true,
}) {
  final io.ProcessResult success = io.ProcessResult(1, 0, '', '');
  FakeProcess fakeProcess(io.ProcessResult? result) => FakeProcess(
        exitCode: result?.exitCode ?? 0,
        stdout: result?.stdout as String? ?? '',
        stderr: result?.stderr as String? ?? '',
      );
  return FakeProcessManager(
    canRun: canRun ?? (Object? exe, {String? workingDirectory}) => true,
    onRun: (List<String> cmd) => switch (cmd) {
      _ => failUnknown ? io.ProcessResult(1, 1, '', '') : success,
    },
    onStart: (List<String> cmd) => switch (cmd) {
      [final String exe, ...] when exe.endsWith('gn') => fakeProcess(gnResult),
      [final String exe, ...] when exe.endsWith('bootstrap') =>
        fakeProcess(bootstrapResult),
      [final String exe, ...] when exe.endsWith('ninja') =>
        fakeProcess(ninjaResult),
      _ => failUnknown ? FakeProcess(exitCode: 1) : FakeProcess(),
    },
  );
}
