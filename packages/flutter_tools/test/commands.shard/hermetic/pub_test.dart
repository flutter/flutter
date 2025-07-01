// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/context.dart';
import '../../src/package_config.dart';
import '../../src/test_flutter_command_runner.dart';

const String minimalV2EmbeddingManifest = r'''
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
  late FakePub pub;
  late BufferLogger logger;

  setUp(() {
    Cache.disableLocking();
    fileSystem = MemoryFileSystem.test();
    pub = FakePub();
    logger = BufferLogger.test();
  });

  tearDown(() {
    Cache.enableLocking();
  });

  testUsingContext('pub shows help', () async {
    final PackagesCommand command = PackagesCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['pub']);

    expect(
      logger.statusText,
      allOf(
        contains('Commands for managing Flutter packages.'),
        contains('Usage: flutter pub <subcommand> [arguments]'),
      ),
    );
  }, overrides: <Type, Generator>{Logger: () => logger});

  testUsingContext(
    'pub get usage values are resilient to missing package config files before running "pub get"',
    () async {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      fileSystem.currentDirectory.childFile('.flutter-plugins').createSync();
      fileSystem.currentDirectory.childFile('.flutter-plugins-dependencies').createSync();
      fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(minimalV2EmbeddingManifest);

      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
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
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  testUsingContext(
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

      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
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
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  testUsingContext(
    'pub get on target directory',
    () async {
      fileSystem.currentDirectory.childDirectory('target').createSync();
      final Directory targetDirectory = fileSystem.currentDirectory.childDirectory('target');
      targetDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');

      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);

      await commandRunner.run(<String>['get', '--directory=${targetDirectory.path}']);
      final FlutterProject rootProject = FlutterProject.fromDirectory(targetDirectory);
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
    },
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  testUsingContext(
    "pub get doesn't treat unknown flag as directory",
    () async {
      fileSystem.currentDirectory.childDirectory('target').createSync();
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);
      pub.expectedArguments = <String>['get', '--unknown-flag', '--example', '--directory', '.'];
      await commandRunner.run(<String>['get', '--unknown-flag']);
    },
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  testUsingContext(
    "pub get doesn't treat -v as directory",
    () async {
      fileSystem.currentDirectory.childDirectory('target').createSync();
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);
      pub.expectedArguments = <String>['get', '-v', '--example', '--directory', '.'];
      await commandRunner.run(<String>['get', '-v']);
    },
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/144898
  // Regression test for https://github.com/flutter/flutter/issues/160145
  testUsingContext(
    "pub add doesn't treat dependency syntax as directory",
    () async {
      fileSystem.currentDirectory.childDirectory('target').createSync();
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      fileSystem.currentDirectory.childDirectory('example').createSync(recursive: true);
      fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(minimalV2EmbeddingManifest);

      final PackagesGetCommand command = PackagesGetCommand('add', '', PubContext.pubAdd);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);
      const List<String> availableSyntax = <String>[
        'foo:{"path":"../foo"}',
        'foo:{"hosted":"my-pub.dev"}',
        'foo:{"sdk":"flutter"}',
        'foo:{"git":"https://github.com/foo/foo"}',
      ];
      for (final String syntax in availableSyntax) {
        pub.expectedArguments = <String>['add', syntax, '--example', '--directory', '.'];
        await commandRunner.run(<String>['add', syntax]);
      }
    },
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  testUsingContext(
    "pub get skips example directory if it doesn't contain a pubspec.yaml",
    () async {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync('name: my_app');
      fileSystem.currentDirectory.childDirectory('example').createSync(recursive: true);
      fileSystem.currentDirectory.childDirectory('android').childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(minimalV2EmbeddingManifest);

      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
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
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );

  testUsingContext(
    'pub get throws error on missing directory',
    () async {
      final PackagesGetCommand command = PackagesGetCommand('get', '', PubContext.pubGet);
      final CommandRunner<void> commandRunner = createTestCommandRunner(command);

      try {
        await commandRunner.run(<String>['get', '--directory=missing_dir']);
        fail('expected an exception');
      } on Exception catch (e) {
        expect(e.toString(), contains('Expected to find project root in missing_dir'));
      }
    },
    overrides: <Type, Generator>{
      Pub: () => pub,
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => fileSystem,
    },
  );
}

class FakePub extends Fake implements Pub {
  FakePub();

  List<String>? expectedArguments;

  @override
  Future<void> interactively(
    List<String> arguments, {
    FlutterProject? project,
    required PubContext context,
    required String command,
    bool touchesPackageConfig = false,
    PubOutputMode outputMode = PubOutputMode.all,
  }) async {
    if (project != null) {
      writePackageConfigFiles(directory: project.directory, mainLibName: 'my_app');
    }
  }
}
