// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late FakePub pub;

  setUp(() {
    Cache.disableLocking();
    fileSystem = MemoryFileSystem.test();
    pub = FakePub(fileSystem);
  });

  tearDown(() {
    Cache.enableLocking();
  });

  testUsingContext('pub get usage values are resilient to missing package config files before running "pub get"', () async {
    fileSystem.currentDirectory.childFile('pubspec.yaml').createSync();
    fileSystem.currentDirectory.childFile('.flutter-plugins').createSync();
    fileSystem.currentDirectory.childFile('.flutter-plugins-dependencies').createSync();

    final PackagesGetCommand command = PackagesGetCommand('get', false);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await commandRunner.run(<String>['get']);

    expect(await command.usageValues, const CustomDimensions(
      commandPackagesNumberPlugins: 0,
      commandPackagesProjectModule: false,
      commandPackagesAndroidEmbeddingVersion: 'v1',
    ));
  }, overrides: <Type, Generator>{
    Pub: () => pub,
    ProcessManager: () => FakeProcessManager.any(),
    FileSystem: () => fileSystem,
  });

  testUsingContext('pub get usage values are resilient to poorly formatted package config before "pub get"', () async {
    fileSystem.currentDirectory.childFile('pubspec.yaml').createSync();
    fileSystem.currentDirectory.childFile('.flutter-plugins').createSync();
    fileSystem.currentDirectory.childFile('.flutter-plugins-dependencies').createSync();
    fileSystem.currentDirectory.childFile('.packages').writeAsBytesSync(<int>[0]);
    fileSystem.currentDirectory.childFile('.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[0]);

    final PackagesGetCommand command = PackagesGetCommand('get', false);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await commandRunner.run(<String>['get']);

    expect(await command.usageValues, const CustomDimensions(
      commandPackagesNumberPlugins: 0,
      commandPackagesProjectModule: false,
      commandPackagesAndroidEmbeddingVersion: 'v1',
    ));
  }, overrides: <Type, Generator>{
    Pub: () => pub,
    ProcessManager: () => FakeProcessManager.any(),
    FileSystem: () => fileSystem,
  });

  testUsingContext('pub get on target directory', () async {
    fileSystem.currentDirectory.childDirectory('target').createSync();
    final Directory targetDirectory = fileSystem.currentDirectory.childDirectory('target');
    targetDirectory.childFile('pubspec.yaml').createSync();

    final PackagesGetCommand command = PackagesGetCommand('get', false);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await commandRunner.run(<String>['get', targetDirectory.path]);
    final FlutterProject rootProject = FlutterProject.fromDirectory(targetDirectory);
    expect(rootProject.packageConfigFile.existsSync(), true);
    expect(await rootProject.packageConfigFile.readAsString(), '{"configVersion":2,"packages":[]}');
  }, overrides: <Type, Generator>{
    Pub: () => pub,
    ProcessManager: () => FakeProcessManager.any(),
    FileSystem: () => fileSystem,
  });

  testUsingContext("pub get skips example directory if it doesn't contain a pubspec.yaml", () async {
    fileSystem.currentDirectory.childFile('pubspec.yaml').createSync();
    fileSystem.currentDirectory.childDirectory('example').createSync(recursive: true);

    final PackagesGetCommand command = PackagesGetCommand('get', false);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await commandRunner.run(<String>['get']);

    expect(await command.usageValues, const CustomDimensions(
      commandPackagesNumberPlugins: 0,
      commandPackagesProjectModule: false,
      commandPackagesAndroidEmbeddingVersion: 'v1',
    ));
  }, overrides: <Type, Generator>{
    Pub: () => pub,
    ProcessManager: () => FakeProcessManager.any(),
    FileSystem: () => fileSystem,
  });

  testUsingContext('pub get triggers localizations generation when generate: true', () async {
    final File pubspecFile = fileSystem.currentDirectory.childFile('pubspec.yaml')
      ..createSync();
    pubspecFile.writeAsStringSync(
      '''
      flutter:
        generate: true
      '''
    );
    fileSystem.currentDirectory.childFile('l10n.yaml')
      ..createSync()
      ..writeAsStringSync(
        '''
        arb-dir: lib/l10n
        '''
      );
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync(
      '''
      {
        "helloWorld": "Hello, World!",
        "@helloWorld": {
          "description": "Sample description"
        }
      }
      '''
    );

    final PackagesGetCommand command = PackagesGetCommand('get', false);
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    await commandRunner.run(<String>['get']);
    final FlutterCommandResult result = await command.runCommand();

    expect(result.exitStatus, ExitStatus.success);
    final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('.dart_tool', 'flutter_gen', 'gen_l10n'));
    expect(outputDirectory.existsSync(), true);
    expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
    expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
  }, overrides: <Type, Generator>{
    Pub: () => pub,
    ProcessManager: () => FakeProcessManager.any(),
    FileSystem: () => fileSystem,
  });
}

class FakePub extends Fake implements Pub {
  FakePub(this.fileSystem);

  final FileSystem fileSystem;

  @override
  Future<void> get({
    required PubContext context,
    String? directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool generateSyntheticPackage = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool printProgress = true,
  }) async {
    fileSystem.directory(directory)
      .childDirectory('.dart_tool')
      .childFile('package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{"configVersion":2,"packages":[]}');
  }
}
