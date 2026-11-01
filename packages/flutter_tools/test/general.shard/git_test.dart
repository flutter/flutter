// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/git.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';

void main() {
  late BufferLogger logger;
  late Git git;
  late FakeProcessManager processManager;

  setUp(() {
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
  });

  group('repository environment isolation', () {
    setUp(() {
      git = Git(
        currentPlatform: FakePlatform(
          environment: {
            'PATH': '/usr/bin',
            'GIT_DIR': '/outer/repository',
            'git_work_tree': '/outer/worktree',
            'GIT_INDEX_FILE': '/outer/index',
            'GIT_OBJECT_DIRECTORY': '/outer/objects',
            'GIT_ALTERNATE_OBJECT_DIRECTORIES': '/outer/alternates',
            'GIT_QUARANTINE_PATH': '/outer/quarantine',
            'GIT_COMMON_DIR': '/outer/common',
          },
        ),
        runProcessWith: ProcessUtils(processManager: processManager, logger: logger),
      );
      processManager.addCommand(
        const FakeCommand(
          command: ['git', 'rev-parse', 'HEAD'],
          environment: {'PATH': '/usr/bin', 'CUSTOM': 'value'},
          includeParentEnvironment: false,
        ),
      );
    });

    const environment = {'CUSTOM': 'value', 'GIT_DIR': '/another/repository'};

    test('runSync does not re-inherit removed variables', () {
      git.runSync(['rev-parse', 'HEAD'], environment: environment);
    });

    test('run does not re-inherit removed variables', () async {
      await git.run(['rev-parse', 'HEAD'], environment: environment);
    });

    test('run with a timeout does not re-inherit removed variables', () async {
      await git.run(
        ['rev-parse', 'HEAD'],
        environment: environment,
        timeout: const Duration(minutes: 1),
      );
    });

    test('stream does not re-inherit removed variables', () async {
      await git.stream(['rev-parse', 'HEAD'], environment: environment);
    });
  });

  // Regression test for https://github.com/flutter/flutter/issues/74165.
  group('on Windows', () {
    const expectedCygwinEnvVars = {'MSYS': 'noglob', 'CYGWIN': 'noglob'};

    setUp(() {
      git = Git(
        currentPlatform: FakePlatform(operatingSystem: 'windows'),
        runProcessWith: ProcessUtils(processManager: processManager, logger: logger),
      );
    });

    test('git.runSync passes ENV=noglob if environment is omitted', () {
      processManager.addCommand(
        const FakeCommand(command: ['git', 'foo', 'bar'], environment: expectedCygwinEnvVars),
      );
      git.runSync(['foo', 'bar']);
    });

    test('git.runSync passes ENV=noglob if environment is present', () {
      processManager.addCommand(
        const FakeCommand(
          command: ['git', 'foo', 'bar'],
          environment: {...expectedCygwinEnvVars, 'baz': 'BAZ'},
        ),
      );
      git.runSync(['foo', 'bar'], environment: {'baz': 'BAZ'});
    });

    test('git.run passes ENV=noglob if environment is omitted', () async {
      processManager.addCommand(
        const FakeCommand(command: ['git', 'foo', 'bar'], environment: expectedCygwinEnvVars),
      );
      await git.run(['foo', 'bar']);
    });

    test('git.run passes ENV=noglob if environment is present', () async {
      processManager.addCommand(
        const FakeCommand(
          command: ['git', 'foo', 'bar'],
          environment: {...expectedCygwinEnvVars, 'baz': 'BAZ'},
        ),
      );
      await git.run(['foo', 'bar'], environment: {'baz': 'BAZ'});
    });

    test('git.stream passes ENV=noglob if environment is omitted', () async {
      processManager.addCommand(
        const FakeCommand(command: ['git', 'foo', 'bar'], environment: expectedCygwinEnvVars),
      );
      await git.stream(['foo', 'bar']);
    });

    test('git.stream passes ENV=noglob if environment is present', () async {
      processManager.addCommand(
        const FakeCommand(
          command: ['git', 'foo', 'bar'],
          environment: {...expectedCygwinEnvVars, 'baz': 'BAZ'},
        ),
      );
      await git.stream(['foo', 'bar'], environment: {'baz': 'BAZ'});
    });
  });
}
