// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
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

  test('test command executes test', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
      // This test needs specific instrumentation. Ideally all tests should
      // use per-test environments and not rely on global state, but that is a
      // larger change (https://github.com/flutter/flutter/issues/148420).
      cannedProcesses: [
        CannedProcess(
          (command) => command.contains('desc'),
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
    addTearDown(testEnvironment.cleanup);

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: configs,
    );
    final result = await runner.run(<String>[
      'test',
      '//flutter/display_list:display_list_unittests',
    ]);
    expect(result, equals(0));
    expect(testEnvironment.processHistory.length, greaterThan(3));
    final offset = testEnvironment.processHistory.length - 1;
    expect(
      testEnvironment.processHistory[offset].command[0],
      endsWith('display_list_unittests'),
    );
  });

  test('test command skips non-testonly executables', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
      // This test needs specific instrumentation. Ideally all tests should
      // use per-test environments and not rely on global state, but that is a
      // larger change (https://github.com/flutter/flutter/issues/148420).
      cannedProcesses: [
        CannedProcess(
          (command) => command.contains('desc'),
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
    addTearDown(testEnvironment.cleanup);

    final env = testEnvironment.environment;
    final runner = ToolCommandRunner(
      environment: env,
      configs: configs,
    );
    final result = await runner.run(<String>[
      'test',
      '//...',
    ]);
    expect(result, equals(0));
    expect(testEnvironment.processHistory.where((ExecutedProcess process) {
      return process.command[0].contains('protoc');
    }), isEmpty);
  });
}
