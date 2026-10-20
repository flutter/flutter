// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/commands/command_runner.dart';
import 'package:test/test.dart';

import '../src/test_build_configs.dart';
import '../src/utils.dart';

void main() {
  test('test implicitly picks a configuration and executes tests', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
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

    final builders = TestBuilderConfig();
    builders.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
      targetDir: 'host_debug',
    );

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: {
        'linux_test_config': builders.buildConfig(path: 'ci/builders/linux_test_config.json'),
      },
    );
    final int result = await runner.run(['test', '//flutter/display_list:display_list_unittests']);

    printOnFailure(testEnvironment.testLogs.map((t) => t.message).join('\n'));
    expect(result, equals(0));

    expect(
      testEnvironment.processHistory,
      contains(
        isA<ExecutedProcess>().having(
          (e) => e.command,
          'command',
          contains(endsWith('display_list_unittests')),
        ),
      ),
    );
  });

  test('test command skips non-testonly executables', () async {
    final testEnvironment = TestEnvironment.withTestEngine(
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

    final builders = TestBuilderConfig();
    builders.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
      targetDir: 'host_debug',
    );

    final runner = ToolCommandRunner(
      environment: testEnvironment.environment,
      configs: {
        'linux_test_config': builders.buildConfig(path: 'ci/builders/linux_test_config.json'),
      },
    );
    final int result = await runner.run(<String>['test', '//...']);

    printOnFailure(testEnvironment.testLogs.map((t) => t.message).join('\n'));
    expect(result, equals(0));

    expect(
      testEnvironment.processHistory,
      contains(
        isA<ExecutedProcess>().having(
          (e) => e.command,
          'command',
          contains(endsWith('display_list_unittests')),
        ),
      ),
      reason: 'display_list_unittests is marked as testonly',
    );

    expect(
      testEnvironment.processHistory,
      isNot(
        contains(
          isA<ExecutedProcess>().having((e) => e.command, 'command', contains(endsWith('protoc'))),
        ),
      ),
      reason: 'protoc is not marked as testonly',
    );
  });

  group('--backend bazel', () {
    Map<String, BuilderConfig> linuxConfigs({bool withTests = false}) {
      final builder = TestBuilderConfig();
      builder.addBuild(
        name: 'linux/host_debug',
        dimension: TestDroneDimension.linux,
        enableLto: false,
        targetDir: 'host_debug',
      );
      final Map<String, Object?> json = builder.buildJson();
      if (withTests) {
        // A run_tests.py step, as the CI builds have (a `script` of its own:
        // the shared helper's `testTask` writes a `scripts` list the model
        // does not read).
        final build = (json['builds']! as List<Object?>).single! as Map<String, Object?>;
        build['tests'] = <Object?>[
          <String, Object?>{
            'name': 'Host Tests',
            'language': 'python3',
            'script': 'flutter/testing/run_tests.py',
            'parameters': <String>['--variant', 'host_debug', '--type', 'engine'],
            'contexts': <String>[],
          },
        ];
      }
      return {
        'local_engine': BuilderConfig.fromJson(map: json, path: 'ci/builders/local_engine.json'),
      };
    }

    test("runs the patterns' Bazel counterparts with bazel test", () async {
      final testEnv = TestEnvironment.withTestEngine();
      addTearDown(testEnv.cleanup);

      final runner = ToolCommandRunner(environment: testEnv.environment, configs: linuxConfigs());
      final int result = await runner.run([
        'test',
        '--config',
        'host_debug',
        '--backend',
        'bazel',
        '//flutter/fml:fml_unittests',
        '//flutter/display_list/...',
      ]);

      printOnFailure(testEnv.testLogs.map((r) => r.message).join('\n'));
      expect(result, equals(0));
      expect(testEnv.processHistory.single.command, <String>[
        'bazelisk',
        'test',
        '--config=host_debug',
        '//engine/src/flutter/fml:fml_unittests',
        '//engine/src/flutter/display_list/...',
      ]);
    });

    test("with no patterns runs the build's own suite, if it has test steps", () async {
      final testEnv = TestEnvironment.withTestEngine();
      addTearDown(testEnv.cleanup);

      final runner = ToolCommandRunner(
        environment: testEnv.environment,
        configs: linuxConfigs(withTests: true),
      );
      final int result = await runner.run(['test', '--config', 'host_debug', '--backend', 'bazel']);

      printOnFailure(testEnv.testLogs.map((r) => r.message).join('\n'));
      expect(result, equals(0));
      expect(testEnv.processHistory.single.command, <String>[
        'bazelisk',
        'test',
        '--config=host_debug',
        '//engine/src/flutter/ci/builders:host_debug_tests',
      ]);

      final without = TestEnvironment.withTestEngine();
      addTearDown(without.cleanup);
      final int none = await ToolCommandRunner(
        environment: without.environment,
        configs: linuxConfigs(),
      ).run(['test', '--config', 'host_debug', '--backend', 'bazel']);
      expect(none, equals(1));
      expect(without.processHistory, isEmpty);
    });
  });
}
