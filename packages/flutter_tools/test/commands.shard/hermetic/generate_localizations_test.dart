// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/depfile.dart' show Depfile;
import 'package:flutter_tools/src/build_system/targets/localizations.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/generate_localizations.dart';
import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';

import '../../integration.shard/test_data/basic_project.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Artifacts artifacts;
  late FakeProcessManager processManager;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    processManager = FakeProcessManager.empty();
  });

  testUsingContext(
    'default l10n settings',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'throws error when arguments are invalid',
    () async {
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
      fileSystem.file('pubspec.yaml').writeAsStringSync('''
flutter:
  generate: true''');
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      expect(
        () => createTestCommandRunner(
          command,
        ).run(<String>['gen-l10n', '--header="some header', '--header-file="header.txt"']),
        throwsToolExit(),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'l10n yaml file takes precedence over command line arguments',
    () async {
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
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: FakeProcessManager.any(),
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);

      expect(
        logger.statusText,
        contains('Because l10n.yaml exists, the options defined there will be used instead.'),
      );
      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'nullable-getter help message is expected string',
    () async {
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
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: FakeProcessManager.any(),
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);
      expect(command.usage, contains(' If this value is set to false, then '));
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'dart format is run when --format is passed',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartBinary',
            'format',
            '/lib/l10n/app_localizations_en.dart',
            '/lib/l10n/app_localizations.dart',
          ],
        ),
      );

      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );

      await createTestCommandRunner(command).run(<String>['gen-l10n', '--format']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'dart format is not run when --no-format is passed',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);

      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );

      await createTestCommandRunner(command).run(<String>['gen-l10n', '--no-format']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'dart format is run when format: true is passed into l10n.yaml',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File configFile = fileSystem.file('l10n.yaml')..createSync();
      configFile.writeAsStringSync('''
format: true
''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartBinary',
            'format',
            '/lib/l10n/app_localizations_en.dart',
            '/lib/l10n/app_localizations.dart',
          ],
        ),
      );
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'dart format is not running when format: false is passed into l10n.yaml',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File configFile = fileSystem.file('l10n.yaml')..createSync();
      configFile.writeAsStringSync('''
format: false
''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/119594
  testUsingContext(
    'dart format is working when the untranslated messages file is produced',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "untranslated": "Test untranslated message."
}''');
      fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_es.arb'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "helloWorld": "Hello, World!"
}''');
      final File configFile = fileSystem.file('l10n.yaml')..createSync();
      configFile.writeAsStringSync('''
format: true
untranslated-messages-file: lib/l10n/untranslated.json
''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartBinary',
            'format',
            '/lib/l10n/app_localizations_en.dart',
            '/lib/l10n/app_localizations_es.dart',
            '/lib/l10n/app_localizations.dart',
          ],
        ),
      );
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_es.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      final File untranslatedMessagesFile = fileSystem.file(
        fileSystem.path.join('lib', 'l10n', 'untranslated.json'),
      );
      expect(untranslatedMessagesFile.existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  // Regression test for https://github.com/flutter/flutter/issues/120530.
  testUsingContext(
    'dart format is run when generateLocalizations is called through build target',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File configFile = fileSystem.file('l10n.yaml')..createSync();
      configFile.writeAsStringSync('''
format: true
''');
      const Target buildTarget = GenerateLocalizationsTarget();
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'Artifact.engineDartBinary',
            'format',
            '/lib/l10n/app_localizations_en.dart',
            '/lib/l10n/app_localizations.dart',
          ],
        ),
      );
      final environment = Environment.test(
        fileSystem.currentDirectory,
        artifacts: artifacts,
        processManager: processManager,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
      );
      await buildTarget.build(environment);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), true);
      expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testUsingContext('generates normalized input & output file paths', () async {
    final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true);
    arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!"
}''');
    final File configFile = fileSystem.file('l10n.yaml')..createSync();
    // Writing both forward and backward slashes to test both cases.
    configFile.writeAsStringSync(r'''
arb-dir: lib/l10n
output-dir: lib\l10n
format: false
''');
    final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
    pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);

    processManager.addCommand(const FakeCommand(command: <String>[]));
    final environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
    const Target buildTarget = GenerateLocalizationsTarget();
    await buildTarget.build(environment);

    final File dependencyFile = environment.buildDir.childFile(buildTarget.depfiles.single);
    final Depfile depfile = environment.depFileService.parse(dependencyFile);

    final oppositeSeparator = fileSystem.path.separator == '/' ? r'\' : '/';
    expect(depfile.inputs, everyElement(isNot(contains(oppositeSeparator))));
    expect(depfile.outputs, everyElement(isNot(contains(oppositeSeparator))));
  });

  testUsingContext(
    'nullable-getter defaults to true',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      await createTestCommandRunner(command).run(<String>['gen-l10n']);

      final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('app_localizations.dart').existsSync(), isTrue);
      expect(
        outputDirectory.childFile('app_localizations.dart').readAsStringSync(),
        contains('static AppLocalizations? of(BuildContext context)'),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'throw when generate: false when run with l10n.yaml',
    () async {
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
      pubspecFile.writeAsStringSync('''
  name: test
  environment:
    sdk: ^3.7.0-0

  dependencies:
    flutter:
      sdk: flutter

  flutter:
    generate: false
  ''');
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      expect(
        () async => createTestCommandRunner(command).run(<String>['gen-l10n']),
        throwsToolExit(
          message:
              'Attempted to generate localizations code without having the flutter: generate flag turned on.',
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext(
    'throw when generate: false when run via commandline options',
    () async {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      arbFile.writeAsStringSync('''
{
  "helloWorld": "Hello, World!",
  "@helloWorld": {
    "description": "Sample description"
  }
}''');
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('''
  name: test
  environment:
    sdk: ^3.7.0-0

  dependencies:
    flutter:
      sdk: flutter

  flutter:
    generate: false
  ''');
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      expect(
        () async => createTestCommandRunner(command).run(<String>['gen-l10n']),
        throwsToolExit(
          message:
              'Attempted to generate localizations code without having the flutter: generate flag turned on.',
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    },
  );

  testUsingContext('throws error when unexpected positional argument is provided', () {
    final command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
      artifacts: artifacts,
      processManager: processManager,
    );
    expect(
      () async => createTestCommandRunner(command).run(<String>['gen-l10n', 'false']),
      throwsToolExit(message: 'Unexpected positional argument "false".'),
    );
  });

  testUsingContext('throws error when synthetic-package is provided', () async {
    final command = GenerateLocalizationsCommand(
      fileSystem: fileSystem,
      logger: logger,
      artifacts: artifacts,
      processManager: processManager,
    );
    await expectLater(
      () async => createTestCommandRunner(command).run(<String>['gen-l10n', '--synthetic-package']),
      throwsToolExit(message: 'synthetic-package'),
    );
  });

  testUsingContext(
    'prints warning when --no-synthetic-package is provided',
    () async {
      final command = GenerateLocalizationsCommand(
        fileSystem: fileSystem,
        logger: logger,
        artifacts: artifacts,
        processManager: processManager,
      );
      fileSystem
          .file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
          .createSync(recursive: true);
      final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
      await createTestCommandRunner(command).run(<String>['gen-l10n', '--no-synthetic-package']);
      expect(logger.warningText, contains('synthetic-package'));
    },
    overrides: <Type, Generator>{Logger: () => logger},
  );

  group(AppResourceBundle, () {
    testWithoutContext("can be parsed without FormatException when it's content is empty", () {
      final File arbFile = fileSystem.file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
        ..createSync(recursive: true);
      expect(AppResourceBundle(arbFile), isA<AppResourceBundle>());
    });

    testUsingContext(
      "would not fail the gen-l10n command when it's content is empty",
      () async {
        fileSystem
            .file(fileSystem.path.join('lib', 'l10n', 'app_en.arb'))
            .createSync(recursive: true);
        final File pubspecFile = fileSystem.file('pubspec.yaml')..createSync();
        pubspecFile.writeAsStringSync(BasicProjectWithFlutterGen().pubspec);
        final command = GenerateLocalizationsCommand(
          fileSystem: fileSystem,
          logger: logger,
          artifacts: artifacts,
          processManager: processManager,
        );
        await createTestCommandRunner(command).run(<String>['gen-l10n']);

        final Directory outputDirectory = fileSystem.directory(fileSystem.path.join('lib', 'l10n'));
        expect(outputDirectory.existsSync(), true);
        expect(outputDirectory.childFile('app_localizations_en.dart').existsSync(), true);
        expect(outputDirectory.childFile('app_localizations.dart').existsSync(), true);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}
