// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

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
    'mac_test_config': macTestConfig,
    'win_test_config': winTestConfig,
  };

  test('test command executes test', () async {
    final TestEnvironment testEnvironment = TestEnvironment.withTestEngine(
      // This test needs specific instrumentation. Ideally all tests should
      // use per-test environments and not rely on global state, but that is a
      // larger change (https://github.com/flutter/flutter/issues/148420).
      cannedProcesses: <CannedProcess>[
        CannedProcess(
          (List<String> command) => command.contains('desc'),
          stdout: '''
            {
              "//flutter/fml:display_list_unittests": {
                "outputs": ["//out/host_debug/flutter/fml:display_list_unittests"],
                "testonly": true,
                "type": "executable"
              }
            }
          ''',
        ),
      ],
    );
    try {
      final Environment env = testEnvironment.environment;
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'test',
        '//flutter/display_list:display_list_unittests',
      ]);
      expect(result, equals(0));
      expect(testEnvironment.processHistory.length, greaterThan(3));
      final int offset = testEnvironment.processHistory.length - 1;
      expect(testEnvironment.processHistory[offset].command[0],
          endsWith('display_list_unittests'));
    } finally {
      testEnvironment.cleanup();
    }
  });

  test('test command skips non-testonly executables', () async {
    final TestEnvironment testEnvironment = TestEnvironment.withTestEngine(
      // This test needs specific instrumentation. Ideally all tests should
      // use per-test environments and not rely on global state, but that is a
      // larger change (https://github.com/flutter/flutter/issues/148420).
      cannedProcesses: <CannedProcess>[
        CannedProcess(
          (List<String> command) => command.contains('desc'),
          stdout: '''
            {
              "//flutter/fml:display_list_unittests": {
                "outputs": ["//out/host_debug/flutter/fml:display_list_unittests"],
                "testonly": true,
                "type": "executable"
              },
              "//third_party/protobuf:protoc": {
                "outputs": ["//out/host_debug/third_party/protobuf:protoc"],
                "testonly": false,
                "type": "executable"
              }
            }
          ''',
        ),
      ],
    );
    try {
      final Environment env = testEnvironment.environment;
      final ToolCommandRunner runner = ToolCommandRunner(
        environment: env,
        configs: configs,
      );
      final int result = await runner.run(<String>[
        'test',
        '//...',
      ]);
      expect(result, equals(0));
      expect(testEnvironment.processHistory.where((ExecutedProcess process) {
        return process.command[0].contains('protoc');
      }), isEmpty);
    } finally {
      testEnvironment.cleanup();
    }
  });
}
