// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:engine_build_configs/src/build_config.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:engine_tool/src/commands/run_command.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:engine_tool/src/flutter_tool_interop/device.dart';
import 'package:engine_tool/src/flutter_tool_interop/flutter_tool.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:process_fakes/process_fakes.dart';
import 'package:process_runner/process_runner.dart';
import 'package:test/test.dart';

import '../src/test_build_configs.dart';
import '../src/utils.dart';

void main() {
  late io.Directory tempRoot;
  late TestEngine testEngine;

  setUp(() {
    tempRoot = io.Directory.systemTemp.createTempSync('engine_tool_test');
    testEngine = TestEngine.createTemp(rootDir: tempRoot);
  });

  tearDown(() {
    tempRoot.deleteSync(recursive: true);
  });

  test('fails if flutter is not on your PATH', () async {
    final failsCanRun = FakeProcessManager(
      canRun: (executable, {workingDirectory}) {
        if (executable == 'flutter') {
          return false;
        }
        fail('Unexpected');
      },
    );

    final testEnvironment = Environment(
      abi: Abi.macosArm64,
      engine: testEngine,
      logger: Logger.test((_) {}),
      platform: _fakePlatform(Platform.linux),
      processRunner: ProcessRunner(defaultWorkingDirectory: tempRoot, processManager: failsCanRun),
    );

    final CommandRunner<int> et = _engineTool(
      RunCommand(
        environment: testEnvironment,
        // Intentionally left blank, none of these builds make it far enough.
        configs: {},
      ),
    );

    expect(
      () => et.run(['run']),
      throwsA(
        isA<FatalError>().having(
          (a) => a.toString(),
          'toString()',
          contains('"flutter" command in your PATH'),
        ),
      ),
    );
  });

  group('configuration failures', () {
    final unusedProcessManager = FakeProcessManager(canRun: (_, {workingDirectory}) => true);

    late List<LogRecord> testLogs;
    late Environment testEnvironment;
    late _FakeFlutterTool flutterTool;

    setUp(() {
      testLogs = [];
      testEnvironment = Environment(
        abi: Abi.linuxX64,
        engine: testEngine,
        logger: Logger.test(testLogs.add),
        platform: _fakePlatform(Platform.linux),
        processRunner: ProcessRunner(
          defaultWorkingDirectory: tempRoot,
          processManager: unusedProcessManager,
        ),
      );
      flutterTool = _FakeFlutterTool();
    });

    test('fails if a host build could not be found', () async {
      final builders = TestBuilderConfig();
      builders.addBuild(
        name: 'linux/android_debug_arm64',
        dimension: TestDroneDimension.linux,
        targetDir: 'android_debug_arm64',
      );

      final CommandRunner<int> et = _engineTool(
        RunCommand(
          environment: testEnvironment,
          configs: {
            'linux_test_config': builders.buildConfig(path: 'ci/builders/linux_test_config.json'),
          },
          flutterTool: flutterTool,
        ),
      );

      expect(
        () => et.run(['run', '--config=android_debug_arm64']),
        throwsA(
          isA<FatalError>().having(
            (a) => a.toString(),
            'toString()',
            contains('Could not find host build'),
          ),
        ),
      );
    });
  });

  group('builds and executes `flutter run`', () {
    late CommandRunner<int> et;
    late io.Directory rbeDir;

    var commandsRun = <List<String>>[];
    var testLogs = <LogRecord>[];
    var attachedDevices = <Device>[];
    var interceptCommands = <(String, FakeProcess? Function(List<String>))>[];

    setUp(() {
      // Builder configuration doesn't change for these tests. The Android
      // build is one the Bazel build has no platform for (x86), which the
      // refusing test below relies on.
      final builders = TestBuilderConfig();
      builders.addBuild(
        name: 'linux/android_debug_arm64',
        dimension: TestDroneDimension.linux,
        targetDir: 'android_debug_arm64',
        enableRbe: true,
        gnFlags: const ['--android', '--android-cpu=x86', '--no-lto'],
      );
      builders.addBuild(
        name: 'linux/host_debug',
        dimension: TestDroneDimension.linux,
        targetDir: 'host_debug',
        enableRbe: true,
        // As the developer's build is: the Bazel backend has no LTO.
        enableLto: false,
      );

      // Be very permissive on process execution, and check usage below instead.
      final permissiveProcessManager = FakeProcessManager(
        canRun: (_, {workingDirectory}) => true,
        onRun: (FakeCommandLogEntry entry) {
          commandsRun.add(entry.command);
          return io.ProcessResult(81, 0, '', '');
        },
        onStart: (FakeCommandLogEntry entry) {
          commandsRun.add(entry.command);
          for (final intercept in interceptCommands) {
            if (entry.command.first.endsWith(intercept.$1)) {
              final FakeProcess? result = intercept.$2(entry.command);
              if (result != null) {
                return result;
              }
            }
          }
          switch (entry.command) {
            case ['flutter', 'devices', '--machine', ..._]:
              return FakeProcess(stdout: jsonEncode(attachedDevices));
            default:
              return FakeProcess();
          }
        },
      );

      // Create an RBE directory by default.
      rbeDir = io.Directory(p.join(testEngine.srcDir.path, 'flutter', 'build', 'rbe'));
      rbeDir.createSync(recursive: true);

      // Set up the environment for the test.
      final testEnvironment = Environment(
        abi: Abi.linuxX64,
        engine: testEngine,
        logger: Logger.test((log) {
          testLogs.add(log);
        }),
        platform: _fakePlatform(Platform.linux),
        processRunner: ProcessRunner(
          defaultWorkingDirectory: tempRoot,
          processManager: permissiveProcessManager,
        ),
      );

      // Set up the Flutter tool for the test.
      et = _engineTool(
        RunCommand(
          environment: testEnvironment,
          configs: {
            'linux_test_config': builders.buildConfig(path: 'ci/builders/linux_test_config.json'),
          },
        ),
      );

      // Reset logs.
      commandsRun = [];
      attachedDevices = [];
      testLogs = [];
      interceptCommands = [];
    });

    tearDown(() {
      printOnFailure('Commands run:\n${commandsRun.map((c) => c.join('\n'))}');
      printOnFailure('Logs:\n${testLogs.map((l) => l.message).join('\n')}');
    });

    test('build includes RBE flags when enabled implicitly', () async {
      await et.run(['run', '--config=android_debug_arm64']);

      expect(
        commandsRun,
        containsAllInOrder([
          // ./tools/gn --rbe
          containsAllInOrder([endsWith('tools/gn'), contains('--rbe')]),

          // ./reclient/bootstrap
          containsAllInOrder([endsWith('reclient/bootstrap')]),
        ]),
      );
    });

    test('build excludes RBE flags when disabled', () async {
      await et.run(['run', '--config=android_debug_arm64', '--no-rbe']);

      expect(
        commandsRun,
        containsAllInOrder([
          // ./tools/gn --no-rbe
          containsAllInOrder([endsWith('tools/gn'), contains('--no-rbe')]),

          // ./reclient/bootstrap
          isNot(containsAllInOrder([endsWith('reclient/bootstrap')])),
        ]),
      );
    });

    test('picks a default concurrency for RBE builds', () async {
      await et.run(['run', '--config=android_debug_arm64']);

      expect(
        commandsRun,
        containsAllInOrder([
          // ninja -C out/android_debug_arm64 -j 1000 (or whatever is picked)
          containsAllInOrder([
            endsWith('ninja/ninja'),
            contains('-j'),
            isA<String>().having(int.tryParse, 'concurrency', greaterThan(100)),
          ]),
        ]),
      );
    });

    test('does not define a default concurrency for non-RBE builds', () async {
      await et.run(['run', '--no-rbe', '--config=android_debug_arm64']);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder([endsWith('ninja/ninja'), isNot(contains('-j'))]),
        ]),
      );
    });

    test('define a user-specified concurrency for non-RBE builds', () async {
      await et.run(['run', '--concurrency=42', '--no-rbe', '--config=android_debug_arm64']);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder([endsWith('ninja/ninja'), contains('-j'), '42']),
        ]),
      );
    });

    test('handles host build failures', () async {
      interceptCommands.add((
        'ninja',
        (command) {
          print(command);
          if (command.any((c) => c.contains('host_debug'))) {
            return FakeProcess(exitCode: 1);
          }
          return null;
        },
      ));

      expect(
        () => et.run(['run', '--config=android_debug_arm64']),
        throwsA(
          isA<FatalError>().having(
            (a) => a.toString(),
            'toString()',
            contains('Failed to build host'),
          ),
        ),
      );
    });

    test('handles target build failures', () async {
      interceptCommands.add((
        'ninja',
        (command) {
          if (command.any((c) => c.contains('android_debug_arm64'))) {
            return FakeProcess(exitCode: 1);
          }
          return null;
        },
      ));

      expect(
        () => et.run(['run', '--config=android_debug_arm64']),
        throwsA(
          isA<FatalError>().having(
            (a) => a.toString(),
            'toString()',
            contains('Failed to build target'),
          ),
        ),
      );
    });

    test('builds only once if the target and host are the same', () async {
      await et.run(['run', '--config=host_debug']);

      expect(commandsRun, containsOnce(containsAllInOrder([endsWith('ninja'), '-C'])));
    });

    test('builds both the target and host if they are different', () async {
      await et.run(['run', '--config=android_debug_arm64']);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder([endsWith('ninja'), contains('host_debug')]),
          containsAllInOrder([endsWith('ninja'), contains('android_debug_arm64')]),
        ]),
      );
    });

    test('delegates to `flutter run` with --local-engine flags', () async {
      await et.run(['run', '--config=android_debug_arm64']);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder([
            endsWith('flutter'),
            contains('run'),
            '--local-engine-src-path',
            testEngine.srcDir.path,
            '--local-engine',
            'android_debug_arm64',
            '--local-engine-host',
            'host_debug',
          ]),
        ]),
      );
    });

    test('delegates to `flutter run` with --flutter-flags', () async {
      await et.run([
        'run',
        '--config=android_debug_arm64',
        '--flutter-flags=--foo',
        '--flutter-flags=--bar=baz,foobar',
        '--flutter-flags=--flag1 --flag2',
      ]);

      expect(
        commandsRun,
        containsAllInOrder([
          containsAllInOrder(['flutter', 'run', '--foo', '--bar=baz,foobar', '--flag1', '--flag2']),
        ]),
      );
    });

    test('--backend bazel installs the host build with Bazel, then runs `flutter run`', () async {
      final int? result = await et.run(['run', '--config=host_debug', '--backend', 'bazel']);

      expect(result, equals(0));
      expect(
        commandsRun.where((c) => c.first.endsWith('ninja') || c.first.endsWith('/gn')),
        isEmpty,
      );
      expect(
        commandsRun,
        containsAllInOrder([
          [
            'bazelisk',
            'run',
            '--config=host_debug',
            // The builder's own install target: the test's build names
            // ninja targets (a developer's, without, is read in place through
            // its local engine manifest; the group below).
            '//engine/src/flutter/ci/builders:host_debug',
            '--',
            p.join(testEngine.outDir.path, 'host_debug'),
          ],
          containsAllInOrder([
            endsWith('flutter'),
            contains('run'),
            '--local-engine',
            'host_debug',
            '--local-engine-host',
            'host_debug',
          ]),
        ]),
      );
    });

    test('--backend bazel refuses a target build the Bazel build has none for', () async {
      final int? result = await et.run([
        'run',
        '--config=android_debug_arm64',
        '--backend',
        'bazel',
      ]);

      expect(result, equals(1));
      // The host was installed; the Android build stopped it before flutter run.
      expect(commandsRun, contains(containsAllInOrder(['bazelisk', 'run', '--config=host_debug'])));
      expect(commandsRun.where((c) => c.first.endsWith('flutter') && c.contains('run')), isEmpty);
      expect(
        testLogs.map((l) => l.message).join(),
        contains('cannot express linux/android_debug_arm64'),
      );
    });

    group("--backend bazel with the developer's builds", () {
      // local_engine.json's builds: ninja's default target, everything (no
      // ninja targets), which the flutter tool reads where Bazel builds it,
      // through each build's local engine manifest.
      Map<String, BuilderConfig> developerConfigs() {
        final builders = TestBuilderConfig();
        builders.addBuild(
          name: 'linux/android_debug_arm64',
          dimension: TestDroneDimension.linux,
          targetDir: 'android_debug_arm64',
          gnFlags: const ['--android', '--android-cpu=arm64'],
          enableLto: false,
        );
        builders.addBuild(
          name: 'linux/host_debug',
          dimension: TestDroneDimension.linux,
          targetDir: 'host_debug',
          enableLto: false,
        );
        final Map<String, Object?> json = builders.buildJson();
        for (final build in json['builds']! as List<Object?>) {
          ((build! as Map<String, Object?>)['ninja']! as Map<String, Object?>)['targets'] =
              <String>[];
        }
        return {
          'local_engine': BuilderConfig.fromJson(map: json, path: 'ci/builders/local_engine.json'),
        };
      }

      test('builds the host and Android local engines, then runs `flutter run` on both', () async {
        // What Bazel answers: the output directory, and each configuration's
        // manifest among its local engine target's files.
        final testEnv = TestEnvironment.withTestEngine(
          cannedProcesses: <CannedProcess>[
            CannedProcess(
              (command) => command.length > 1 && command[1] == 'info',
              stdout: '/cache/execroot/_main/bazel-out\n',
            ),
            CannedProcess(
              (command) =>
                  command.length > 2 &&
                  command[1] == 'cquery' &&
                  command[2] == '--config=host_debug',
              stdout: 'bazel-out/k8-dbg/bin/engine/src/flutter/local_engine.json\n',
            ),
            CannedProcess(
              (command) =>
                  command.length > 2 &&
                  command[1] == 'cquery' &&
                  command[2] == '--config=android_debug_arm64',
              stdout: 'bazel-out/android_arm64-opt/bin/engine/src/flutter/local_engine.json\n',
            ),
          ],
        );
        addTearDown(testEnv.cleanup);
        final CommandRunner<int> et = _engineTool(
          RunCommand(
            environment: testEnv.environment,
            configs: developerConfigs(),
            flutterTool: _FakeFlutterTool(),
          ),
        );

        final int? result = await et.run([
          'run',
          '--config=android_debug_arm64',
          '--backend',
          'bazel',
        ]);

        printOnFailure(testEnv.testLogs.map((r) => r.message).join('\n'));
        expect(result, equals(0));
        final List<List<String>> commands = testEnv.processHistory.map((p) => p.command).toList();
        // Neither build is installed: there is no install target to run.
        expect(commands.where((c) => c.first == 'bazelisk' && c[1] == 'run'), isEmpty);
        expect(
          commands,
          containsAllInOrder([
            ['bazelisk', 'build', '--config=host_debug', '//engine/src/flutter:local_engine'],
            [
              'bazelisk',
              'build',
              '--config=android_debug_arm64',
              '//engine/src/flutter:local_engine',
            ],
            containsAllInOrder([
              endsWith('flutter'),
              'run',
              '--local-engine',
              '/cache/execroot/_main/bazel-out/android_arm64-opt/bin/engine/src/flutter',
              '--local-engine-host',
              '/cache/execroot/_main/bazel-out/k8-dbg/bin/engine/src/flutter',
            ]),
          ]),
        );
      });
    });

    group('delegates to `flutter run` in mode', () {
      for (final mode in const ['debug', 'profile', 'release']) {
        test('$mode mode', () async {
          await et.run(['run', '--config=android_debug_arm64', '--', '--$mode']);

          expect(
            commandsRun,
            containsAllInOrder([
              containsAllInOrder([endsWith('flutter'), contains('run'), contains('--$mode')]),
            ]),
          );
        });
      }
    });
  });

  // FIXME: Add positive tests.
  // ^^^ Both sets, calls flutter run as expected n stuff.
  // ... and check debug/profile/release
}

CommandRunner<int> _engineTool(RunCommand runCommand) {
  return CommandRunner<int>('et', 'Fake tool with a single instrumented command.')
    ..addCommand(runCommand);
}

Platform _fakePlatform(String os, {int numberOfProcessors = 32, String pathSeparator = '/'}) {
  return FakePlatform(
    operatingSystem: os,
    resolvedExecutable: io.Platform.resolvedExecutable,
    numberOfProcessors: numberOfProcessors,
    pathSeparator: pathSeparator,
  );
}

final class _FakeFlutterTool implements FlutterTool {
  List<Device> respondWithDevices = [];

  @override
  Future<List<Device>> devices() async {
    return respondWithDevices;
  }
}
