// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/localizations/gen_l10n.dart';
import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';
import 'package:flutter_tools/src/localizations/localizations_utils.dart';

import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf; // ignore: deprecated_member_use
// ignore: deprecated_member_use
export 'package:test_core/test_core.dart' hide TypeMatcher, isInstanceOf, test; // Defines a 'package:test' shim.

final String defaultL10nPathString = globals.fs.path.join('lib', 'l10n');
final String syntheticPackagePath = globals.fs.path.join('.dart_tool', 'flutter_gen', 'gen_l10n');
const String defaultTemplateArbFileName = 'app_en.arb';
const String defaultOutputFileString = 'output-localization-file.dart';
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
    test('setInputDirectory fails if the directory does not exist', () {
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setInputDirectory('lib');
      } on L10nException catch (e) {
        expect(e.message, contains('Make sure that the correct path was provided'));
        return;
      }

      fail(
        'LocalizationsGenerator.setInputDirectory should fail if the '
        'directory does not exist.'
      );
    });

    test('setInputDirectory fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setInputDirectory(null);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'LocalizationsGenerator.setInputDirectory should fail if the '
        'input string is null.'
      );
    });

    test(
      'setOutputDirectory fails if output string is null while not using the '
      'synthetic package option',
      () {
        _standardFlutterDirectoryL10nSetup(fs);
        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        try {
          generator.setOutputDirectory(
            outputPathString: null,
            useSyntheticPackage: false,
          );
        } on L10nException catch (e) {
          expect(e.message, contains('cannot be null'));
          return;
        }

        fail(
          'LocalizationsGenerator.setOutputDirectory should fail if the '
          'input string is null.'
        );
      },
    );

    test('setTemplateArbFile fails if inputDirectory is null', () {
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setTemplateArbFile(defaultTemplateArbFileName);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'LocalizationsGenerator.setTemplateArbFile should fail if the '
        'inputDirectory is not specified.'
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
        'LocalizationsGenerator.setTemplateArbFile should fail if the '
        'templateArbFileName passed in is null.'
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
        'LocalizationsGenerator.setTemplateArbFile should fail if the '
        'input string is null.'
      );
    });

    test('setBaseOutputFile fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setBaseOutputFile(null);
      } on L10nException catch (e) {
        expect(e.message, contains('cannot be null'));
        return;
      }

      fail(
        'LocalizationsGenerator.setBaseOutputFile should fail if the '
        'input string is null.'
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
        'LocalizationsGenerator.className should fail if the '
        'input string is null.'
      );
    });

    test('sets absolute path of the target Flutter project', () {
      // Set up project directory.
      final Directory l10nDirectory = fs.currentDirectory
        .childDirectory('absolute')
        .childDirectory('path')
        .childDirectory('to')
        .childDirectory('flutter_project')
        .childDirectory('lib')
        .childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      // Run localizations generator in specified absolute path.
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      final String flutterProjectPath = fs.path.join('absolute', 'path', 'to', 'flutter_project');
      try {
        generator.initialize(
          projectPathString: flutterProjectPath,
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
        generator.writeOutputFiles();
      } on L10nException catch (e) {
        throw TestFailure('Unexpected failure during test setup: ${e.message}');
      } on Exception catch (e) {
        throw TestFailure('Unexpected failure during test setup: $e');
      }

      // Output files should be generated in the provided absolute path.
      expect(
        fs.isFileSync(fs.path.join(
          flutterProjectPath,
          '.dart_tool',
          'flutter_gen',
          'gen_l10n',
          'output-localization-file_en.dart',
        )),
        true,
      );
      expect(
        fs.isFileSync(fs.path.join(
          flutterProjectPath,
          '.dart_tool',
          'flutter_gen',
          'gen_l10n',
          'output-localization-file_es.dart',
        )),
        true,
      );
    });

    test('throws error when directory at absolute path does not exist', () {
      // Set up project directory.
      final Directory l10nDirectory = fs.currentDirectory
        .childDirectory('lib')
        .childDirectory('l10n')
        ..createSync(recursive: true);
      l10nDirectory.childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory.childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      // Project path should be intentionally a directory that does not exist.
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.initialize(
          projectPathString: 'absolute/path/to/flutter_project',
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
      } on L10nException catch (e) {
        expect(e.message, contains('Directory does not exist'));
        return;
      }

      fail(
        'An exception should be thrown when the directory '
        'specified in projectPathString does not exist.'
      );
    });

    group('className should only take valid Dart class names', () {
      LocalizationsGenerator generator;
      setUp(() {
        _standardFlutterDirectoryL10nSetup(fs);
        generator = LocalizationsGenerator(fs);
        try {
          generator.setInputDirectory(defaultL10nPathString);
          generator.setOutputDirectory();
          generator.setTemplateArbFile(defaultTemplateArbFileName);
          generator.setBaseOutputFile(defaultOutputFileString);
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
          'LocalizationsGenerator.className should fail if the '
          'input string is not a valid Dart class name.'
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
          'LocalizationsGenerator.className should fail if the '
          'input string is not a valid public Dart class name.'
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
          'LocalizationsGenerator.className should fail if the '
          'input string is not a valid public Dart class name.'
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
          'LocalizationsGenerator.className should fail if the '
          'input string is not a valid public Dart class name.'
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
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
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
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
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

  test('sets templateArbFileName with more than one underscore correctly', () {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile('app_localizations_en.arb')
      .writeAsStringSync(singleMessageArbFileString);
    l10nDirectory.childFile('app_localizations_es.arb')
      .writeAsStringSync(singleEsMessageArbFileString);
    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator
        ..initialize(
          inputPathString: defaultL10nPathString,
          templateArbFileName: 'app_localizations_en.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        )
        ..loadResources()
        ..writeOutputFiles();
    } on L10nException catch (e) {
      fail('Generating output should not fail: \n${e.message}');
    }

    final Directory outputDirectory = fs.directory(syntheticPackagePath);
    expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
    expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
    expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
  });

  test('filenames with invalid locales should not be recognized', () {
    final Directory l10nDirectory = fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
      ..createSync(recursive: true);
    l10nDirectory.childFile('app_localizations_en.arb')
      .writeAsStringSync(singleMessageArbFileString);
    l10nDirectory.childFile('app_localizations_en_CA_foo.arb')
      .writeAsStringSync(singleMessageArbFileString);
    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator
        ..initialize(
          inputPathString: defaultL10nPathString,
          templateArbFileName: 'app_localizations_en.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        )
        ..loadResources();
    } on L10nException catch (e) {
      expect(e.message, contains('The following .arb file\'s locale could not be determined'));
      return;
    }

    fail('Using app_en_CA_foo.arb should fail as it is not a valid locale.');
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        )
        ..loadResources()
        ..writeOutputFiles()
        ..outputUnimplementedMessages(
          fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
          BufferLogger.test(),
        );
    } on L10nException catch (e) {
      fail('Generating output should not fail: \n${e.message}');
    }

    final File unimplementedOutputFile = fs.file(
      fs.path.join('lib', 'l10n', 'unimplemented_message_translations.json'),
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

  test(
    'uses inputPathString as outputPathString when the outputPathString is '
    'null while not using the synthetic package option',
    () {
      _standardFlutterDirectoryL10nSetup(fs);
      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator
          ..initialize(
            inputPathString: defaultL10nPathString,
            // outputPathString is intentionally not defined
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            useSyntheticPackage: false,
          )
          ..loadResources()
          ..writeOutputFiles();
      } on L10nException catch (e) {
        fail('Generating output should not fail: \n${e.message}');
      }

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n');
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
    },
  );

  test(
    'correctly generates output files in non-default output directory if it '
    'already exists while not using the synthetic package option',
    () {
      final Directory l10nDirectory = fs.currentDirectory
        .childDirectory('lib')
        .childDirectory('l10n')
        ..createSync(recursive: true);
      // Create the directory 'lib/l10n/output'.
      l10nDirectory.childDirectory('output');

      l10nDirectory
        .childFile(defaultTemplateArbFileName)
        .writeAsStringSync(singleMessageArbFileString);
      l10nDirectory
        .childFile(esArbFileName)
        .writeAsStringSync(singleEsMessageArbFileString);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator
          ..initialize(
            inputPathString: defaultL10nPathString,
            outputPathString: fs.path.join('lib', 'l10n', 'output'),
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            useSyntheticPackage: false,
          )
          ..loadResources()
          ..writeOutputFiles();
      } on L10nException catch (e) {
        fail('Generating output should not fail: \n${e.message}');
      }

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n').childDirectory('output');
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
    },
  );

  test(
    'correctly creates output directory if it does not exist and writes files '
    'in it while not using the synthetic package option',
    () {
      _standardFlutterDirectoryL10nSetup(fs);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator
          ..initialize(
            inputPathString: defaultL10nPathString,
            outputPathString: fs.path.join('lib', 'l10n', 'output'),
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            useSyntheticPackage: false,
          )
          ..loadResources()
          ..writeOutputFiles();
      } on L10nException catch (e) {
        fail('Generating output should not fail: \n${e.message}');
      }

      final Directory outputDirectory = fs.directory('lib').childDirectory('l10n').childDirectory('output');
      expect(outputDirectory.existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_en.dart').existsSync(), isTrue);
      expect(outputDirectory.childFile('output-localization-file_es.dart').existsSync(), isTrue);
    },
  );

  test('creates list of inputs and outputs when file path is specified', () {
    _standardFlutterDirectoryL10nSetup(fs);

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator
        ..initialize(
          inputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          inputsAndOutputsListPath: syntheticPackagePath,
        )
        ..loadResources()
        ..writeOutputFiles();
    } on L10nException catch (e) {
      fail('Generating output should not fail: \n${e.message}');
    }

    final File inputsAndOutputsList = fs.file(
      fs.path.join(syntheticPackagePath, 'gen_l10n_inputs_and_outputs.json'),
    );
    expect(inputsAndOutputsList.existsSync(), isTrue);

    final Map<String, dynamic> jsonResult = json.decode(inputsAndOutputsList.readAsStringSync()) as Map<String, dynamic>;
    expect(jsonResult.containsKey('inputs'), isTrue);
    final List<dynamic> inputList = jsonResult['inputs'] as List<dynamic>;
    expect(inputList, contains(fs.path.absolute('lib', 'l10n', 'app_en.arb')));
    expect(inputList, contains(fs.path.absolute('lib', 'l10n', 'app_es.arb')));

    expect(jsonResult.containsKey('outputs'), isTrue);
    final List<dynamic> outputList = jsonResult['outputs'] as List<dynamic>;
    expect(outputList, contains(fs.path.absolute(syntheticPackagePath, 'output-localization-file.dart')));
    expect(outputList, contains(fs.path.absolute(syntheticPackagePath, 'output-localization-file_en.dart')));
    expect(outputList, contains(fs.path.absolute(syntheticPackagePath, 'output-localization-file_es.dart')));
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
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
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
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
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

  test('setting useDefferedLoading to null should fail', () {
    _standardFlutterDirectoryL10nSetup(fs);

    LocalizationsGenerator generator;
    try {
      generator = LocalizationsGenerator(fs);
      generator.initialize(
        inputPathString: defaultL10nPathString,
        outputPathString: defaultL10nPathString,
        templateArbFileName: defaultTemplateArbFileName,
        outputFileString: defaultOutputFileString,
        classNameString: defaultClassNameString,
        headerString: '/// Sample header',
        useDeferredLoading: null,
      );
    } on L10nException catch (e) {
      expect(e.message, contains('useDeferredLoading argument cannot be null.'));
      return;
    }

    fail('Setting useDefferedLoading to null should fail');
  });

  group('loadResources', () {
    test('correctly initializes supportedLocales and supportedLanguageCodes properties', () {
      _standardFlutterDirectoryL10nSetup(fs);

      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
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

      const List<String> preferredSupportedLocale = <String>['zh', 'es'];
      LocalizationsGenerator generator;
      try {
        generator = LocalizationsGenerator(fs);
        generator.initialize(
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          preferredSupportedLocale: preferredSupportedLocale,
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

        const List<String> preferredSupportedLocale = <String>['am', 'es'];
        LocalizationsGenerator generator;
        try {
          generator = LocalizationsGenerator(fs);
          generator.initialize(
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
            preferredSupportedLocale: preferredSupportedLocale,
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        fail('Setting language and locales should not fail: \n${e.message}');
      }

      expect(generator.arbPathStrings.first, fs.path.join('lib', 'l10n', 'app_en.arb'));
      expect(generator.arbPathStrings.elementAt(1), fs.path.join('lib', 'l10n', 'app_es.arb'));
      expect(generator.arbPathStrings.elementAt(2), fs.path.join('lib', 'l10n', 'app_zh.arb'));
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
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

    test('correctly requires @@locale property in arb file to match the filename locale suffix', () {
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: 'app_es.arb',
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
      } on L10nException catch (e) {
        expect(e.message, contains('The locale specified in @@locale and the arb filename do not match.'));
        return;
      }

      fail(
        'An exception should occur if the @@locale and the filename extensions are '
        'defined but not matching.'
      );
    });

    test("throws when arb file's locale could not be determined", () {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
        ..createSync(recursive: true)
        ..childFile('app.arb')
        .writeAsStringSync(singleMessageArbFileString);
      try {
        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        generator.initialize(
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
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

  group('writeOutputFiles', () {
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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
        generator.writeOutputFiles();
      } on Exception catch (e) {
        fail('Generating output files should not fail: $e');
      }

      expect(fs.isFileSync(fs.path.join(syntheticPackagePath, 'output-localization-file_en.dart')), true);
      expect(fs.isFileSync(fs.path.join(syntheticPackagePath, 'output-localization-file_en_US.dart')), false);

      final String englishLocalizationsFile = fs.file(
        fs.path.join(syntheticPackagePath, 'output-localization-file_en.dart')
      ).readAsStringSync();
      expect(englishLocalizationsFile, contains('class AppLocalizationsEnCa extends AppLocalizationsEn'));
      expect(englishLocalizationsFile, contains('class AppLocalizationsEn extends AppLocalizations'));
    });

    test('language imports are sorted when preferredSupportedLocaleString is given', () {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString)
        ..childFile('app_zh.arb').writeAsStringSync(singleZhMessageArbFileString)
        ..childFile('app_es.arb').writeAsStringSync(singleEsMessageArbFileString);

      const List<String> preferredSupportedLocale = <String>['zh'];
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.initialize(
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          preferredSupportedLocale: preferredSupportedLocale,
        );
        generator.loadResources();
        generator.writeOutputFiles();
      } on Exception catch (e) {
        fail('Generating output files should not fail: $e');
      }

      final String localizationsFile = fs.file(
        fs.path.join(syntheticPackagePath, defaultOutputFileString),
      ).readAsStringSync();
      expect(localizationsFile, contains(
'''
import 'output-localization-file_en.dart';
import 'output-localization-file_es.dart';
import 'output-localization-file_zh.dart';
'''));
    });

    test('imports are deferred and loaded when useDeferredImports are set', () {
      fs.currentDirectory.childDirectory('lib').childDirectory('l10n')..createSync(recursive: true)
        ..childFile(defaultTemplateArbFileName).writeAsStringSync(singleMessageArbFileString);

      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.initialize(
          inputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
          useDeferredLoading: true,
        );
        generator.loadResources();
        generator.writeOutputFiles();
      } on Exception catch (e) {
        fail('Generating output files should not fail: $e');
      }

      final String localizationsFile = fs.file(
        fs.path.join(syntheticPackagePath, defaultOutputFileString),
      ).readAsStringSync();
      expect(localizationsFile, contains(
'''
import 'output-localization-file_en.dart' deferred as output-localization-file_en;
'''));
      expect(localizationsFile, contains('output-localization-file_en.loadLibrary()'));
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
            inputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
        } on L10nException catch (e) {
          expect(e.message, contains('is not properly formatted'));
          expect(e.message, contains('Ensure that it is a map with string valued keys'));
          return;
        }
        fail('Generating class methods with incorrect placeholder format should not succeed');
      });
    });

    test(
      'should throw with descriptive error message when failing to parse the '
      'arb file',
      () {
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
        } on L10nException catch (e) {
          expect(e.message, contains('app_en.arb'));
          expect(e.message, contains('FormatException'));
          expect(e.message, contains('Unexpected character'));
          return;
        }

        fail(
          'should fail with an L10nException due to a trailing comma in the '
          'arb file.'
        );
      },
    );

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
          inputPathString: defaultL10nPathString,
          outputPathString: defaultL10nPathString,
          templateArbFileName: defaultTemplateArbFileName,
          outputFileString: defaultOutputFileString,
          classNameString: defaultClassNameString,
        );
        generator.loadResources();
        generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            outputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
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
            inputPathString: defaultL10nPathString,
            templateArbFileName: defaultTemplateArbFileName,
            outputFileString: defaultOutputFileString,
            classNameString: defaultClassNameString,
          );
          generator.loadResources();
          generator.writeOutputFiles();
        } on L10nException catch (e) {
          expect(e.message, contains('Invalid ARB resource name'));
          return;
        }

        fail('should fail since key starts with a number.');
      });
    });
  });
}
