// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/mocks.dart' show MockProcessManager;
import '../../src/testbed.dart';

void main() {
  Cache.disableLocking();
  group('packages get/upgrade', () {
    Directory tempDir;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    Future<String> createProjectWithPlugin(String plugin, { List<String> arguments }) async {
      final String projectPath = await createProject(tempDir, arguments: arguments);
      final File pubspec = globals.fs.file(globals.fs.path.join(projectPath, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      final List<String> contentLines = LineSplitter.split(content).toList();
      final int depsIndex = contentLines.indexOf('dependencies:');
      expect(depsIndex, isNot(-1));
      contentLines.replaceRange(depsIndex, depsIndex + 1, <String>[
        'dependencies:',
        '  $plugin:',
      ]);
      content = contentLines.join('\n');
      await pubspec.writeAsString(content, flush: true);
      return projectPath;
    }

    Future<PackagesCommand> runCommandIn(String projectPath, String verb, { List<String> args }) async {
      final PackagesCommand command = PackagesCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'packages',
        verb,
        ...?args,
        projectPath,
      ]);
      return command;
    }

    void expectExists(String projectPath, String relPath) {
      expect(
        globals.fs.isFileSync(globals.fs.path.join(projectPath, relPath)),
        true,
        reason: '$projectPath/$relPath should exist, but does not',
      );
    }

    void expectContains(String projectPath, String relPath, String substring) {
      expectExists(projectPath, relPath);
      expect(
        globals.fs.file(globals.fs.path.join(projectPath, relPath)).readAsStringSync(),
        contains(substring),
        reason: '$projectPath/$relPath has unexpected content',
      );
    }

    void expectNotExists(String projectPath, String relPath) {
      expect(
        globals.fs.isFileSync(globals.fs.path.join(projectPath, relPath)),
        false,
        reason: '$projectPath/$relPath should not exist, but does',
      );
    }

    void expectNotContains(String projectPath, String relPath, String substring) {
      expectExists(projectPath, relPath);
      expect(
        globals.fs.file(globals.fs.path.join(projectPath, relPath)).readAsStringSync(),
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
      'ios/Flutter/Debug.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      'ios/Flutter/Release.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    };

    const Map<String, String> modulePluginContentWitnesses = <String, String>{
      '.ios/Config/Debug.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      '.ios/Config/Release.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    };

    void expectDependenciesResolved(String projectPath) {
      for (final String output in pubOutput) {
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
      for (final String path in allFiles) {
        final File file = globals.fs.file(globals.fs.path.join(projectPath, path));
        ErrorHandlingFileSystem.deleteIfExists(file);
      }
    }

    testUsingContext('get fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('get --offline fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get', args: <String>['--offline']);

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('set no plugins as usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get'] as PackagesGetCommand;

      expect(await getCommand.usageValues,
             containsPair(CustomDimensions.commandPackagesNumberPlugins, '0'));
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('set the number of plugins as usage value', () async {
      final String projectPath = await createProject(
        tempDir,
        arguments: <String>['--template=plugin', '--no-pub', '--platforms=ios,android,macos,windows'],
      );
      final String exampleProjectPath = globals.fs.path.join(projectPath, 'example');

      final PackagesCommand command = await runCommandIn(exampleProjectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get'] as PackagesGetCommand;

      expect(await getCommand.usageValues,
          containsPair(CustomDimensions.commandPackagesNumberPlugins, '1'));
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('indicate that the project is not a module in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get'] as PackagesGetCommand;

      expect(await getCommand.usageValues,
             containsPair(CustomDimensions.commandPackagesProjectModule, 'false'));
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('indicate that the project is a module in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get'] as PackagesGetCommand;

      expect(await getCommand.usageValues,
             containsPair(CustomDimensions.commandPackagesProjectModule, 'true'));
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('indicate that Android project reports v1 in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      removeGeneratedFiles(projectPath);

      final File androidManifest = globals.fs.file(globals.fs.path.join(
        projectPath,
        'android/app/src/main/AndroidManifest.xml',
      ));
      final String updatedAndroidManifestString =
          androidManifest.readAsStringSync().replaceAll('android:value="2"', 'android:value="1"');

      androidManifest.writeAsStringSync(updatedAndroidManifestString);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get'] as PackagesGetCommand;

      expect(await getCommand.usageValues,
             containsPair(CustomDimensions.commandPackagesAndroidEmbeddingVersion, 'v1'));
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('indicate that Android project reports v2 in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get'] as PackagesGetCommand;

      expect(await getCommand.usageValues,
             containsPair(CustomDimensions.commandPackagesAndroidEmbeddingVersion, 'v2'));
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('upgrade fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'upgrade');

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, overrides: <Type, Generator>{
      Stdio: () => FakeStdio()..stdout.terminalColumns = 80,
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('get fetches packages and injects plugin', () async {
      final String projectPath = await createProjectWithPlugin('path_provider',
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);
      expectModulePluginInjected(projectPath);
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('get fetches packages and injects plugin in plugin project', () async {
      final String projectPath = await createProject(
        tempDir,
        arguments: <String>['--template=plugin', '--no-pub', '--platforms=ios,android'],
      );
      final String exampleProjectPath = globals.fs.path.join(projectPath, 'example');
      removeGeneratedFiles(projectPath);
      removeGeneratedFiles(exampleProjectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);

      await runCommandIn(exampleProjectPath, 'get');

      expectDependenciesResolved(exampleProjectPath);
      expectPluginInjected(exampleProjectPath);
    }, overrides: <Type, Generator>{
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });
  });

  group('packages test/pub', () {
    MockProcessManager mockProcessManager;
    FakeStdio mockStdio;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockStdio = FakeStdio()..stdout.terminalColumns = 80;
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
      BotDetector: () => const FakeBotDetector(false),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
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
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
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
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('pub publish', () async {
      final PromptingProcess process = PromptingProcess();
      mockProcessManager.processFactory = (List<String> commands) => process;
      final Future<void> runPackages = createTestCommandRunner(PackagesCommand()).run(<String>['pub', 'publish']);
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
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('pub publish input fails', () async {
      final PromptingProcess process = PromptingProcess(stdinError: true);
      mockProcessManager.processFactory = (List<String> commands) => process;
      final Future<void> runPackages = createTestCommandRunner(PackagesCommand()).run(<String>['pub', 'publish']);
      final Future<void> runPrompt = process.showPrompt('Proceed (y/n)? ', <String>['hello', 'world']);
      final Future<void> simulateUserInput = Future<void>(() {
        mockStdio.simulateStdin('y');
      });
      await Future.wait<void>(<Future<void>>[runPackages, runPrompt, simulateUserInput]);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'publish');
      // We get a trace message about the write to stdin failing.
      expect(testLogger.traceText, contains('Echoing stdin to the pub subprocess failed'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('publish', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['pub', 'publish']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'publish');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('packages publish', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'pub', 'publish']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'publish');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('deps', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'deps']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'deps');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('cache', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'cache']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'cache');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('version', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'version']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'version');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('uploader', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'uploader']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'uploader');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('global', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'global', 'list']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(3));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'global');
      expect(commands[2], 'list');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });

    testUsingContext('outdated', () async {
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'outdated']);
      final List<String> commands = mockProcessManager.commands;
      expect(commands, hasLength(2));
      expect(commands[0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(commands[1], 'outdated');
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
      ),
    });
  });
}
