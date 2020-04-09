// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

import '../../localization/gen_l10n.dart';
import '../../localization/gen_l10n_types.dart';
import '../../localization/localizations_utils.dart';

import '../common.dart';

final String defaultArbPathString = path.join('lib', 'l10n');
const String defaultTemplateArbFileName = 'app_en.arb';
const String defaultOutputFileString = 'output-localization-file';
const String defaultClassNameString = 'AppLocalizations';
const String singleMessageArbFileString = '''
{
  "title": "Title",
  "@title": {
    "description": "Title for the application"
  }
}''';
const String twoMessageArbFileString = '''
{
  "title": "Title",
  "@title": {
    "description": "Title for the application"
  },
  "subtitle": "Subtitle",
  "@subtitle": {
    "description": "Subtitle for the application"
  }
}''';
const String esArbFileName = 'app_es.arb';
const String singleEsMessageArbFileString = '''
{
  "title": "Título"
}''';
const String singleZhMessageArbFileString = '''
{
  "title": "标题"
}''';

void _standardFlutterDirectoryL10nSetup(FileSystem fs) {
  final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
    ..createSync(recursive: true);
  l10nDirectory.childFile(defaultTemplateArbFileName)
    .writeAsStringSync(singleMessageArbFileString);
  l10nDirectory.childFile(esArbFileName)
    .writeAsStringSync(singleEsMessageArbFileString);
}

