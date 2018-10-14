// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart' show MockProcessManager, MockStdio, PromptingProcess;

class AlwaysTrueBotDetector implements BotDetector {
  const AlwaysTrueBotDetector();

  @override
  bool get isRunningOnBot => true;
}


class AlwaysFalseBotDetector implements BotDetector {
  const AlwaysFalseBotDetector();

  @override
  bool get isRunningOnBot => false;
}


void main() {
  Cache.disableLocking();
  group('packages get/upgrade', () {
    Directory tempDir;

    setUp(() {
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    Future<String> createProjectWithPlugin(String plugin, {List<String> arguments}) async {
      final String projectPath = await createProject(tempDir, arguments: arguments);
      final File pubspec = fs.file(fs.path.join(projectPath, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  $plugin:\n',
      );
      await pubspec.writeAsString(content, flush: true);
      return projectPath;
    }

    Future<void> runCommandIn(String projectPath, String verb, { List<String> args }) async {
      final PackagesCommand command = PackagesCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      final List<String> commandArgs = <String>['packages', verb];
      if (args != null)
        commandArgs.addAll(args);
      commandArgs.add(projectPath);

      await runner.run(commandArgs);
    }

    void expectExists(String projectPath, String relPath) {
      expect(
        fs.isFileSync(fs.path.join(projectPath, relPath)),
        true,
        reason: '$projectPath/$relPath should exist, but does not',
      );
    }

    void expectContains(String projectPath, String relPath, String substring) {
      expectExists(projectPath, relPath);
      expect(
        fs.file(fs.path.join(projectPath, relPath)).readAsStringSync(),
        contains(substring),
        reason: '$projectPath/$relPath has unexpected content'
      );
    }

    void expectNotExists(String projectPath, String relPath) {
      expect(
        fs.isFileSync(fs.path.join(projectPath, relPath)),
        false,
        reason: '$projectPath/$relPath should not exist, but does',
      );
    }

    void expectNotContains(String projectPath, String relPath, String substring) {
      expectExists(projectPath, relPath);
      expect(
        fs.file(fs.path.join(projectPath, relPath)).readAsStringSync(),
        isNot(contains(substring)),
        reason: '$projectPath/$relPath has unexpected content',
      );
    }

    const List<String> pubOutput = <String>[
      '.packages',
      'pubspec.lock',
    ];

    const List<String> pluginRegistrants = <String>[
      'ios/Runner/GeneratedPluginRegistrant.h',
      'ios/Runner/GeneratedPluginRegistrant.m',
      'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
    ];

    const List<String> modulePluginRegistrants = <String>[
      '.ios/Flutter/FlutterPluginRegistrant/Classes/GeneratedPluginRegistrant.h',
      '.ios/Flutter/FlutterPluginRegistrant/Classes/GeneratedPluginRegistrant.m',
      '.android/Flutter/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
    ];

    const List<String> pluginWitnesses = <String>[
      '.flutter-plugins',
      'ios/Podfile',
    ];

    const List<String> modulePluginWitnesses = <String>[
      '.flutter-plugins',
      '.ios/Podfile',
    ];

    const Map<String, String> pluginContentWitnesses = <String, String>{
      'ios/Flutter/Debug.xcconfig': '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      'ios/Flutter/Release.xcconfig': '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    };

    const Map<String, String> modulePluginContentWitnesses = <String, String>{
      '.ios/Config/Debug.xcconfig': '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      '.ios/Config/Release.xcconfig': '#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    };

    void expectDependenciesResolved(String projectPath) {
      for (String output in pubOutput) {
        expectExists(projectPath, output);
      }
    }

    void expectZeroPluginsInjected(String projectPath) {
      for (final String registrant in modulePluginRegistrants) {
        expectExists(projectPath, registrant);
      }
      for (final String witness in pluginWitnesses) {
        expectNotExists(projectPath, witness);
      }
      modulePluginContentWitnesses.forEach((String witness, String content) {
        expectNotContains(projectPath, witness, content);
      });
    }

    void expectPluginInjected(String projectPath) {
      for (final String registrant in pluginRegistrants) {
        expectExists(projectPath, registrant);
      }
      for (final String witness in pluginWitnesses) {
        expectExists(projectPath, witness);
      }
      pluginContentWitnesses.forEach((String witness, String content) {
        expectContains(projectPath, witness, content);
      });
    }

    void expectModulePluginInjected(String projectPath) {
      for (final String registrant in modulePluginRegistrants) {
        expectExists(projectPath, registrant);
      }
      for (final String witness in modulePluginWitnesses) {
        expectExists(projectPath, witness);
      }
      modulePluginContentWitnesses.forEach((String witness, String content) {
        expectContains(projectPath, witness, content);
      });
    }

    void removeGeneratedFiles(String projectPath) {
      final Iterable<String> allFiles = <List<String>>[
        pubOutput,
        modulePluginRegistrants,
        pluginWitnesses,
      ].expand<String>((List<String> list) => list);
      for (String path in allFiles) {
        final File file = fs.file(fs.path.join(projectPath, path));
        if (file.existsSync())
          file.deleteSync();
      }
    }

    testUsingContext('get fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('get --offline fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get', args: <String>['--offline']);

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, timeout: allowForCreateFlutterProject);

    testUsingContext('upgrade fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'upgrade');

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('get fetches packages and injects plugin', () async {
      final String projectPath = await createProjectWithPlugin('path_provider',
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);
      expectModulePluginInjected(projectPath);
    }, timeout: allowForRemotePubInvocation);

    testUsingContext('get fetches packages and injects plugin in plugin project', () async {
      final String projectPath = await createProject(
        tempDir,
        arguments: <String>['--template=plugin', '--no-pub'],
      );
      final String exampleProjectPath = fs.path.join(projectPath, 'example');
      removeGeneratedFiles(projectPath);
      removeGeneratedFiles(exampleProjectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);

      await runCommandIn(exampleProjectPath, 'get');

      expectDependenciesResolved(exampleProjectPath);
      expectPluginInjected(exampleProjectPath);
    }, timeout: allowForRemotePubInvocation);
  });

  group('packages test/pub', () {
    MockProcessManager mockProcessManager;
    MockStdio mockStdio;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockStdio = MockStdio();
    });

    testUsingContext('test without bot', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'test']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(3));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'run');
      expect(commands[2], 'test');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const AlwaysFalseBotDetector(),
    });

    testUsingContext('test with bot', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'test']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(4));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], '--trace');
      expect(commands[2], 'run');
      expect(commands[3], 'test');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const AlwaysTrueBotDetector(),
    });

    testUsingContext('run', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', '--verbose', 'pub', 'run', '--foo', 'bar']);
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
      final PromptingProcess process = PromptingProcess();
      mockProcessManager.processFactory = (List<String> commands) => process;
      final Future<void> runPackages = createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'pub', 'publish']);
      final Future<void> runPrompt = process.showPrompt('Proceed (y/n)? ', <String>['hello', 'world']);
      final Future<void> simulateUserInput = Future<void>(() {
        mockStdio.simulateStdin('y');
      });
      await Future.wait<void>(<Future<void>>[runPackages, runPrompt, simulateUserInput]);
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
