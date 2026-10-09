// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/localizations.dart';
import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';
import 'package:flutter_tools/src/localizations/localizations_utils.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';

void main() {
  testWithoutContext('generateLocalizations is skipped if l10n.yaml does not exist.', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final environment = Environment.test(
      fileSystem.currentDirectory,
      artifacts: Artifacts.test(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    );

    expect(await const GenerateLocalizationsTarget().canSkip(environment), true);

    environment.projectDir.childFile('l10n.yaml').createSync();

    expect(await const GenerateLocalizationsTarget().canSkip(environment), false);
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
required-resource-attributes: false
nullable-getter: false
''');

    final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
      file: configFile,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      defaultArbDir: fileSystem.path.join('lib', 'l10n'),
    );

    expect(options.arbDir, Uri.parse('arb').path);
    expect(options.templateArbFile, Uri.parse('example.arb').path);
    expect(options.outputLocalizationFile, Uri.parse('bar').path);
    expect(options.untranslatedMessagesFile, Uri.parse('untranslated').path);
    expect(options.outputClass, 'Foo');
    expect(options.headerFile, Uri.parse('header').path);
    expect(options.header, 'HEADER');
    expect(options.useDeferredLoading, true);
    expect(options.preferredSupportedLocales, <String>['en_US']);
    expect(options.requiredResourceAttributes, false);
    expect(options.nullableGetter, false);
  });

  testWithoutContext('parseLocalizationsOptions refuses synthetic-package: true', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
arb-dir: arb
synthetic-package: true
template-arb-file: example.arb
output-localization-file: bar
untranslated-messages-file: untranslated
output-class: Foo
header-file: header
header: HEADER
use-deferred-loading: true
preferred-supported-locales: en_US
required-resource-attributes: false
nullable-getter: false
''');

    expect(
      () => parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      ),
      throwsToolExit(message: 'synthetic-package'),
    );
  });

  testWithoutContext('parseLocalizationsOptions warns on synthetic-package: false', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
arb-dir: arb
synthetic-package: false
template-arb-file: example.arb
output-localization-file: bar
untranslated-messages-file: untranslated
output-class: Foo
header-file: header
header: HEADER
use-deferred-loading: true
preferred-supported-locales: en_US
required-resource-attributes: false
nullable-getter: false
''');

    final logger = BufferLogger.test();
    expect(
      () => parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: logger,
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      ),
      returnsNormally,
    );

    expect(logger.warningText, contains('synthetic-package'));
  });

  testWithoutContext(
    'parseLocalizationsOptions handles preferredSupportedLocales as list',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
preferred-supported-locales: ['en_US', 'de']
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.preferredSupportedLocales, <String>['en_US', 'de']);
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws exception on invalid yaml configuration',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
use-deferred-loading: string
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsException,
      );
    },
  );

  testWithoutContext('parseLocalizationsOptions tool exits on malformed Yaml', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
template-arb-file: {name}_en.arb
''');

    expect(
      () => parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      ),
      throwsToolExit(),
    );
  });

  testWithoutContext('parseLocalizationsOptions handles new extensibility options', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
arb-dir:
  - lib/l10n
  - lib/features/auth/l10n
output-class-mixins:
  "*":
    - GlobalMixin
  es:
    - EsMixin
output-base-class-mixins:
  - BaseMixin
fallback-locale: en
localization-runtime:
  package: package:core/core.dart
  alias: coreTr
''');

    final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
      file: configFile,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      defaultArbDir: fileSystem.path.join('lib', 'l10n'),
    );

    expect(options.arbDir, fileSystem.path.join('lib', 'l10n'));
    expect(options.arbDirs, <String>[
      fileSystem.path.join('lib', 'l10n'),
      fileSystem.path.join('lib', 'features', 'auth', 'l10n'),
    ]);
    expect(options.outputClassMixins, <String, List<String>>{
      '*': <String>['GlobalMixin'],
      'es': <String>['EsMixin'],
    });
    expect(options.outputBaseClassMixins, <String>['BaseMixin']);
    expect(options.fallbackLocale, 'en');
    expect(options.libraryPackage, 'package:core/core.dart');
    expect(options.libraryAlias, 'coreTr');
  });

  testWithoutContext(
    'parseLocalizationsOptions defaults localization-runtime to intl values',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
arb-dir: lib/l10n
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.libraryPackage, 'package:intl/intl.dart');
      expect(options.libraryAlias, 'intl');
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions handles output-class-mixins as a flat list',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
output-class-mixins:
  - FirstMixin
  - SecondMixin
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.outputClassMixins, <String, List<String>>{
        '*': <String>['FirstMixin', 'SecondMixin'],
      });
    },
  );

  testWithoutContext('parseLocalizationsOptions handles qualified mixins in output-base-class-mixins and output-class-mixins', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
localization-runtime:
  package: package:core/core.dart
  alias: "coreX"

output-base-class-mixins:
  - coreX.CoreLocalizations

output-class-mixins:
  ar:
    - coreX.CoreLocalizationsAr
  fallback:
    - coreX.CoreLocalizationsEn
''');

    final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
      file: configFile,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      defaultArbDir: fileSystem.path.join('lib', 'l10n'),
    );

    expect(options.outputBaseClassMixins, <String>['coreX.CoreLocalizations']);
    expect(options.outputClassMixins, <String, List<String>>{
      'ar': <String>['coreX.CoreLocalizationsAr'],
      'fallback': <String>['coreX.CoreLocalizationsEn'],
    });
  });

  testWithoutContext(
    'parseLocalizationsOptions handles mixed qualified and unqualified mixins',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
output-base-class-mixins:
  - CoreLocalizations
  - coreX.CoreLocalizationsExtra

output-class-mixins:
  ar:
    - CoreLocalizationsAr
    - coreX.CoreLocalizationsArExtra
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.outputBaseClassMixins, <String>[
        'CoreLocalizations',
        'coreX.CoreLocalizationsExtra',
      ]);
      expect(options.outputClassMixins, <String, List<String>>{
        'ar': <String>['CoreLocalizationsAr', 'coreX.CoreLocalizationsArExtra'],
      });
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid localization-runtime alias',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  alias: 123InvalidAlias
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid Dart identifier'),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid localization-runtime package',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  package: not-a-valid-uri
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid URI'),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws on malformed localization-runtime',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime: package:core/core.dart
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Expected "localization-runtime" to be a map'),
          ),
        ),
      );
    },
  );

  testWithoutContext('parseLocalizationsOptions throws on invalid mixin name', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
output-class-mixins:
  - 123InvalidMixin
''');

    expect(
      () => parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      ),
      throwsA(
        isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('is not a valid Dart mixin type reference'),
        ),
      ),
    );
  });

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid qualified mixin or arbitrary expression',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      const invalidMixins = <String>[
        'core-x.CoreLocalizations',
        'coreX.invalidClass',
        'coreX.',
        '.CoreLocalizations',
        'coreX.CoreLocalizations.Extra',
        'foo.bar.baz()',
        'Foo()',
        'Foo + Bar',
        'foo.bar + baz',
      ];

      for (final invalidMixin in invalidMixins) {
        final File configFile = fileSystem.file('l10n.yaml')
          ..writeAsStringSync('''
output-class-mixins:
  - $invalidMixin
''');

        expect(
          () => parseLocalizationsOptionsFromYAML(
            file: configFile,
            logger: BufferLogger.test(),
            fileSystem: fileSystem,
            defaultArbDir: fileSystem.path.join('lib', 'l10n'),
          ),
          throwsA(
            isA<L10nException>().having(
              (L10nException e) => e.message,
              'message',
              contains('is not a valid Dart mixin type reference'),
            ),
          ),
          reason: 'Failed to reject invalid mixin: "$invalidMixin"',
        );
      }
    },
  );

  testWithoutContext('parseLocalizationsOptions throws on invalid fallback-locale', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
fallback-locale: invalid locale with spaces
''');

    expect(
      () => parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      ),
      throwsA(
        isA<L10nException>().having(
          (L10nException e) => e.message,
          'message',
          contains('must be a valid locale identifier'),
        ),
      ),
    );
  });

  testWithoutContext(
    'parseLocalizationsOptions parses localization-runtime with full symbols configuration',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  package: package:custom_l10n/custom_l10n.dart
  alias: custom_l10n
  symbols:
    canonicalized-locale: CustomLocale.canonicalize
    plural-logic: CustomPlural.resolve
    select-logic: CustomSelect.resolve
    date-format: CustomDateFormat
    number-format: CustomNumberFormat
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.libraryPackage, 'package:custom_l10n/custom_l10n.dart');
      expect(options.libraryAlias, 'custom_l10n');
      expect(options.localizationRuntime.package, 'package:custom_l10n/custom_l10n.dart');
      expect(options.localizationRuntime.alias, 'custom_l10n');
      expect(options.localizationRuntime.symbols.canonicalizedLocale, 'CustomLocale.canonicalize');
      expect(options.localizationRuntime.symbols.pluralLogic, 'CustomPlural.resolve');
      expect(options.localizationRuntime.symbols.selectLogic, 'CustomSelect.resolve');
      expect(options.localizationRuntime.symbols.dateFormat, 'CustomDateFormat');
      expect(options.localizationRuntime.symbols.numberFormat, 'CustomNumberFormat');
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions parses localization-runtime with kebab-case symbols',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  package: package:custom_l10n/custom_l10n.dart
  alias: custom_l10n
  symbols:
    canonicalized-locale: CustomLocale.canonicalize
    plural-logic: CustomPlural.resolve
    select-logic: CustomSelect.resolve
    date-format: CustomDateFormat
    number-format: CustomNumberFormat
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.libraryPackage, 'package:custom_l10n/custom_l10n.dart');
      expect(options.libraryAlias, 'custom_l10n');
      expect(options.localizationRuntime.package, 'package:custom_l10n/custom_l10n.dart');
      expect(options.localizationRuntime.alias, 'custom_l10n');
      expect(options.localizationRuntime.symbols.canonicalizedLocale, 'CustomLocale.canonicalize');
      expect(options.localizationRuntime.symbols.pluralLogic, 'CustomPlural.resolve');
      expect(options.localizationRuntime.symbols.selectLogic, 'CustomSelect.resolve');
      expect(options.localizationRuntime.symbols.dateFormat, 'CustomDateFormat');
      expect(options.localizationRuntime.symbols.numberFormat, 'CustomNumberFormat');
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions handles camelCase symbol keys and apis key',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  apis:
    canonicalizedLocale: CustomLocale.canonicalize
    pluralLogic: CustomPlural.resolve
    selectLogic: CustomSelect.resolve
    dateFormat: CustomDateFormat
    numberFormat: CustomNumberFormat
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.localizationRuntime.symbols.canonicalizedLocale, 'CustomLocale.canonicalize');
      expect(options.localizationRuntime.symbols.pluralLogic, 'CustomPlural.resolve');
      expect(options.localizationRuntime.symbols.selectLogic, 'CustomSelect.resolve');
      expect(options.localizationRuntime.symbols.dateFormat, 'CustomDateFormat');
      expect(options.localizationRuntime.symbols.numberFormat, 'CustomNumberFormat');
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions handles partial symbols and falls back to defaults',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  symbols:
    date-format: MyDateFormatter
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.localizationRuntime.symbols.dateFormat, 'MyDateFormatter');
      expect(
        options.localizationRuntime.symbols.canonicalizedLocale,
        LocalizationRuntimeSymbols.defaultCanonicalizedLocale,
      );
      expect(
        options.localizationRuntime.symbols.pluralLogic,
        LocalizationRuntimeSymbols.defaultPluralLogic,
      );
      expect(
        options.localizationRuntime.symbols.selectLogic,
        LocalizationRuntimeSymbols.defaultSelectLogic,
      );
      expect(
        options.localizationRuntime.symbols.numberFormat,
        LocalizationRuntimeSymbols.defaultNumberFormat,
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid symbol key in localization-runtime',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  symbols:
    unknown-symbol: Something
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains(
              'Invalid symbol key "unknown-symbol" specified in "localization-runtime.symbols".',
            ),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws when localization-library is used',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-library:
  package: package:core/core.dart
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains(
              'The "localization-library" configuration key is not supported. Use "localization-runtime" instead.',
            ),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid symbol identifier in localization-runtime',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  symbols:
    plural-logic: 123InvalidIdentifier
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid Dart symbol reference.'),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws when symbols is not a map in localization-runtime',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  symbols: not-a-map
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Expected "localization-runtime.symbols" to be a map.'),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid symbol identifier in date-format',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
localization-runtime:
  symbols:
    date-format: 123invalid..symbol
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('is not a valid Dart symbol reference.'),
          ),
        ),
      );
    },
  );

  testWithoutContext('parseLocalizationsOptions defaults ignoreArbKeys to empty', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File configFile = fileSystem.file('l10n.yaml')
      ..writeAsStringSync('''
arb-dir: lib/l10n
''');

    final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
      file: configFile,
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      defaultArbDir: fileSystem.path.join('lib', 'l10n'),
    );

    expect(options.ignoreArbKeys, isEmpty);
  });

  testWithoutContext(
    'parseLocalizationsOptions handles ignore-arb-keys as list of strings',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
ignore-arb-keys:
  - someKey
  - anotherKey
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.ignoreArbKeys, equals(<String>{'someKey', 'anotherKey'}));
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws when ignore-arb-keys has non-string or empty item',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
ignore-arb-keys:
  - '  '
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Expected "ignore-arb-keys" entries to be non-empty strings.'),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws when ignore-arb-keys is not a list',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
ignore-arb-keys:
  someKey: true
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains('Expected "ignore-arb-keys" to be a list of ARB keys.'),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions default arb-conflict-resolution is error',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
arb-dir: lib/l10n
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.arbConflictResolution, ArbConflictResolution.error);
    },
  );

  testWithoutContext('parseLocalizationsOptions parses arb-conflict-resolution values', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();

    for (final MapEntry<String, ArbConflictResolution> entry in <String, ArbConflictResolution>{
      'error': ArbConflictResolution.error,
      'first': ArbConflictResolution.first,
      'last': ArbConflictResolution.last,
    }.entries) {
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
arb-conflict-resolution: ${entry.key}
''');

      final LocalizationOptions options = parseLocalizationsOptionsFromYAML(
        file: configFile,
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
        defaultArbDir: fileSystem.path.join('lib', 'l10n'),
      );

      expect(options.arbConflictResolution, entry.value);
    }
  });

  testWithoutContext(
    'parseLocalizationsOptions throws on invalid arb-conflict-resolution value',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
arb-conflict-resolution: merge
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains(
              'Invalid "arb-conflict-resolution" value: "merge". Supported values are "error", "first", and "last".',
            ),
          ),
        ),
      );
    },
  );

  testWithoutContext(
    'parseLocalizationsOptions throws when arb-conflict-resolution is not a string',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final File configFile = fileSystem.file('l10n.yaml')
        ..writeAsStringSync('''
arb-conflict-resolution: 123
''');

      expect(
        () => parseLocalizationsOptionsFromYAML(
          file: configFile,
          logger: BufferLogger.test(),
          fileSystem: fileSystem,
          defaultArbDir: fileSystem.path.join('lib', 'l10n'),
        ),
        throwsA(
          isA<L10nException>().having(
            (L10nException e) => e.message,
            'message',
            contains(
              'Invalid "arb-conflict-resolution" value: "123". Supported values are "error", "first", and "last".',
            ),
          ),
        ),
      );
    },
  );
}
