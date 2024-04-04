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
import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';

import 'fixtures.dart' as fixtures;
import 'utils.dart';

void main() {
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
    'linux_test_config2': linuxTestConfig,
    'mac_test_config': macTestConfig,
    'win_test_config': winTestConfig,
  };

  final List<CannedProcess> cannedProcesses = <CannedProcess>[
    CannedProcess((List<String> command) => command.contains('desc'),
        stdout: fixtures.gnDescOutput()),
  ];

  TestEnvironment makeTestEnv({bool withRbe = false}) {
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
    final TestEnvironment testEnvironment = TestEnvironment(engine,
        abi: ffi.Abi.linuxX64, cannedProcesses: cannedProcesses);
    return testEnvironment;
  }

  void cleanupEnv(TestEnvironment testEnv) {
    try {
      testEnv.environment.engine.srcDir.parent.deleteSync(recursive: true);
    } catch (_) {
      // Ignore failure to clean up.
    }
  }

  test('can find host runnable build', () async {
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final List<Build> result = runnableBuilds(testEnv.environment, configs);
      expect(result.length, equals(8));
      expect(result[0].name, equals('ci/build_name'));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command invokes gn', () async {
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/build_name',
      ]);
      print(testEnv.processHistory);
      expect(result, equals(0));
      expect(testEnv.processHistory.length, greaterThanOrEqualTo(1));
      expect(testEnv.processHistory[0].command[0], contains('gn'));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command invokes ninja', () async {
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/build_name',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory.length, greaterThanOrEqualTo(2));
      expect(testEnv.processHistory[2].command[0], contains('ninja'));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command invokes generator', () async {
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/build_name',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory.length, greaterThanOrEqualTo(3));
      expect(
        testEnv.processHistory[3].command,
        containsStringsInOrder(<String>['python3', 'gen/script.py']),
      );
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command does not invoke tests', () async {
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/build_name',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory.length, lessThanOrEqualTo(4));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command runs rbe on an rbe build', () async {
    final TestEnvironment testEnv = makeTestEnv(withRbe: true);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/android_debug_rbe_arm64',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory[1].command[0],
          contains(path.join('tools', 'gn')));
      expect(testEnv.processHistory[1].command[4], equals('--rbe'));
      expect(testEnv.processHistory[2].command[0],
          contains(path.join('reclient', 'bootstrap')));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command does not run rbe when disabled', () async {
    final TestEnvironment testEnv = makeTestEnv(withRbe: true);
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/android_debug_rbe_arm64',
        '--no-rbe',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory[1].command[0],
          contains(path.join('tools', 'gn')));
      expect(testEnv.processHistory[1].command,
          doesNotContainAny(<String>['--rbe']));
      expect(testEnv.processHistory[2].command[0],
          contains(path.join('ninja', 'ninja')));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('build command does not run rbe when rbe configs do not exist',
      () async {
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/android_debug_rbe_arm64',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory[1].command[0],
          contains(path.join('tools', 'gn')));
      expect(testEnv.processHistory[1].command,
          doesNotContainAny(<String>['--rbe']));
      expect(testEnv.processHistory[2].command[0],
          contains(path.join('ninja', 'ninja')));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('mangleConfigName removes the OS and adds ci/ as needed', () {
    final TestEnvironment testEnv = makeTestEnv();
    final Environment env = testEnv.environment;
    expect(mangleConfigName(env, 'linux/build'), equals('build'));
    expect(mangleConfigName(env, 'ci/build'), equals('ci/build'));
  });

  test('mangleConfigName throws when the input config name is malformed', () {
    final TestEnvironment testEnv = makeTestEnv();
    final Environment env = testEnv.environment;
    expectArgumentError(() => mangleConfigName(env, 'build'));
  });

  test('demangleConfigName adds the OS and removes ci/ as needed', () {
    final TestEnvironment testEnv = makeTestEnv();
    final Environment env = testEnv.environment;
    expect(demangleConfigName(env, 'build'), equals('linux/build'));
    expect(demangleConfigName(env, 'ci/build'), equals('ci/build'));
  });

  test('local config name on the command line is correctly translated',
      () async {
    final BuilderConfig namespaceTestConfigs = BuilderConfig.fromJson(
      path: 'ci/builders/namespace_test_config.json',
      map: convert.jsonDecode(fixtures.configsToTestNamespacing)
          as Map<String, Object?>,
    );
    final Map<String, BuilderConfig> configs = <String, BuilderConfig>{
      'namespace_test_config': namespaceTestConfigs,
    };
    final TestEnvironment testEnv = makeTestEnv();
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'host_debug',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory[2].command[0],
          contains(path.join('ninja', 'ninja')));
      expect(
          testEnv.processHistory[2].command[2], contains('local_host_debug'));
    } finally {
      cleanupEnv(testEnv);
    }
  });

  test('ci config name on the command line is correctly translated', () async {
    final BuilderConfig namespaceTestConfigs = BuilderConfig.fromJson(
      path: 'ci/builders/namespace_test_config.json',
      map: convert.jsonDecode(fixtures.configsToTestNamespacing)
          as Map<String, Object?>,
    );
    final Map<String, BuilderConfig> configs = <String, BuilderConfig>{
      'namespace_test_config': namespaceTestConfigs,
    };
    final TestEnvironment testEnv = makeTestEnv();
    final Environment env = testEnv.environment;
    try {
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'build',
        '--config',
        'ci/host_debug',
      ]);
      expect(result, equals(0));
      expect(testEnv.processHistory[2].command[0],
          contains(path.join('ninja', 'ninja')));
      expect(testEnv.processHistory[2].command[2], contains('ci/host_debug'));
    } finally {
      cleanupEnv(testEnv);
    }
  });
}
