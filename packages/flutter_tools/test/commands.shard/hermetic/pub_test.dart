// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' hide FakeProcess;
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

const minimalV2EmbeddingManifest = r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:name="${applicationName}">
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''';

void main() {
  late FileSystem fileSystem;
  late _PubTestProcessManager processManager;
  late BufferLogger logger;

  setUp(() {
    Cache.disableLocking();
    fileSystem = MemoryFileSystem.test();
    processManager = _PubTestProcessManager(fileSystem);
    logger = BufferLogger.test();
  });

  tearDown(() {
    Cache.enableLocking();
  });

  PackagesGetCommand createPackagesGetCommand(
    String commandName,
    String description,
    PubContext context,
  ) {
    final toolContext = FakeToolContext(
      fs: fileSystem,
      logger: logger,
      processManager: processManager,
    );
    return PackagesGetCommand(
      commandName,
      description,
      context,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );
  }

  testWithoutContext('pub shows help', () async {
    final toolContext = FakeToolContext(fs: fileSystem, logger: logger);
    final command = PackagesCommand(
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      toolContext: toolContext,
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['pub']);

    expect(
      logger.statusText,
      allOf(
        contains('Commands for managing Flutter packages.'),
        contains('Usage: flutter pub <subcommand> [arguments]'),
      ),
    );
  });

  testWithoutContext(
    'pub get usage values are resilient to missing package config files before running "pub get"',
    () async {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      fileSystem.currentDirectory.childFile('.flutter-plugins').createSync();
      fileSystem.currentDirectory.childFile('.flutter-plugins-dependencies').createSync();
      fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(minimalV2EmbeddingManifest);

      final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);

      await commandRunner.run(<String>['get']);

      expect(
        await command.unifiedAnalyticsUsageValues('pub'),
        Event.commandUsageValues(
          workflow: 'pub',
          commandHasTerminal: false,
          packagesNumberPlugins: 0,
          packagesProjectModule: false,
          packagesAndroidEmbeddingVersion: 'v2',
        ),
      );
    },
  );

  testWithoutContext(
    'pub get usage values are resilient to poorly formatted package config before "pub get"',
    () async {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      fileSystem.currentDirectory.childFile('.flutter-plugins').createSync();
      fileSystem.currentDirectory.childFile('.flutter-plugins-dependencies').createSync();
      fileSystem.currentDirectory.childFile('.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[0]);
      fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(minimalV2EmbeddingManifest);

      final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);

      await commandRunner.run(<String>['get']);

      expect(
        await command.unifiedAnalyticsUsageValues('pub'),
        Event.commandUsageValues(
          workflow: 'pub',
          commandHasTerminal: false,
          packagesNumberPlugins: 0,
          packagesProjectModule: false,
          packagesAndroidEmbeddingVersion: 'v2',
        ),
      );
    },
  );

  testWithoutContext('pub get on target directory', () async {
    fileSystem.currentDirectory.childDirectory('target').createSync();
    final Directory targetDirectory = fileSystem.currentDirectory.childDirectory('target');
    targetDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');

    final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await commandRunner.run(<String>['get', '--directory=${targetDirectory.path}']);
    final FlutterProject rootProject = FlutterProject.fromDirectoryTest(targetDirectory, logger);
    final File packageConfigFile = rootProject.dartTool.childFile('package_config.json');

    expect(packageConfigFile.existsSync(), true);
    expect(json.decode(packageConfigFile.readAsStringSync()), <String, Object>{
      'configVersion': 2,
      'packages': <Object?>[
        <String, Object?>{
          'name': 'my_app',
          'rootUri': '../',
          'packageUri': 'lib/',
          'languageVersion': '3.7',
        },
      ],
    });
  });

  testWithoutContext("pub get doesn't treat unknown flag as directory", () async {
    fileSystem.currentDirectory.childDirectory('target').createSync();
    fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
    final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    await commandRunner.run(<String>['get', '--unknown-flag']);
    expect(
      processManager.lastCommand,
      containsAllInOrder(<String>['get', '--unknown-flag', '--example', '--directory', '.']),
    );
  });

  testWithoutContext("pub get doesn't treat -v as directory", () async {
    fileSystem.currentDirectory.childDirectory('target').createSync();
    fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
    final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    await commandRunner.run(<String>['get', '-v']);
    expect(
      processManager.lastCommand,
      containsAllInOrder(<String>['get', '-v', '--example', '--directory', '.']),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/144898
  // Regression test for https://github.com/flutter/flutter/issues/160145
  testWithoutContext("pub add doesn't treat dependency syntax as directory", () async {
    fileSystem.currentDirectory.childDirectory('target').createSync();
    fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
    fileSystem.currentDirectory.childDirectory('example').createSync(recursive: true);
    fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
      ..createSync(recursive: true)
      ..writeAsStringSync(minimalV2EmbeddingManifest);

    final PackagesGetCommand command = createPackagesGetCommand('add', '', PubContext.pubAdd);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);
    const availableSyntax = <String>[
      'foo:{"path":"../foo"}',
      'foo:{"hosted":"my-pub.dev"}',
      'foo:{"sdk":"flutter"}',
      'foo:{"git":"https://github.com/foo/foo"}',
    ];
    for (final syntax in availableSyntax) {
      await commandRunner.run(<String>['add', syntax]);
      expect(
        processManager.lastCommand,
        containsAllInOrder(<String>['add', syntax, '--example', '--directory', '.']),
      );
    }
  });

  testWithoutContext(
    "pub get skips example directory if it doesn't contain a pubspec.yaml",
    () async {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      fileSystem.currentDirectory.childDirectory('example').createSync(recursive: true);
      fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(minimalV2EmbeddingManifest);

      final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);

      await commandRunner.run(<String>['get']);

      expect(
        await command.unifiedAnalyticsUsageValues('pub'),
        Event.commandUsageValues(
          workflow: 'pub',
          commandHasTerminal: false,
          packagesNumberPlugins: 0,
          packagesProjectModule: false,
          packagesAndroidEmbeddingVersion: 'v2',
        ),
      );
    },
  );

  testWithoutContext('pub get throws error on missing directory', () async {
    final PackagesGetCommand command = createPackagesGetCommand('get', '', PubContext.pubGet);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    try {
      await commandRunner.run(<String>['get', '--directory=missing_dir']);
      fail('expected an exception');
    } on Exception catch (e) {
      expect(e.toString(), contains('Expected to find project root in missing_dir'));
    }
  });

  testWithoutContext(
    'packages forward command forwards command name and arguments to pub',
    () async {
      final toolContext = FakeToolContext(
        fs: fileSystem,
        logger: logger,
        processManager: processManager,
      );
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      final command = PackagesCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        toolContext: toolContext,
      );
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['pub', 'outdated', '--json']);
      expect(
        processManager.lastCommand,
        containsAllInOrder(<String>['pub', '--suppress-analytics', 'outdated', '--json']),
      );
    },
  );
}

class _PubTestProcessManager extends Fake implements ProcessManager {
  _PubTestProcessManager(this.fileSystem);

  final FileSystem fileSystem;
  List<String>? lastCommand;

  @override
  bool canRun(Object? executable, {String? workingDirectory}) => true;

  @override
  Future<io.Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    io.ProcessStartMode mode = io.ProcessStartMode.normal,
  }) async {
    final stringCommand = <String>[for (final e in command) e.toString()];
    lastCommand = stringCommand;
    String? dir;
    const directoryFlagPrefix = '--directory=';
    for (final (index, arg) in stringCommand.indexed) {
      if (arg == '--directory' && index + 1 < stringCommand.length) {
        dir = stringCommand[index + 1];
        break;
      }
      if (arg.startsWith(directoryFlagPrefix)) {
        dir = arg.substring(directoryFlagPrefix.length);
        break;
      }
    }
    final Directory targetDir = dir != null
        ? fileSystem.directory(dir)
        : fileSystem.currentDirectory;
    writePackageConfigFiles(directory: targetDir, mainLibName: 'my_app');
    return FakeProcess();
  }

  @override
  io.ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    covariant Object? stdoutEncoding = io.systemEncoding,
    covariant Object? stderrEncoding = io.systemEncoding,
  }) {
    if (command.contains('tag')) {
      return io.ProcessResult(1, 0, '1.2.3', '');
    }
    return io.ProcessResult(1, 0, '1234567890abcdef', '');
  }
}