void main() {
  MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem(
      style: Platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix
    );
    precacheLanguageAndRegionTags();
  });

  group('Setters', () {
    test('setL10nDirectory fails if the directory does not exist', () {
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setL10nDirectory('lib');
      } on FileSystemException catch (e) {
        expect(e.message, contains('Make sure that the correct path was provided'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setL10nDirectory should fail if the '
        'directory does not exist.'
      );
    });

    test('setL10nDirectory fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setL10nDirectory(null);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setL10nDirectory should fail if the '
        'the input string is null.'
      );
    });

    test('setTemplateArbFile fails if l10nDirectory is null', () {
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setTemplateArbFile(defaultTemplateArbFileName);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setTemplateArbFile should fail if the '
        'the l10nDirectory is null.'
      );
    });

    test('setTemplateArbFile fails if templateArbFileName is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setTemplateArbFile(null);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setTemplateArbFile should fail if the '
        'the l10nDirectory is null.'
      );
    });

    test('setTemplateArbFile fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setTemplateArbFile(null);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setTemplateArbFile should fail if the '
        'the input string is null.'
      );
    });

    test('setOutputFile fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setOutputFile(null);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setOutputFile should fail if the '
        'the input string is null.'
      );
    });

    test('setting className fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.className = null;
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.className should fail if the '
        'the input string is null.'
      );
    });

    group('className should only take valid Dart class names', () {
      LocalizationsGenerator generator;
      setUp(() {
        _standardFlutterDirectoryL10nSetup(fs);
        generator = LocalizationsGenerator(fs);
        try {
          generator.setL10nDirectory(defaultArbPathString);
          generator.setTemplateArbFile(defaultTemplateArbFileName);
          generator.setOutputFile(defaultOutputFileString);
        } on L10nException catch (e) {
          throw TestFailure('Unexpected failure during test setup: ${e.message}');
        }
      });

      test('fails on string with spaces', () {
        try {
          generator.className = 'String with spaces';
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid public Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.className should fail if the '
          'the input string is not a valid Dart class name.'
        );
      });

      test('fails on non-alphanumeric symbols', () {
        try {
          generator.className = 'TestClass@123';
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid public Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.className should fail if the '
          'the input string is not a valid public Dart class name.'
        );
      });

      test('fails on camel-case', () {
        try {
          generator.className = 'camelCaseClassName';
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid public Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.className should fail if the '
          'the input string is not a valid public Dart class name.'
        );
      });

      test('fails when starting with a number', () {
        try {
          generator.className = '123ClassName';
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid public Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.className should fail if the '
          'the input string is not a valid public Dart class name.'
        );
      });
    });
  });

  test('correctly adds a headerString when it is set', () {
    _standardFlutterDirectoryL10nSetup(fs);

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator.initialize(
        l10nDirectoryPath: defaultArbPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        headerString: '/// Sample header',
      );
    } on L10nException catch (e) {
      fail('Setting a header through a String should not fail: \n${e.message}');
    }

    expect(generator.header, '/// Sample header');
  });

  test('correctly adds a headerFile when it is set', () {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString)
      ..childFile('header.txt').writeAsStringSync('/// Sample header in a text file');

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator.initialize(
        l10nDirectoryPath: defaultArbPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        headerFile: 'header.txt',
      );
    } on L10nException catch (e) {
      fail('Setting a header through a file should not fail: \n${e.message}');
    }

    expect(generator.header, '/// Sample header in a text file');
  });

  test('correctly creates an unimplemented messages file', () {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(twoMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString);

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator
        ..initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        )
        ..loadResources()
        ..generateCode()
        ..outputUnimplementedMessages(path.join('lib', 'l10n', 'unimplemented_message_translations.json'));
    } on L10nException catch (e) {
      fail('Generating output should not fail: \n${e.message}');
    }

    final File unimplementedOutputFile = fs.file(
      path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
    );
    final String unimplementedOutputString = unimplementedOutputFile.readAsStringSync();
    try {
      // Since ARB file is essentially JSON, decoding it should not fail.
      json.decode(unimplementedOutputString);
    } on Exception {
      fail('Parsing arb file should not fail');
    }
    expect(unimplementedOutputString, contains('es'));
    expect(unimplementedOutputString, contains('subtitle'));
  });

  test('setting both a headerString and a headerFile should fail', () {
    fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true)
      ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
      ..childFile(esArbFileName).writeAsStringSync(singleEsMessageArbFileString)
      ..childFile('header.txt').writeAsStringSync('/// Sample header in a text file');

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator.initialize(
        l10nDirectoryPath: defaultArbPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        headerString: '/// Sample header for localizations file.',
        headerFile: 'header.txt',
      );
    } on L10nException catch (e) {
      expect(e.message, contains('Cannot accept both header and header file arguments'));
      return;
    }

    fail('Setting both headerFile and headerString should fail');
  });

  test('setting a headerFile that does not exist should fail', () {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile(defaultTemplateArbFileName)
      .writeAsStringSync(singleMessageArbFileString);
    l10nDirectory.childFile(esArbFileName)
      .writeAsStringSync(singleEsMessageArbFileString);
    l10nDirectory.childFile('header.txt')
      .writeAsStringSync('/// Sample header in a text file');

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator.initialize(
        l10nDirectoryPath: defaultArbPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        headerFile: 'header.tx', // Intentionally spelled incorrectly
      );
    } on L10nException catch (e) {
      expect(e.message, contains('Failed to read header file'));
      return;
    }

    fail('Setting headerFile that does not exist should fail');
  });

  group('loadResources', () {
    test('correctly initializes supportedLocales and supportedLanguageCodes properties', () {
      _standardFlutterDirectoryL10nSetup(fs);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('es')), true);
    });

    test('correctly sorts supportedLocales and supportedLanguageCodes alphabetically', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      // Write files in non-alphabetical order so that read performs in that order
      l10nDirectory.childFile('app_zh.arb')
        .writeAsStringSync(singleZhMessageArbFileString);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(singleEsMessageArbFileString);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      expect(generator.supportedLocales.first, LocaleInfo.fromString('en'));
      expect(generator.supportedLocales.elementAt(1), LocaleInfo.fromString('es'));
      expect(generator.supportedLocales.elementAt(2), LocaleInfo.fromString('zh'));
    });

    test('adds preferred locales to the top of supportedLocales and supportedLanguageCodes', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(singleEsMessageArbFileString);
      l10nDirectory.childFile('app_zh.arb')
        .writeAsStringSync(singleZhMessageArbFileString);

      const String preferredSupportedLocaleString = '["zh", "es"]';
      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          preferredSupportedLocaleString: preferredSupportedLocaleString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      expect(generator.supportedLocales.first, LocaleInfo.fromString('zh'));
      expect(generator.supportedLocales.elementAt(1), LocaleInfo.fromString('es'));
      expect(generator.supportedLocales.elementAt(2), LocaleInfo.fromString('en'));
    });

    test(
      'throws an error attempting to add preferred locales '
      'with incorrect runtime type',
      () {
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile('app_en.arb')
          .writeAsStringSync(singleMessageArbFileString);
        l10nDirectory.childFile('app_es.arb')
          .writeAsStringSync(singleEsMessageArbFileString);
        l10nDirectory.childFile('app_zh.arb')
          .writeAsStringSync(singleZhMessageArbFileString);

        const String preferredSupportedLocaleString = '[44, "en"]';
        LocalizationsGenerator generator;
        try {
          generator = LocalizationsGenerator(fs);
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            preferredSupportedLocaleString: preferredSupportedLocaleString,
          );
          generator.loadResources();
        } on L10nException catch (e) {
          expect(
            e.message,
            contains('Incorrect runtime type'),
          );
          return;
        }

        fail(
          'Should fail since an incorrect runtime type was used '
          'in the preferredSupportedLocales list.'
        );
      },
    );

    test(
      'throws an error attempting to add preferred locales '
      'when there is no corresponding arb file for that '
      'locale',
      () {
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile('app_en.arb')
          .writeAsStringSync(singleMessageArbFileString);
        l10nDirectory.childFile('app_es.arb')
          .writeAsStringSync(singleEsMessageArbFileString);
        l10nDirectory.childFile('app_zh.arb')
          .writeAsStringSync(singleZhMessageArbFileString);

        const String preferredSupportedLocaleString = '["am", "es"]';
        LocalizationsGenerator generator;
        try {
          generator = LocalizationsGenerator(fs);
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            preferredSupportedLocaleString: preferredSupportedLocaleString,
          );
          generator.loadResources();
        } on L10nException catch (e) {
          expect(
            e.message,
            contains("The preferred supported locale, 'am', cannot be added."),
          );
          return;
        }

        fail(
          'Should fail since an unsupported locale was added '
          'to the preferredSupportedLocales list.'
        );
      },
    );

    test('correctly sorts arbPathString alphabetically', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      // Write files in non-alphabetical order so that read performs in that order
      l10nDirectory.childFile('app_zh.arb')
        .writeAsStringSync(singleZhMessageArbFileString);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(singleEsMessageArbFileString);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      if (Platform.isWindows) {
        expect(generator.arbPathStrings.first, r'lib\l10n\app_en.arb');
        expect(generator.arbPathStrings.elementAt(1), r'lib\l10n\app_es.arb');
        expect(generator.arbPathStrings.elementAt(2), r'lib\l10n\app_zh.arb');
      } else {
        expect(generator.arbPathStrings.first, 'lib/l10n/app_en.arb');
        expect(generator.arbPathStrings.elementAt(1), 'lib/l10n/app_es.arb');
        expect(generator.arbPathStrings.elementAt(2), 'lib/l10n/app_zh.arb');
      }
    });

    test('correctly parses @@locale property in arb file', () {
      const String arbFileWithEnLocale = '''
{
  "@@locale": "en",
  "title": "Title",
  "@title": {
    "description": "Title for the application"
  }
}''';

      const String arbFileWithZhLocale = '''
{
  "@@locale": "zh",
  "title": "标题",
  "@title": {
    "description": "Title for the application"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('first_file.arb')
        .writeAsStringSync(arbFileWithEnLocale);
      l10nDirectory.childFile('second_file.arb')
        .writeAsStringSync(arbFileWithZhLocale);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: 'first_file.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('zh')), true);
    });

    test('correctly prioritizes @@locale property in arb file over filename', () {
      const String arbFileWithEnLocale = '''
{
  "@@locale": "en",
  "title": "Stocks",
  "@title": {
    "description": "Title for the Stocks application"
  }
}''';

      const String arbFileWithZhLocale = '''
{
  "@@locale": "zh",
  "title": "标题",
  "@title": {
    "description": "Title for the Stocks application"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_es.arb')
        .writeAsStringSync(arbFileWithEnLocale);
      l10nDirectory.childFile('app_am.arb')
        .writeAsStringSync(arbFileWithZhLocale);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: 'app_es.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      // @@locale property should hold higher priority
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('zh')), true);
      // filename should not be used since @@locale is specified
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('es')), false);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('am')), false);
    });

    test("throws when arb file's locale could not be determined", () {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true)
        ..childFile('app.arb')
        .writeAsStringSync(singleMessageArbFileString);
      try {
        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: 'app.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        expect(e.message, contains('locale could not be determined'));
        return;
      }
      fail(
        'Since locale is not specified, setting languages and locales '
        'should fail'
      );
    });
    test('throws when the same locale is detected more than once', () {
      const String secondMessageArbFileString = '''
{
  "market": "MARKET",
  "@market": {
    "description": "Label for the Market tab"
  }
}''';

      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en.arb')
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile('app2_en.arb')
        .writeAsStringSync(secondMessageArbFileString);

      try {
        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: 'app_en.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        expect(e.message, contains("Multiple arb files with the same 'en' locale detected"));
        return;
      }

      fail(
        'Since en locale is specified twice, setting languages and locales '
        'should fail'
      );
    });

    test('throws when the base locale does not exist', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en_US.arb')
        .writeAsStringSync(singleMessageArbFileString);

      try {
        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: 'app_en_US.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        expect(e.message, contains('Arb file for a fallback, en, does not exist'));
        return;
      }

      fail(
        'Since en_US.arb is specified, but en.arb is not, '
        'the tool should throw an error.'
      );
    });
  });

  group('generateCode', () {
    test('should generate a file per language', () {
      const String singleEnCaMessageArbFileString = '''
{
  "title": "Canadian Title"
}''';
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_en_CA.arb').writeAsStringSync(singleEnCaMessageArbFileString);

      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
        generator.writeOutputFile();
      } on Exception catch (e) {
        fail('Generating output files should not fail: $e');
      }

      expect(fs.isFileSync(path.join('lib', 'l10n', 'output-localization-file_en.dart')), true);
      expect(fs.isFileSync(path.join('lib', 'l10n', 'output-localization-file_en_US.dart')), false);

      final String englishLocalizationsFile = fs.file(
        path.join('lib', 'l10n', 'output-localization-file_en.dart')
      ).readAsStringSync();
      expect(englishLocalizationsFile, contains('class AppLocalizationsEnCa extends AppLocalizationsEn'));
      expect(englishLocalizationsFile, contains('class AppLocalizationsEn extends AppLocalizations'));
    });

    group('DateTime tests', () {
      test('throws an exception when improperly formatted date is passed in', () {
        const String singleDateMessageArbFileString = '''
{
  "@@locale": "en",
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
      "description": "The first day of spring",
      "placeholders": {
          "springStartDate": {
              "type": "DateTime",
              "format": "asdf"
          }
      }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(singleDateMessageArbFileString);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('asdf'));
          expect(e.message, contains('springStartDate'));
          expect(e.message, contains('does not have a corresponding DateFormat'));
          return;
        }

        fail('Improper date formatting should throw an exception');
      });

      test('throws an exception when no format attribute is passed in', () {
        const String singleDateMessageArbFileString = '''
{
  "springBegins": "Spring begins on {springStartDate}",
  "@springBegins": {
      "description": "The first day of spring",
      "placeholders": {
          "springStartDate": {
              "type": "DateTime"
          }
      }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(singleDateMessageArbFileString);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('the "format" attribute needs to be set'));
          return;
        }

        fail('Improper date formatting should throw an exception');
      });

      test('throws an exception when improperly formatted number is passed in', () {
        const String singleDateMessageArbFileString = '''
{
  "courseCompletion": "You have completed {progress} of the course.",
  "@courseCompletion": {
    "description": "The amount of progress the student has made in their class.",
    "placeholders": {
      "progress": {
        "type": "double",
        "format": "asdf"
      }
    }
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(singleDateMessageArbFileString);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('asdf'));
          expect(e.message, contains('progress'));
          expect(e.message, contains('does not have a corresponding NumberFormat'));
          return;
        }

        fail('Improper date formatting should throw an exception');
      });
    });

    group('plural messages', () {
      test('should throw attempting to generate a plural message without placeholders', () {
        const String pluralMessageWithoutPlaceholdersAttribute = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "description": "Improperly formatted since it has no placeholder attribute."
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithoutPlaceholdersAttribute);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('Check to see if the plural message is in the proper ICU syntax format'));
          return;
        }
        fail('Generating class methods without placeholders should not succeed');
      });

      test('should throw attempting to generate a plural message with an empty placeholders map', () {
        const String pluralMessageWithEmptyPlaceholdersMap = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "description": "Improperly formatted since it has no placeholder attribute.",
    "placeholders": {}
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithEmptyPlaceholdersMap);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('Check to see if the plural message is in the proper ICU syntax format'));
          return;
        }
        fail('Generating class methods without placeholders should not succeed');
      });

      test('should throw attempting to generate a plural message with no resource attributes', () {
        const String pluralMessageWithoutResourceAttributes = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}"
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithoutResourceAttributes);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('Resource attribute "@helloWorlds" was not found'));
          return;
        }
        fail('Generating plural class method without resource attributes should not succeed');
      });

      test('should throw attempting to generate a plural message with incorrect format for placeholders', () {
        const String pluralMessageWithIncorrectPlaceholderFormat = '''
{
  "helloWorlds": "{count,plural, =0{Hello}=1{Hello World}=2{Hello two worlds}few{Hello {count} worlds}many{Hello all {count} worlds}other{Hello other {count} worlds}}",
  "@helloWorlds": {
    "placeholders": "Incorrectly a string, should be a map."
  }
}''';

        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(pluralMessageWithIncorrectPlaceholderFormat);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('is not properly formatted'));
          expect(e.message, contains('Ensure that it is a map with string valued keys'));
          return;
        }
        fail('Generating class methods with incorrect placeholder format should not succeed');
      });
    });

    test('should throw when failing to parse the arb file', () {
      const String arbFileWithTrailingComma = '''
{
  "title": "Stocks",
  "@title": {
    "description": "Title for the Stocks application"
  },
}''';
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(arbFileWithTrailingComma);

      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
        generator.generateCode();
      } on FormatException catch (e) {
        expect(e.message, contains('Unexpected character'));
        return;
      }

      fail(
        'should fail with a FormatException due to a trailing comma in the '
        'arb file.'
      );
    });

    test('should throw when resource is missing resource attribute', () {
      const String arbFileWithMissingResourceAttribute = '''
{
  "title": "Stocks"
}''';
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(arbFileWithMissingResourceAttribute);

      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.initialize(
          l10nDirectoryPath: defaultArbPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
        generator.generateCode();
      } on L10nException catch (e) {
        expect(e.message, contains('Resource attribute "@title" was not found'));
        return;
      }

      fail(
        'should fail with a FormatException due to a trailing comma in the '
        'arb file.'
      );
    });

    group('checks for method/getter formatting', () {
      test('cannot contain non-alphanumeric symbols', () {
        const String nonAlphaNumericArbFile = '''
{
  "title!!": "Stocks",
  "@title!!": {
    "description": "Title for the Stocks application"
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(nonAlphaNumericArbFile);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid ARB resource name'));
          return;
        }

        fail('should fail due to non-alphanumeric character.');
      });

      test('must start with lowercase character', () {
        const String nonAlphaNumericArbFile = '''
{
  "Title": "Stocks",
  "@Title": {
    "description": "Title for the Stocks application"
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(nonAlphaNumericArbFile);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid ARB resource name'));
          return;
        }

        fail('should fail since key starts with a non-lowercase.');
      });

      test('cannot start with a number', () {
        const String nonAlphaNumericArbFile = '''
{
  "123title": "Stocks",
  "@123title": {
    "description": "Title for the Stocks application"
  }
}''';
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile(defaultTemplateArbFileName)
          .writeAsStringSync(nonAlphaNumericArbFile);

        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.initialize(
            l10nDirectoryPath: defaultArbPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.generateCode();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid ARB resource name'));
          return;
        }

        fail('should fail since key starts with a number.');
      });
    });
  });
}
