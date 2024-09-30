// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/build_utils.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:test/test.dart';

import 'fixtures.dart' as fixtures;
import 'utils.dart';

void main() {
  final linuxTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/linux_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Linux', Platform.linux))
        as Map<String, Object?>,
  );

  final macTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/mac_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Mac-12', Platform.macOS))
        as Map<String, Object?>,
  );

  final winTestConfig = BuilderConfig.fromJson(
    path: 'ci/builders/win_test_config.json',
    map: convert.jsonDecode(fixtures.testConfig('Windows-11', Platform.windows))
        as Map<String, Object?>,
  );

  final configs = <String, BuilderConfig>{
    'linux_test_config': linuxTestConfig,
    'mac_test_config': macTestConfig,
    'win_test_config': winTestConfig,
  };

  final cannedProcesses = [
    CannedProcess(
      (command) => command.contains('desc'),
      stdout: fixtures.gnDescOutput(),
    ),
  ];

  test('can find host runnable build', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final result = runnableBuilds(testEnv.environment, configs, true);
    expect(result.length, equals(4));
    expect(result[0].name, equals('ci/build_name'));
  });

  test('build command invokes gn', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/build_name',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory.length, greaterThanOrEqualTo(1));
    expect(testEnv.processHistory[0].command[0], contains('gn'));
  });

  test('build command invokes ninja', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/build_name',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory.length, greaterThanOrEqualTo(2));
    expect(testEnv.processHistory[1].command[0], contains('ninja'));
  });

  test('build command invokes generator', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/build_name',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory.length, greaterThanOrEqualTo(3));
    expect(
      testEnv.processHistory[2].command,
      containsAllInOrder(['python3', 'gen/script.py']),
    );
  });

  test('build command does not invoke tests', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/build_name',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory.length, lessThanOrEqualTo(4));
  });

  test('build command runs rbe on an rbe build', () async {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/android_debug_rbe_arm64',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory[0].command[0],
        contains(path.join('tools', 'gn')));
    expect(testEnv.processHistory[0].command[2], equals('--rbe'));
    expect(testEnv.processHistory[1].command[0],
        contains(path.join('reclient', 'bootstrap')));
  });

  test('build command plumbs -j to ninja', () async {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/android_debug_rbe_arm64',
      '-j',
      '500',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory[0].command[0],
        contains(path.join('tools', 'gn')));
    expect(testEnv.processHistory[0].command[2], equals('--rbe'));
    expect(testEnv.processHistory[2].command.contains('500'), isTrue);
  });

  test('build command fails when rbe is enabled but not supported', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
      // Intentionally omit withRbe: true.
      // That means the //flutter/build/rbe directory will not be created.
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/android_debug_rbe_arm64',
      '--rbe',
    ]);
    expect(result, equals(1));
    expect(
      testEnv.testLogs.map((LogRecord r) => r.message).join(),
      contains('RBE was requested but no RBE config was found'),
    );
  });

  test('build command does not run rbe when disabled', () async {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/android_debug_rbe_arm64',
      '--no-rbe',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory[0].command[0],
        contains(path.join('tools', 'gn')));
    expect(testEnv.processHistory[0].command, isNot(contains(['--rbe'])));
    expect(testEnv.processHistory[1].command[0],
        contains(path.join('ninja', 'ninja')));
  });

  test('build command does not run rbe when rbe configs do not exist',
      () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/android_debug_rbe_arm64',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory[0].command[0],
        contains(path.join('tools', 'gn')));
    expect(testEnv.processHistory[0].command, isNot(contains(['--rbe'])));
    expect(testEnv.processHistory[1].command[0],
        contains(path.join('ninja', 'ninja')));
  });

  test('mangleConfigName removes the OS and adds ci/ as needed', () {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final env = testEnv.environment;
    expect(mangleConfigName(env, 'linux/build'), equals('build'));
    expect(mangleConfigName(env, 'ci/build'), equals('ci/build'));
  });

  test('mangleConfigName throws when the input config name is malformed', () {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final env = testEnv.environment;
    expect(
      () => mangleConfigName(env, 'build'),
      throwsArgumentError,
    );
  });

  test('demangleConfigName adds the OS and removes ci/ as needed', () {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final env = testEnv.environment;
    expect(demangleConfigName(env, 'build'), equals('linux/build'));
    expect(demangleConfigName(env, 'ci/build'), equals('ci/build'));
  });

  test('local config name on the command line is correctly translated',
      () async {
    final namespaceTestConfigs = BuilderConfig.fromJson(
      path: 'ci/builders/namespace_test_config.json',
      map: convert.jsonDecode(fixtures.configsToTestNamespacing)
          as Map<String, Object?>,
    );
    final configs = <String, BuilderConfig>{
      'namespace_test_config': namespaceTestConfigs,
    };
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'host_debug',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory[1].command[0],
        contains(path.join('ninja', 'ninja')));
    expect(testEnv.processHistory[1].command[2], contains('local_host_debug'));
  });

  test('ci config name on the command line is correctly translated', () async {
    final namespaceTestConfigs = BuilderConfig.fromJson(
      path: 'ci/builders/namespace_test_config.json',
      map: convert.jsonDecode(fixtures.configsToTestNamespacing)
          as Map<String, Object?>,
    );
    final configs = <String, BuilderConfig>{
      'namespace_test_config': namespaceTestConfigs,
    };
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'ci/host_debug',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory[1].command[0],
        contains(path.join('ninja', 'ninja')));
    expect(testEnv.processHistory[1].command[2], contains('ci/host_debug'));
  });

  test('build command invokes ninja with the specified target', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'host_debug',
      '//flutter/fml:fml_arc_unittests',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory, containsCommand((command) {
      return command.length > 3 &&
          command[0].contains('ninja') &&
          command[1].contains('-C') &&
          command[2].endsWith('/host_debug') &&
          // TODO(matanlurey): Tighten this up to be more specific.
          // The reason we need a broad check is because the test fixture
          // always returns multiple targets for gn desc, even though that is
          // not the actual behavior.
          command.sublist(3).contains('flutter/fml:fml_arc_unittests');
    }));
  });

  test('build command invokes ninja with all matched targets', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'host_debug',
      '//flutter/...',
    ]);
    expect(result, equals(0));
    expect(testEnv.processHistory, containsCommand((command) {
      return command.length > 5 &&
          command[0].contains('ninja') &&
          command[1].contains('-C') &&
          command[2].endsWith('/host_debug') &&
          command[3] == 'flutter/display_list:display_list_unittests' &&
          command[4] == 'flutter/flow:flow_unittests' &&
          command[5] == 'flutter/fml:fml_arc_unittests';
    }));
  });

  test('build command gracefully handles no matched targets', () async {
    final cannedProcesses = [
      CannedProcess(
        (command) => command.contains('desc'),
        stdout: fixtures.gnDescOutputEmpty(
            gnPattern: 'testing/scenario_app:sceario_app'),
        exitCode: 1,
      ),
    ];
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
    );
    final result = await runner.run([
      'build',
      '--config',
      'host_debug',
      // Intentionally omit the prefix '//flutter/' to trigger the warning.
      '//testing/scenario_app',
    ]);
    expect(result, equals(0));
    expect(
      testEnv.testLogs.map((LogRecord r) => r.message).join(),
      contains('No targets matched the pattern `testing/scenario_app'),
    );
  });

  test('et help build line length is not too big', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
      verbose: true,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
      help: true,
    );
    final result = await runner.run([
      'help',
      'build',
    ]);
    expect(result, equals(0));

    // Avoid a degenerate case where nothing is logged.
    expect(testEnv.testLogs, isNotEmpty, reason: 'No logs were emitted');

    expect(
      testEnv.testLogs.map((LogRecord r) => r.message.split('\n')),
      everyElement(hasLength(lessThanOrEqualTo(100))),
    );
  });

  test('non-verbose "et help build" does not contain ci builds', () async {
    final testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnv.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnv.environment,
      configs: configs,
      help: true,
    );
    final result = await runner.run([
      'help',
      'build',
    ]);
    expect(result, equals(0));

    // Avoid a degenerate case where nothing is logged.
    expect(testEnv.testLogs, isNotEmpty, reason: 'No logs were emitted');

    expect(
      testEnv.testLogs.map((LogRecord r) => r.message),
      isNot(contains('[ci/')),
    );
  });
}
