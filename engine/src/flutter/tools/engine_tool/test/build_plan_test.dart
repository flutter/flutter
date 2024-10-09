// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_tool/src/build_plan.dart';
import 'package:engine_tool/src/logger.dart';
import 'package:test/test.dart';

import 'src/test_build_configs.dart';
import 'src/utils.dart';

void main() {
  test('rbe defaults to true if detected', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.useRbe, isTrue);
    expect(plan.toGnArgs(), isNot(contains('--no-rbe')));
  });

  test('rbe defaults to false if not detected', () {
    final testEnv = TestEnvironment.withTestEngine(
      // This is the default, but make it explicit for the test.
      // ignore: avoid_redundant_argument_values
      withRbe: false,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.useRbe, isFalse);
    expect(plan.toGnArgs(), contains('--no-rbe'));
  });

  test('rbe forced to true if not detected is an error', () {
    final testEnv = TestEnvironment.withTestEngine(
      // This is the default, but make it explicit for the test.
      // ignore: avoid_redundant_argument_values
      withRbe: false,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    expect(
      () => BuildPlan.fromArgResults(
        parser.parse(['--rbe']),
        testEnv.environment,
        builds: builds,
      ),
      throwsA(isA<FatalError>().having(
        (e) => e.toString(),
        'toString()',
        contains('RBE requested but configuration not found'),
      )),
    );
  });

  test('lto is true if explicitly enabled', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse(['--lto']),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.useLto, isTrue);
    expect(plan.toGnArgs(), contains('--lto'));
  });

  test('lto is false if explicitly disabled', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse(['--no-lto']),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.useLto, isFalse);
    expect(plan.toGnArgs(), contains('--no-lto'));
  });

  test('lto is true if the config omits --no-lto', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
    );

    expect(
      plan.useLto,
      isTrue,
      reason: 'Not specified and the build config did not include --no-lto',
    );
    expect(plan.toGnArgs(), contains('--lto'));
  });

  test('lto is false if the config uses --no-lto', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
      enableLto: false,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
    );

    expect(
      plan.useLto,
      isFalse,
      reason: 'Not specified and the build config included --no-lto',
    );
    expect(plan.toGnArgs(), contains('--no-lto'));
  });

  test('concurrency defaults to null if not specified', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.concurrency, isNull);
  });

  test('concurrency parses the number provided', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse(['--concurrency=1024']),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.concurrency, 1024);
  });

  test('concurrency fails on a non-integer', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    expect(
      () => BuildPlan.fromArgResults(
        parser.parse(['--concurrency=ABCD']),
        testEnv.environment,
        builds: builds,
      ),
      throwsA(isA<FatalError>().having(
        (e) => e.toString(),
        'toString()',
        contains('Invalid value for --concurrency: ABCD'),
      )),
    );
  });

  test('concurrency fails on a negative integer', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    expect(
      () => BuildPlan.fromArgResults(
        parser.parse(['--concurrency=-1024']),
        testEnv.environment,
        builds: builds,
      ),
      throwsA(isA<FatalError>().having(
        (e) => e.toString(),
        'toString()',
        contains('Invalid value for --concurrency: -1024'),
      )),
    );
  });

  test('strategy defaults to auto', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse(['--concurrency=1024']),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.strategy, BuildStrategy.auto);
    expect(
      plan.toRbeConfig(),
      same(const RbeConfig()),
      reason: 'Auto should use the default RbeConfig instance.',
    );
  });

  test('strategy can be set to --local', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse(['--build-strategy=local']),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.strategy, BuildStrategy.local);
    expect(
      plan.toRbeConfig(),
      same(const RbeConfig(
        execStrategy: RbeExecStrategy.local,
        remoteDisabled: true,
      )),
      reason: 'Local should use RbeExecStrategy.local with RBE disabled',
    );
  });

  test('strategy can be set to --remote', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse(['--build-strategy=remote']),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.strategy, BuildStrategy.remote);
    expect(
      plan.toRbeConfig(),
      same(const RbeConfig(execStrategy: RbeExecStrategy.remote)),
      reason: 'Local should use RbeExecStrategy.remote',
    );
  });

  test('strategy of --remote with RBE disabled fails', () {
    final testEnv = TestEnvironment.withTestEngine(
      // This is the default, but make it explicit for the test.
      // ignore: avoid_redundant_argument_values
      withRbe: false,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    expect(
      () => BuildPlan.fromArgResults(
        parser.parse(['--build-strategy=remote']),
        testEnv.environment,
        builds: builds,
      ),
      throwsA(isA<FatalError>().having(
        (e) => e.toString(),
        'toString()',
        contains('Cannot use remote builds without RBE enabled'),
      )),
    );
  });

  test('build defaults to host_debug', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
    );

    expect(plan.build.name, 'linux/host_debug');
  });

  test('build defaults to the provided default', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug_unopt_arm64',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    final plan = BuildPlan.fromArgResults(
      parser.parse([]),
      testEnv.environment,
      builds: builds,
      defaultBuild: () => 'host_debug_unopt_arm64',
    );

    expect(plan.build.name, 'linux/host_debug_unopt_arm64');
  });

  test('build fails if host_debug not specified and no config set', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug_unopt_arm64',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    expect(
      () => BuildPlan.fromArgResults(
        parser.parse([]),
        testEnv.environment,
        builds: builds,
      ),
      throwsA(isA<FatalError>().having(
        (e) => e.toString(),
        'toString()',
        contains('Unknown build configuration: host_debug'),
      )),
    );
  });

  test('build fails if a config not available is requested', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final builds = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: false,
    );

    expect(
      () => BuildPlan.fromArgResults(
        parser.parse(['--config=host_debug_unopt_arm64']),
        testEnv.environment,
        builds: builds,
      ),
      throwsA(
        isA<ArgParserException>().having(
          (e) => e.toString(),
          'toString()',
          contains(
            '"host_debug_unopt_arm64" is not an allowed value for option',
          ),
        ),
      ),
    );
  });

  test('show builds in help message as long as not a [ci/...] build', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'ci/host_debug',
      dimension: TestDroneDimension.linux,
    );
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(parser.usage, contains('host_debug'));
    expect(parser.usage, isNot(contains('ci/host_debug')));
  });

  test('shows [ci/...] builds if verbose is true', () {
    final testEnv = TestEnvironment.withTestEngine(
      verbose: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'ci/host_debug',
      dimension: TestDroneDimension.linux,
    );
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(parser.usage, contains('host_debug'));
    expect(parser.usage, contains('ci/host_debug'));
  });

  test('hides LTO instructions normally', () {
    final testEnv = TestEnvironment.withTestEngine();
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      isNot(contains('Whether LTO should be enabled for a build')),
    );
  });

  test('shows LTO instructions if verbose', () {
    final testEnv = TestEnvironment.withTestEngine(
      verbose: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'ci/host_debug',
      dimension: TestDroneDimension.linux,
    );
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      contains('Whether LTO should be enabled for a build'),
    );
  });

  test('shows RBE instructions if not configured', () {
    final testEnv = TestEnvironment.withTestEngine(
      // This is the default, but make it explicit for the test.
      // ignore: avoid_redundant_argument_values
      withRbe: false,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      contains('Enable pre-configured remote build execution'),
    );
    expect(
      parser.usage,
      contains('https://flutter.dev/to/engine-rbe'),
    );
  });

  test('shows RBE instructions if verbose', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
      verbose: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      contains('Enable pre-configured remote build execution'),
    );
    expect(
      parser.usage,
      contains('https://flutter.dev/to/engine-rbe'),
    );
  });

  test('hides RBE intsructions if enabled', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      contains('Enable pre-configured remote build execution'),
    );
    expect(
      parser.usage,
      isNot(contains('https://flutter.dev/to/engine-rbe')),
    );
  });

  test('hides --build-strategy if RBE not enabled', () {
    final testEnv = TestEnvironment.withTestEngine(
      // This is the default, but make it explicit for the test.
      // ignore: avoid_redundant_argument_values
      withRbe: false,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      isNot(contains('How to prefer remote or local builds')),
    );
  });

  test('shows --build-strategy if RBE enabled', () {
    final testEnv = TestEnvironment.withTestEngine(
      withRbe: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      contains('How to prefer remote or local builds'),
    );
  });

  test('shows --build-strategy if verbose', () {
    final testEnv = TestEnvironment.withTestEngine(
      verbose: true,
    );
    addTearDown(testEnv.cleanup);

    final testConfig = TestBuilderConfig();
    testConfig.addBuild(
      name: 'linux/host_debug',
      dimension: TestDroneDimension.linux,
    );

    final parser = ArgParser();
    final _ = BuildPlan.configureArgParser(
      parser,
      testEnv.environment,
      configs: {
        'linux_test_config': testConfig.buildConfig(
          path: 'ci/builders/linux_test_config.json',
        ),
      },
      help: true,
    );

    expect(
      parser.usage,
      contains('How to prefer remote or local builds'),
    );
  });
}
