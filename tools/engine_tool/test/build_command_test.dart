// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:ffi' as ffi show Abi;
import 'dart:io' as io;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:engine_tool/src/build_utils.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';

import 'fixtures.dart' as fixtures;

void main() {
  final BuilderConfig linuxTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/linux_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Linux'))
        as Map<String, Object?>,
  );

  final BuilderConfig macTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/mac_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Mac-12'))
        as Map<String, Object?>,
  );

  final BuilderConfig winTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/win_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Windows-11'))
        as Map<String, Object?>,
  );

  final Map<String, BuilderConfig> configs = <String, BuilderConfig>{
    'linux_test_config': linuxTestConfig,
    'linux_test_config2': linuxTestConfig,
    'mac_test_config': macTestConfig,
    'win_test_config': winTestConfig,
  };

  (Environment, List<List<String>>) linuxEnv(
    Logger logger, {
    bool withRbe = false,
  }) {
    final io.Directory rootDir = io.Directory.systemTemp.createTempSync('et');
    final TestEngine engine = TestEngine.createTemp(rootDir: rootDir);
    if (withRbe) {
      io.Directory(path.join(
        engine.srcDir.path,
        'flutter',
        'build',
        'rbe',
      )).createSync(recursive: true);
    }
    final List<List<String>> runHistory = <List<String>>[];
    return (
      Environment(
        abi: ffi.Abi.linuxX64,
        engine: engine,
        platform: FakePlatform(
            operatingSystem: Platform.linux,
            resolvedExecutable: io.Platform.resolvedExecutable),
        processRunner: ProcessRunner(
          processManager: FakeProcessManager(
            canRun: (Object? exe, {String? workingDirectory}) => true,
            onStart: (List<String> command) {
              runHistory.add(command);
              return FakeProcess();
            },
            onRun: (List<String> command) {
              runHistory.add(command);
              return io.ProcessResult(81, 0, '', '');
            },
          ),
        ),
        logger: logger,
      ),
      runHistory
    );
  }

  void cleanupEnv(Environment env) {
    try {
      env.engine.srcDir.parent.deleteSync(recursive: true);
    } catch (_) {
      // Ignore failure to clean up.
    }
  }

  test('can find host runnable build', () async {
    final Logger logger = Logger.test();
    final (Environment env, _) = linuxEnv(logger);
    try {
      final List<Build> result = runnableBuilds(env, configs);
      expect(result.length, equals(8));
      expect(result[0].name, equals('build_name'));
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command invokes gn', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'build_name',
      ]);
      expect(result, equals(0));
      expect(runHistory.length, greaterThanOrEqualTo(1));
      expect(runHistory[0].length, greaterThanOrEqualTo(1));
      expect(runHistory[0][0], contains('gn'));
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command invokes ninja', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'build_name',
      ]);
      expect(result, equals(0));
      expect(runHistory.length, greaterThanOrEqualTo(2));
      expect(runHistory[1].length, greaterThanOrEqualTo(1));
      expect(runHistory[1][0], contains('ninja'));
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command invokes generator', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'build_name',
      ]);
      expect(result, equals(0));
      expect(runHistory.length, greaterThanOrEqualTo(3));
      expect(
        runHistory[2],
        containsStringsInOrder(<String>['python3', 'gen/script.py']),
      );
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command does not invoke tests', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'build_name',
      ]);
      expect(result, equals(0));
      expect(runHistory.length, lessThanOrEqualTo(3));
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command runs rbe on an rbe build', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(
      logger, withRbe: true,
    );
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'android_debug_rbe_arm64',
      ]);
      expect(result, equals(0));
      expect(runHistory[0][0], contains(path.join('tools', 'gn')));
      expect(runHistory[0][4], equals('--rbe'));
      expect(runHistory[1][0], contains(path.join('reclient', 'bootstrap')));
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command does not run rbe when disabled', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(
      logger, withRbe: true,
    );
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'android_debug_rbe_arm64',
        '--no-rbe',
      ]);
      expect(result, equals(0));
      expect(runHistory[0][0], contains(path.join('tools', 'gn')));
      expect(runHistory[0], doesNotContainAny(<String>['--rbe']));
      expect(runHistory[1][0], contains(path.join('ninja', 'ninja')));
    } finally {
      cleanupEnv(env);
    }
  });

  test('build command does not run rbe when rbe configs do not exist', () async {
    final Logger logger = Logger.test();
    final (Environment env, List<List<String>> runHistory) = linuxEnv(logger);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'android_debug_rbe_arm64',
      ]);
      expect(result, equals(0));
      expect(runHistory[0][0], contains(path.join('tools', 'gn')));
      expect(runHistory[0], doesNotContainAny(<String>['--rbe']));
      expect(runHistory[1][0], contains(path.join('ninja', 'ninja')));
    } finally {
      cleanupEnv(env);
    }
  });
}
