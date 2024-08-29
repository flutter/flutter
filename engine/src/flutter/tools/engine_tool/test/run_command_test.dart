// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:ffi' as ffi show Abi;
import 'dart:io' as io;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:engine_tool/src/label.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:engine_tool/src/run_utils.dart';
import 'package:platform/platform.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

import 'fixtures.dart' as fixtures;

void main() {
  final Engine engine;
  try {
    engine = Engine.findWithin();
  } catch (e) {
    io.stderr.writeln(e);
    io.exitCode = 1;
    return;
  }

  final BuilderConfig linuxTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/linux_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Linux', Platform.linux))
        as Map<String, Object?>,
  );

  final BuilderConfig macTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/mac_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Mac-12', Platform.macOS))
        as Map<String, Object?>,
  );

  final BuilderConfig winTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/win_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Windows-11', Platform.windows))
        as Map<String, Object?>,
  );

  final Map<String, BuilderConfig> configs = <String, BuilderConfig>{
    'linux_test_config': linuxTestConfig,
    'mac_test_config': macTestConfig,
    'win_test_config': winTestConfig,
  };

  (Environment, List<List<String>>) linuxEnv(Logger logger) {
    final List<List<String>> runHistory = <List<String>>[];
    return (
      Environment(
        abi: ffi.Abi.linuxX64,
        engine: engine,
        platform: FakePlatform(
          operatingSystem: Platform.linux,
          resolvedExecutable: io.Platform.resolvedExecutable,
          pathSeparator: '/',
          numberOfProcessors: 32,
        ),
        processRunner: ProcessRunner(
          processManager: FakeProcessManager(onStart: (List<String> command) {
            runHistory.add(command);
            switch (command) {
              case ['flutter', 'devices', '--machine']:
                return FakeProcess(stdout: fixtures.attachedDevices());
              default:
                return FakeProcess();
            }
          }, onRun: (List<String> command) {
            // Should not be executed.
            assert(false);
            return io.ProcessResult(81, 1, '', '');
          }),
        ),
        logger: logger,
      ),
      runHistory
    );
  }

  test('run command invokes flutter run', () async {
    final Logger logger = Logger.test((_) {});
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    final ToolCommandRunner runner = ToolCommandRunner(
      environment: env,
      configs: configs,
    );
    final int result =
        await runner.run(<String>['run', '--', '--weird_argument']);
    expect(result, equals(0));
    expect(runHistory.length, greaterThanOrEqualTo(6));
    expect(runHistory[5],
        containsAllInOrder(<String>['flutter', 'run', '--weird_argument']));
  });

  test('parse devices list', () async {
    final Logger logger = Logger.test((_) {});
    final (Environment env, _) = linuxEnv(logger);
    final List<RunTarget> targets =
        parseDevices(env, fixtures.attachedDevices());
    expect(targets.length, equals(4));
    final RunTarget android = targets[0];
    expect(android.name, contains('gphone64'));
    expect(android.buildConfigFor('debug'), equals('android_debug_arm64'));
  });

  test('target specific shell build', () async {
    final Logger logger = Logger.test((_) {});
    final (Environment env, _) = linuxEnv(logger);
    final List<RunTarget> targets =
        parseDevices(env, fixtures.attachedDevices());
    final RunTarget android = targets[0];
    expect(android.name, contains('gphone64'));
    final List<Label> shellLabels = <Label>[
      Label.parseGn('//flutter/shell/platform/android:android_jar')
    ];
    expect(android.buildTargetsForShell(), equals(shellLabels));
  });

  test('default device', () async {
    final Logger logger = Logger.test((_) {});
    final (Environment env, _) = linuxEnv(logger);
    final List<RunTarget> targets =
        parseDevices(env, fixtures.attachedDevices());
    expect(targets.length, equals(4));
    final RunTarget? defaultTarget = defaultDevice(env, targets);
    expect(defaultTarget, isNotNull);
    expect(defaultTarget!.name, contains('gphone64'));
    expect(
        defaultTarget.buildConfigFor('debug'), equals('android_debug_arm64'));
  });

  test('device select', () async {
    final Logger logger = Logger.test((_) {});
    final (Environment env, _) = linuxEnv(logger);
    RunTarget target = selectRunTarget(env, fixtures.attachedDevices())!;
    expect(target.name, contains('gphone64'));
    target = selectRunTarget(env, fixtures.attachedDevices(), 'mac')!;
    expect(target.name, contains('macOS'));
  });

  test('flutter run device select', () async {
    final Logger logger = Logger.test((_) {});
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    final ToolCommandRunner runner = ToolCommandRunner(
      environment: env,
      configs: configs,
    );
    // Request that the emulator device is used. The emulator is an Android
    // ARM64 device.
    final int result =
        await runner.run(<String>['run', '--', '-d', 'emulator']);
    expect(result, equals(0));
    expect(runHistory.length, greaterThanOrEqualTo(6));
    // Observe that we selected android_debug_arm64 as the target.
    expect(
        runHistory[5],
        containsAllInOrder(<String>[
          'flutter',
          'run',
          '--local-engine',
          'android_debug_arm64',
          '--local-engine-host',
          'host_debug',
          '-d',
          'emulator'
        ]));
  });
}
