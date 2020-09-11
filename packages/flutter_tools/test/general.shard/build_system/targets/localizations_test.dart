// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/localizations.dart';
import 'package:flutter_tools/src/localizations/gen_l10n.dart';
import 'package:mockito/mockito.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  // Verifies that values are correctly passed through the localizations
  // target, but does not validate them beyond the serialized data type.
  testUsingContext('generateLocalizations forwards arguments correctly', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Logger logger = BufferLogger.test();
    final Directory flutterProjectDirectory = fileSystem
      .directory(fileSystem.path.join('path', 'to', 'flutter_project'))
      ..createSync(recursive: true);
    final Directory arbDirectory = flutterProjectDirectory
      .childDirectory('arb')
      ..createSync();
    arbDirectory.childFile('foo.arb').createSync();
    arbDirectory.childFile('bar.arb').createSync();

    final LocalizationOptions options = LocalizationOptions(
      header: 'HEADER',
      headerFile: Uri.file('header'),
      arbDirectory: Uri.file('arb'),
      deferredLoading: true,
      outputClass: 'Foo',
      outputLocalizationsFile: Uri.file('bar'),
      preferredSupportedLocales: <String>['en_US'],
      templateArbFile: Uri.file('example.arb'),
      untranslatedMessagesFile: Uri.file('untranslated'),
      useSyntheticPackage: false,
    );

    final LocalizationsGenerator mockLocalizationsGenerator = MockLocalizationsGenerator();
    generateLocalizations(
      localizationsGenerator: mockLocalizationsGenerator,
      options: options,
      logger: logger,
      projectDir: fileSystem.currentDirectory,
      dependenciesDir: fileSystem.currentDirectory,
    );

    verify(
      mockLocalizationsGenerator.initialize(
      inputPathString: 'arb',
      outputPathString: null,
      templateArbFileName: 'example.arb',
      outputFileString: 'bar',
      classNameString: 'Foo',
      preferredSupportedLocale: <String>['en_US'],
      headerString: 'HEADER',
      headerFile: 'header',
      useDeferredLoading: true,
      inputsAndOutputsListPath: '/',
      useSyntheticPackage: false,
      projectPathString: '/',
      ),
    ).called(1);
    verify(mockLocalizationsGenerator.loadResources()).called(1);
    verify(mockLocalizationsGenerator.writeOutputFiles()).called(1);
    verify(mockLocalizationsGenerator.outputUnimplementedMessages('untranslated', logger)).called(1);
  });

  testUsingContext('generateLocalizations throws exception on missing flutter: generate: true flag', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final Directory arbDirectory = fileSystem.directory('arb')
      ..createSync();
    arbDirectory.childFile('foo.arb').createSync();
    arbDirectory.childFile('bar.arb').createSync();

    // Missing flutter: generate: true should throw exception.
    fileSystem.file('pubspec.yaml').writeAsStringSync('''
flutter:
  uses-material-design: true
''');

    final LocalizationOptions options = LocalizationOptions(
      header: 'HEADER',
      headerFile: Uri.file('header'),
      arbDirectory: Uri.file('arb'),
      deferredLoading: true,
      outputClass: 'Foo',
      outputLocalizationsFile: Uri.file('bar'),
      preferredSupportedLocales: <String>['en_US'],
      templateArbFile: Uri.file('example.arb'),
      untranslatedMessagesFile: Uri.file('untranslated'),
      // Set synthetic package to true.
      useSyntheticPackage: true,
    );

    final LocalizationsGenerator mockLocalizationsGenerator = MockLocalizationsGenerator();
    expect(
      () => generateLocalizations(
        localizationsGenerator: mockLocalizationsGenerator,
        options: options,
        logger: logger,
        projectDir: fileSystem.currentDirectory,
        dependenciesDir: fileSystem.currentDirectory,
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      logger.errorText,
      contains('Attempted to generate localizations code without having the flutter: generate flag turned on.'),
    );
  });

  testWithoutContext('generateLocalizations is skipped if l10n.yaml does not exist.', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Environment environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    );

    expect(const GenerateLocalizationsTarget().canSkip(environment), true);

    environment.projectDir.childFile('l10n.yaml').createSync();

    expect(const GenerateLocalizationsTarget().canSkip(environment), false);
  });

  testWithoutContext('parseLocalizationsOptions handles valid yaml configuration', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
arb-dir: arb
template-arb-file: example.arb
output-localization-file: bar
untranslated-messages-file: untranslated
output-class: Foo
header-file: header
header: HEADER
use-deferred-loading: true
preferred-supported-locales: en_US
''');

    final LocalizationOptions options = parseLocalizationsOptions(
      file: configFile,
      logger: BufferLogger.test(),
    );

    expect(options.arbDirectory, Uri.parse('arb'));
    expect(options.templateArbFile, Uri.parse('example.arb'));
    expect(options.outputLocalizationsFile, Uri.parse('bar'));
    expect(options.untranslatedMessagesFile, Uri.parse('untranslated'));
    expect(options.outputClass, 'Foo');
    expect(options.headerFile, Uri.parse('header'));
    expect(options.header, 'HEADER');
    expect(options.deferredLoading, true);
    expect(options.preferredSupportedLocales, <String>['en_US']);
  });

  testWithoutContext('parseLocalizationsOptions handles preferredSupportedLocales as list', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')..writeAsStringSync('''
preferred-supported-locales: ['en_US', 'de']
''');

    final LocalizationOptions options = parseLocalizationsOptions(
      file: configFile,
      logger: BufferLogger.test(),
    );

    expect(options.preferredSupportedLocales, <String>['en_US', 'de']);
  });

  testWithoutContext(
      'parseLocalizationsOptions throws exception on invalid yaml configuration',
      () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')..writeAsStringSync('''
use-deferred-loading: string
''');

    expect(
      () => parseLocalizationsOptions(
        file: configFile,
        logger: BufferLogger.test(),
      ),
      throwsA(isA<Exception>()),
    );
  });
}

class MockLocalizationsGenerator extends Mock implements LocalizationsGenerator {}
