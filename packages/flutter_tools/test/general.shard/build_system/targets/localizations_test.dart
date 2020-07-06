// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/localizations.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  // Verifies that values are correctly passed through the localizations
  // target, but does not validate them beyond the serialized data type.
  testWithoutContext('generateLocalizations forwards arguments correctly', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Logger logger = BufferLogger.test();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'dart',
          '--disable-dart-dev',
          'dev/tools/localization/bin/gen_l10n.dart',
          '--gen-inputs-and-outputs-list=/',
          '--arb-dir=arb',
          '--template-arb-file=example.arb',
          '--output-localization-file=bar',
          '--untranslated-messages-file=untranslated',
          '--output-class=Foo',
          '--header-file=header',
          '--header=HEADER',
          '--use-deferred-loading',
          '--preferred-supported-locales=en_US'
        ],
      ),
    ]);
    final Directory arbDirectory = fileSystem.directory('arb')
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
      preferredSupportedLocales: 'en_US',
      templateArbFile: Uri.file('example.arb'),
      untranslatedMessagesFile: Uri.file('untranslated'),
    );
    await generateLocalizations(
      options: options,
      logger: logger,
      fileSystem: fileSystem,
      processManager: processManager,
      projectDir: fileSystem.currentDirectory,
      dartBinaryPath: 'dart',
      flutterRoot: '',
      dependenciesDir: fileSystem.currentDirectory,
    );

    expect(processManager.hasRemainingExpectations, false);
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
    expect(options.preferredSupportedLocales, 'en_US');
  });

  testWithoutContext('parseLocalizationsOptions throws exception on invalid yaml configuration', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
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
