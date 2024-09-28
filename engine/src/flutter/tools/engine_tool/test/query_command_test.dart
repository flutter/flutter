// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:logging/logging.dart' as log;
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

  final linuxTestConfig2 = BuilderConfig.fromJson(
    path: 'ci/builders/linux_test_config2.json',
    map: convert.jsonDecode(
            fixtures.testConfig('Linux', Platform.linux, suffix: '2'))
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
    'linux_test_config2': linuxTestConfig2,
    'mac_test_config': macTestConfig,
    'win_test_config': winTestConfig,
  };

  List<String> stringsFromLogs(List<log.LogRecord> logs) {
    return logs.map((log.LogRecord r) => r.message).toList();
  }

  final cannedProcesses = <CannedProcess>[
    CannedProcess(
      (command) => command.contains('desc'),
      stdout: fixtures.gnDescOutput(),
    ),
  ];

  test('query command returns builds for the host platform.', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnvironment.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: configs,
    );
    final result = await runner.run(<String>[
      'query',
      'builders',
    ]);
    expect(result, equals(0));
    expect(
      stringsFromLogs(testEnvironment.testLogs),
      equals(<String>[
        'Add --verbose to see detailed information about each builder\n',
        '\n',
        '"linux_test_config" builder:\n',
        '   "ci/build_name" config\n',
        '   "linux/host_debug" config\n',
        '   "linux/android_debug_arm64" config\n',
        '   "ci/android_debug_rbe_arm64" config\n',
        '"linux_test_config2" builder:\n',
        '   "ci/build_name2" config\n',
        '   "linux/host_debug2" config\n',
        '   "linux/android_debug2_arm64" config\n',
        '   "ci/android_debug2_rbe_arm64" config\n',
      ]),
    );
  });

  test('query command with --builder returns only from the named builder.',
      () async {
    final testEnvironment = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnvironment.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: configs,
    );
    final result = await runner.run(<String>[
      'query',
      'builders',
      '--builder',
      'linux_test_config',
    ]);
    expect(result, equals(0));
    expect(
        stringsFromLogs(testEnvironment.testLogs),
        equals(<String>[
          'Add --verbose to see detailed information about each builder\n',
          '\n',
          '"linux_test_config" builder:\n',
          '   "ci/build_name" config\n',
          '   "linux/host_debug" config\n',
          '   "linux/android_debug_arm64" config\n',
          '   "ci/android_debug_rbe_arm64" config\n',
        ]));
  });

  test('query command with --all returns all builds.', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnvironment.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: configs,
    );
    final result = await runner.run(<String>[
      'query',
      'builders',
      '--all',
    ]);
    expect(result, equals(0));
    expect(
      testEnvironment.testLogs.length,
      equals(30),
    );
  });

  test('query targets', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    addTearDown(testEnvironment.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: configs,
    );
    final result = await runner.run(<String>[
      'query',
      'targets',
    ]);
    expect(result, equals(0));

    final expected = <String>[
      '//flutter/display_list:display_list_unittests',
      '//flutter/flow:flow_unittest',
      '//flutter/fml:fml_arc_unittests',
    ];

    final testLogs = stringsFromLogs(testEnvironment.testLogs);
    for (final testLog in testLogs) {
      // Expect one of the expected targets to be in the output.
      // Then remove it from the list of expected targets.
      for (final target in expected) {
        if (testLog.contains(target)) {
          expected.remove(target);
          break;
        }
      }
    }

    expect(
      expected.isEmpty,
      isTrue,
      reason: 'All expected targets were found',
    );
  });
}
