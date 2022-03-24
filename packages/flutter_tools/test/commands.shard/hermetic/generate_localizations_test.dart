// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/generate_localizations.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../integration.shard/test_data/basic_project.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  FileSystem fileSystem;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  testUsingContext('default l10n settings', () async {
    final BufferLogger logger = BufferLogger.test();
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    final GenerateLocalizationsCommand command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
    );
    await createTestCommandRunner(command).run(<String>['gen-l10n']);

    final FlutterCommandResult result = await command.runCommand();
    expect(result.exitStatus, ExitStatus.success);
    final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('.dart_tool', 'flutter_gen', 'gen_l10n'));
    expect(outputDirectory.existsSync(), true);
    expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
    expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('not using synthetic packages', () async {
    final BufferLogger logger = BufferLogger.test();
    final Directory l10nDirectory = fileSystem.directory(
      fileSystem.path.join('lib', 'l10n'),
    );
    final File arbFile = l10nDirectory.childFile(
      'app_en.arb',
    )..createSync(recursive: true);

    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');

    final GenerateLocalizationsCommand command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
    );
    await createTestCommandRunner(command).run(<String>[
      'gen-l10n',
      '--no-synthetic-package',
    ]);

    final FlutterCommandResult result = await command.runCommand();
    expect(result.exitStatus, ExitStatus.success);
    expect(l10nDirectory.existsSync(), true);
    expect(l10nDirectory.childFile('app_localizations_en.dart').existsSync(), true);
    expect(l10nDirectory.childFile('app_localizations.dart').existsSync(), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('throws error when arguments are invalid', () async {
    final BufferLogger logger = BufferLogger.test();
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fileSystem.file('header.txt').writeAsStringSync('a header file');

    final GenerateLocalizationsCommand command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
    );
    expect(
      () => createTestCommandRunner(command).run(<String>[
        'gen-l10n',
        '--header="some header',
        '--header-file="header.txt"',
      ]),
      throwsToolExit(),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('l10n yaml file takes precedence over command line arguments', () async {
    final BufferLogger logger = BufferLogger.test();
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fileSystem.file('l10n.yaml').createSync();
    final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
    pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
    final GenerateLocalizationsCommand command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
    );
    await createTestCommandRunner(command).run(<String>['gen-l10n']);

    final FlutterCommandResult result = await command.runCommand();
    expect(result.exitStatus, ExitStatus.success);
    expect(logger.statusText, contains('Because l10n.yaml exists, the options defined there will be used instead.'));
    final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('.dart_tool', 'flutter_gen', 'gen_l10n'));
    expect(outputDirectory.existsSync(), true);
    expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
    expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('nullable-getter help message is expected string', () async {
    final BufferLogger logger = BufferLogger.test();
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
    fileSystem.file('l10n.yaml').createSync();
    final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
    pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
    final GenerateLocalizationsCommand command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
    );
    await createTestCommandRunner(command).run(<String>['gen-l10n']);
    expect(command.usage, contains(' If this value is set to false, then '));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}
