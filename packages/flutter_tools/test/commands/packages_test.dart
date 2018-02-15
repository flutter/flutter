// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart' show MockProcessManager, MockStdio, PromptingProcess;

void main() {
  Cache.disableLocking();
  group('packages get/upgrade', () {
    Directory temp;

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<String> runCommand(String verb, { List<String> args }) async {
      final String projectPath = await createProject(temp);

      final PackagesCommand command = new PackagesCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      final List<String> commandArgs = <String>['packages', verb];
      if (args != null)
        commandArgs.addAll(args);
      commandArgs.add(projectPath);

      await runner.run(commandArgs);

      return projectPath;
    }

    void expectExists(String projectPath, String relPath) {
      expect(fs.isFileSync(fs.path.join(projectPath, relPath)), true);
    }

    // Verify that we create a project that is well-formed.
    testUsingContext('get', () async {
      final String projectPath = await runCommand('get');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('get --offline', () async {
      final String projectPath = await runCommand('get', args: <String>['--offline']);
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('upgrade', () async {
      final String projectPath = await runCommand('upgrade');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    }, timeout: allowForRemotePubInvocation);
  });

  group('packages test/pub', () {
    MockProcessManager mockProcessManager;
    MockStdio mockStdio;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      mockStdio = new MockStdio();
    });

    testUsingContext('test', () async {
      await createTestCommandRunner(new PackagesCommand()).run(<String>['packages', 'test']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(4));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], '--trace');
      expect(commands[2], 'run');
      expect(commands[3], 'test');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
    });

    testUsingContext('run', () async {
      await createTestCommandRunner(new PackagesCommand()).run(<String>['packages', '--verbose', 'pub', 'run', '--foo', 'bar']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(4));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'run');
      expect(commands[2], '--foo');
      expect(commands[3], 'bar');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
    });

    testUsingContext('publish', () async {
      final PromptingProcess process = new PromptingProcess();
      mockProcessManager.processFactory = (List<String> commands) => process;
      final Future<Null> runPackages = createTestCommandRunner(new PackagesCommand()).run(<String>['packages', 'pub', 'publish']);
      final Future<Null> runPrompt = process.showPrompt('Proceed (y/n)? ', <String>['hello', 'world']);
      final Future<Null> simulateUserInput = new Future<Null>(() {
        mockStdio.simulateStdin('y');
      });
      await Future.wait(<Future<Null>>[runPackages, runPrompt, simulateUserInput]);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'publish');
      final List<String> stdout = mockStdio.writtenToStdout;
      expect(stdout, hasLength(4));
      expect(stdout.sublist(0, 2), contains('Proceed (y/n)? '));
      expect(stdout.sublist(0, 2), contains('y\n'));
      expect(stdout[2], 'hello\n');
      expect(stdout[3], 'world\n');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
    });
  });
}
