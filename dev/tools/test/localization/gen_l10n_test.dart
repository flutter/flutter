// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

import '../../localization/gen_l10n.dart';
import '../../localization/gen_l10n_types.dart';
import '../../localization/localizations_utils.dart';

import '../common.dart';

final String defaultArbPathString = path.join('lib', 'l10n');
const String defaultTemplateArbFileName = 'app_en_US.arb';
const String defaultOutputFileString = 'output-localization-file';
const String defaultClassNameString = 'AppLocalizations';
const String singleMessageArbFileString = '''{
  "title": "Title",
  "@title": {
    "description": "Title for the application"
  }
}''';

const String esArbFileName = 'app_es.arb';
const String singleEsMessageArbFileString = '''{
  "title": "Título"
}''';
const String singleZhMessageArbFileString = '''{
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

  group('parseArbFiles', () {
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n$e');
      }

      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en_US')), true);
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
      l10nDirectory.childFile('app_en_US.arb')
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n$e');
      }

      expect(generator.supportedLocales.first, LocaleInfo.fromString('en_US'));
      expect(generator.supportedLocales.elementAt(1), LocaleInfo.fromString('es'));
      expect(generator.supportedLocales.elementAt(2), LocaleInfo.fromString('zh'));
    });

    test('adds preferred locales to the top of supportedLocales and supportedLanguageCodes', () {
      final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile('app_en_US.arb')
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n$e');
      }

      expect(generator.supportedLocales.first, LocaleInfo.fromString('zh'));
      expect(generator.supportedLocales.elementAt(1), LocaleInfo.fromString('es'));
      expect(generator.supportedLocales.elementAt(2), LocaleInfo.fromString('en_US'));
    });

    test(
      'throws an error attempting to add preferred locales '
      'with incorrect runtime type',
      () {
        final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
          ..createSync(recursive: true);
        l10nDirectory.childFile('app_en_US.arb')
          .writeAsStringSync(singleMessageArbFileString);
        l10nDirectory.childFile('app_es.arb')
          .writeAsStringSync(singleEsMessageArbFileString);
        l10nDirectory.childFile('app_zh.arb')
          .writeAsStringSync(singleZhMessageArbFileString);

        const String preferredSupportedLocaleString = '[44, "en_US"]';
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
          generator.parseArbFiles();
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
        l10nDirectory.childFile('app_en_US.arb')
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
          generator.parseArbFiles();
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
      l10nDirectory.childFile('app_en_US.arb')
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n$e');
      }

      if (Platform.isWindows) {
        expect(generator.arbPathStrings.first, r'lib\l10n\app_en_US.arb');
        expect(generator.arbPathStrings.elementAt(1), r'lib\l10n\app_es.arb');
        expect(generator.arbPathStrings.elementAt(2), r'lib\l10n\app_zh.arb');
      } else {
        expect(generator.arbPathStrings.first, 'lib/l10n/app_en_US.arb');
        expect(generator.arbPathStrings.elementAt(1), 'lib/l10n/app_es.arb');
        expect(generator.arbPathStrings.elementAt(2), 'lib/l10n/app_zh.arb');
      }
    });

    test('correctly parses @@locale property in arb file', () {
      const String arbFileWithEnLocale = '''{
  "@@locale": "en",
  "title": "Title",
  "@title": {
    "description": "Title for the application"
  }
}''';

      const String arbFileWithZhLocale = '''{
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n$e');
      }

      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('zh')), true);
    });

    test('correctly prioritizes @@locale property in arb file over filename', () {
      const String arbFileWithEnLocale = '''{
  "@@locale": "en",
  "title": "Stocks",
  "@title": {
    "description": "Title for the Stocks application"
  }
}''';

      const String arbFileWithZhLocale = '''{
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n$e');
      }

      // @@locale property should hold higher priority
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('en')), true);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('zh')), true);
      // filename should not be used since @@locale is specified
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('es')), false);
      expect(generator.supportedLocales.contains(LocaleInfo.fromString('am')), false);
    });

    test('throws when arb file\'s locale could not be determined', () {
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
        generator.parseArbFiles();
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
      const String secondMessageArbFileString = '''{
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
        generator.parseArbFiles();
      } on L10nException catch (e) {
        expect(e.message, contains('Multiple arb files with the same locale detected'));
        return;
      }

      fail(
        'Since en locale is specified twice, setting languages and locales '
        'should fail'
      );
    });
  });

  group('generateClassMethods', () {
    group('DateTime tests', () {
      test('throws an exception when improperly formatted date is passed in', () {
        const String singleDateMessageArbFileString = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('asdf'));
          expect(e.message, contains('springStartDate'));
          expect(e.message, contains('does not have a corresponding DateFormat'));
          return;
        }

        fail('Improper date formatting should throw an exception');
      });

      test('throws an exception when no format attribute is passed in', () {
        const String singleDateMessageArbFileString = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('the "format" attribute needs to be set'));
          return;
        }

        fail('Improper date formatting should throw an exception');
      });

      test('correctly generates simple message with date along with other placeholders', () {
        const String singleDateMessageArbFileString = '''{
  "springGreetings": "Since it's {springStartDate}, it's finally spring! {helloWorld}!",
  "@springGreetings": {
      "description": "A realization that it's finally the spring season, followed by a greeting.",
      "placeholders": {
          "springStartDate": {
              "type": "DateTime",
              "format": "yMMMMEEEEd"
          },
          "helloWorld": {}
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on Exception catch (e) {
          fail('Parsing template arb file should succeed: \n$e');
        }

        expect(generator.classMethods, isNotEmpty);
        expect(
          generator.classMethods.first,
          r'''
  String springGreetings(DateTime springStartDate, Object helloWorld) {
    final DateFormat springStartDateDateFormat = DateFormat.yMMMMEEEEd(_localeName);
    final String springStartDateString = springStartDateDateFormat.format(springStartDate);

    String springGreetings(Object springStartDate, Object helloWorld) {
      return Intl.message(
        "Since it's ${springStartDate}, it's finally spring! ${helloWorld}!",
        locale: _localeName,
        name: 'springGreetings',
        desc: "A realization that it's finally the spring season, followed by a greeting.",
        args: <Object>[springStartDate, helloWorld]
      );
    }
    return springGreetings(springStartDateString, helloWorld);
  }
''');
      });
    });

    group('Number tests', () {
      test('correctly adds optional named parameters to numbers', () {
        const Set<String> numberFormatsWithNamedParameters = <String>{
          'compact',
          'compactCurrency',
          'compactSimpleCurrency',
          'compactLong',
          'currency',
          'decimalPercentPattern',
          'simpleCurrency',
        };

        for (final String numberFormat in numberFormatsWithNamedParameters) {
          final String singleNumberMessage = '''{
  "courseCompletion": "You have completed {progress} of the course.",
  "@courseCompletion": {
    "description": "The amount of progress the student has made in their class.",
    "placeholders": {
      "progress": {
        "type": "double",
        "format": "$numberFormat",
        "optionalParameters": {
          "decimalDigits": 2
        }
      }
    }
  }
}''';
          final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
            ..createSync(recursive: true);
          l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(singleNumberMessage);

          final LocalizationsGenerator generator = LocalizationsGenerator(fs);
          try {
            generator.initialize(
              l10nDirectoryPath: defaultArbPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
            );
            generator.parseArbFiles();
            generator.generateClassMethods();
          } on Exception catch (e) {
            fail('Parsing template arb file should succeed: \n$e');
          }

          expect(generator.classMethods, isNotEmpty);
          expect(
            generator.classMethods.first,
            '''
  String courseCompletion(double progress) {
    final NumberFormat progressNumberFormat = NumberFormat.$numberFormat(
      locale: _localeName,
      decimalDigits: 2,
    );
    final String progressString = progressNumberFormat.format(progress);

    String courseCompletion(Object progress) {
      return Intl.message(
        'You have completed \${progress} of the course.',
        locale: _localeName,
        name: 'courseCompletion',
        desc: 'The amount of progress the student has made in their class.',
        args: <Object>[progress]
      );
    }
    return courseCompletion(progressString);
  }
''');}
      });

      test('correctly adds optional positional parameters to numbers', () {
        const Set<String> numberFormatsWithPositionalParameters = <String>{
          'decimalPattern',
          'percentPattern',
          'scientificPattern',
        };

        for (final String numberFormat in numberFormatsWithPositionalParameters) {
          final String singleNumberMessage = '''{
  "courseCompletion": "You have completed {progress} of the course.",
  "@courseCompletion": {
    "description": "The amount of progress the student has made in their class.",
    "placeholders": {
      "progress": {
        "type": "double",
        "format": "$numberFormat"
      }
    }
  }
}''';
          final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
            ..createSync(recursive: true);
          l10nDirectory.childFile(defaultTemplateArbFileName)
            .writeAsStringSync(singleNumberMessage);

          final LocalizationsGenerator generator = LocalizationsGenerator(fs);
          try {
            generator.initialize(
              l10nDirectoryPath: defaultArbPathString,
              templateArbFileName: defaultTemplateArbFileName,
              outputFileString: defaultOutputFileString,
              classNameString: defaultClassNameString,
            );
            generator.parseArbFiles();
            generator.generateClassMethods();
          } on Exception catch (e) {
            fail('Parsing template arb file should succeed: \n$e');
          }

          expect(generator.classMethods, isNotEmpty);
          expect(
            generator.classMethods.first,
            '''
  String courseCompletion(double progress) {
    final NumberFormat progressNumberFormat = NumberFormat.$numberFormat(_localeName);
    final String progressString = progressNumberFormat.format(progress);

    String courseCompletion(Object progress) {
      return Intl.message(
        'You have completed \${progress} of the course.',
        locale: _localeName,
        name: 'courseCompletion',
        desc: 'The amount of progress the student has made in their class.',
        args: <Object>[progress]
      );
    }
    return courseCompletion(progressString);
  }
''');
        }
      });

      test('throws an exception when improperly formatted number is passed in', () {
        const String singleDateMessageArbFileString = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
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
        const String pluralMessageWithoutPlaceholdersAttribute = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('Check to see if the plural message is in the proper ICU syntax format'));
          return;
        }
        fail('Generating class methods without placeholders should not succeed');
      });

      test('should throw attempting to generate a plural message with an empty placeholders map', () {
        const String pluralMessageWithEmptyPlaceholdersMap = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('Check to see if the plural message is in the proper ICU syntax format'));
          return;
        }
        fail('Generating class methods without placeholders should not succeed');
      });

      test('should throw attempting to generate a plural message with no resource attributes', () {
        const String pluralMessageWithoutResourceAttributes = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('Resource attribute "@helloWorlds" was not found'));
          return;
        }
        fail('Generating plural class method without resource attributes should not succeed');
      });

      test('should throw attempting to generate a plural message with incorrect format for placeholders', () {
        const String pluralMessageWithIncorrectPlaceholderFormat = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('is not properly formatted'));
          expect(e.message, contains('Ensure that it is a map with string valued keys'));
          return;
        }
        fail('Generating class methods with incorrect placeholder format should not succeed');
      });
    });

    test('should throw when failing to parse the arb file', () {
      const String arbFileWithTrailingComma = '''{
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
        generator.parseArbFiles();
        generator.generateClassMethods();
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
      const String arbFileWithMissingResourceAttribute = '''{
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
        generator.parseArbFiles();
        generator.generateClassMethods();
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
        const String nonAlphaNumericArbFile = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid key format'));
          return;
        }

        fail('should fail due to non-alphanumeric character.');
      });

      test('must start with lowercase character', () {
        const String nonAlphaNumericArbFile = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid key format'));
          return;
        }

        fail('should fail since key starts with a non-lowercase.');
      });

      test('cannot start with a number', () {
        const String nonAlphaNumericArbFile = '''{
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
          generator.parseArbFiles();
          generator.generateClassMethods();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid key format'));
          return;
        }

        fail('should fail since key starts with a number.');
      });
    });
  });

  group('generateString', () {
    test('handles simple string', () {
      expect(generateString('abc'), "'abc'");
    });
    test('handles string with quote', () {
      expect(generateString("ab'c"), '''"ab'c"''');
    });
    test('handles string with double quote', () {
      expect(generateString('ab"c'), """'ab"c'""");
    });
    test('handles string with both single and double quote', () {
      expect(generateString('''a'b"c'''), """'''a'b"c'''""");
    });
    test('handles string with a triple single quote and a double quote', () {
      expect(generateString("""a"b'''c"""), '''"""a"b\'''c"""''');
    });
    test('handles string with a triple double quote and a single quote', () {
      expect(generateString('''a'b"""c'''), """'''a'b\"""c'''""");
    });
    test('handles string with both triple single and triple double quote', () {
      expect(generateString('''a\'''\'''\''b"""c'''), """'a' "'''"  "'''" '''''b\"""c'''""");
    });
    test('handles dollar', () {
      expect(generateString(r'ab$c'), r"r'ab$c'");
    });
    test('handles back slash', () {
      expect(generateString(r'ab\c'), r"r'ab\c'");
    });
    test("doesn't support multiline strings", () {
      expect(() => generateString('ab\nc'), throwsA(isA<AssertionError>()));
    });
  });
}
