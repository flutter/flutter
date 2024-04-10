// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:engine_tool/src/build_utils.dart';
import 'package:engine_tool/src/environment.dart';
import 'package:engine_tool/src/gn_utils.dart';
import 'package:litetest/litetest.dart';
import 'package:platform/platform.dart';

import 'fixtures.dart' as fixtures;
import 'utils.dart';

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

  final Map<String, BuilderConfig> configs = <String, BuilderConfig>{
    'linux_test_config': linuxTestConfig,
  };

  final List<CannedProcess> cannedProcesses = <CannedProcess>[
    CannedProcess((List<String> command) => command.contains('desc'),
        stdout: fixtures.gnDescOutput()),
  ];

  test('find test targets', () async {
    final TestEnvironment testEnvironment =
        TestEnvironment(engine, cannedProcesses: cannedProcesses);
    final Environment env = testEnvironment.environment;
    final Map<String, BuildTarget> testTargets =
        await findTargets(env, engine.outDir);
    expect(testTargets.length, equals(3));
    expect(testTargets['//flutter/display_list:display_list_unittests'],
        notEquals(null));
    expect(
        testTargets['//flutter/display_list:display_list_unittests']!
            .executable!
            .path,
        endsWith('display_list_unittests'));
  });

  test('process queue failure', () async {
    final TestEnvironment testEnvironment =
        TestEnvironment(engine, cannedProcesses: cannedProcesses);
    final Environment env = testEnvironment.environment;
    final Map<String, BuildTarget> testTargets =
        await findTargets(env, engine.outDir);
    expect(selectTargets(<String>['//...'], testTargets).length, equals(3));
    expect(
        selectTargets(<String>['//flutter/display_list'], testTargets).length,
        equals(0));
    expect(
        selectTargets(<String>['//flutter/display_list/...'], testTargets)
            .length,
        equals(1));
    expect(
        selectTargets(<String>['//flutter/display_list:display_list_unittests'],
                testTargets)
            .length,
        equals(1));
  });

  test('targetsFromCommandLine respects defaultToAll when false', () async {
    final TestEnvironment testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    try {
      final Environment env = testEnv.environment;
      final List<Build> builds = runnableBuilds(env, configs, true);
      final Build? build = builds.where(
        (Build build) => build.name == 'linux/host_debug',
      ).firstOrNull;
      final List<BuildTarget>? selectedTargets = await targetsFromCommandLine(
        env, build!, <String>[],
      );
      expect(selectedTargets, isNotNull);
      expect(selectedTargets, isEmpty);
    } finally {
      testEnv.cleanup();
    }
  });

  test('targetsFromCommandLine respects defaultToAll when true', () async {
    final TestEnvironment testEnv = TestEnvironment.withTestEngine(
      cannedProcesses: cannedProcesses,
    );
    try {
      final Environment env = testEnv.environment;
      final List<Build> builds = runnableBuilds(env, configs, true);
      final Build? build = builds.where(
        (Build build) => build.name == 'linux/host_debug',
      ).firstOrNull;
      final List<BuildTarget>? selectedTargets = await targetsFromCommandLine(
        env, build!, <String>[], defaultToAll: true,
      );
      expect(selectedTargets, isNotNull);
      expect(selectedTargets, isNotEmpty);
    } finally {
      testEnv.cleanup();
    }
  });
}
