// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../gen_l10n.dart';

final String defaultArbPathString = path.join('lib', 'l10n');
const String defaultTemplateArbFileName = 'app_en.arb';
const String defaultOutputFileString = 'output-localization-file';
const String defaultClassNameString = 'AppLocalizations';

const String singleMessageArbFileString = '''{
  "title": "Stocks",
  "@title": {
    "description": "Title for the Stocks application"
  }
}''';

void _standardFlutterDirectoryL10nSetup(FileSystem fs) {
  fs.currentDirectory.childDirectory('lib').childDirectory('l10n')
    ..createSync(recursive: true)
    ..childFile(defaultTemplateArbFileName)
    .writeAsStringSync(singleMessageArbFileString);
}

void main() {
  MemoryFileSystem fs;
  setUp(() {
    fs = MemoryFileSystem();
  });

  group('LocalizationsGenerator setters:', () {
    test('happy path', () {
      _standardFlutterDirectoryL10nSetup(fs);

      try {
        final LocalizationsGenerator generator = LocalizationsGenerator(fs);
        generator.setL10nDirectory(defaultArbPathString);
        generator.setTemplateArbFile(defaultTemplateArbFileName);
        generator.setOutputFile(defaultOutputFileString);
        generator.setClassName(defaultClassNameString);
      } on FileSystemException catch (e) {
        fail('Setters should not fail $e');
      }
    });

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
        expect(e.message, 'Input string cannot be null');
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setL10nDirectory should fail if the '
        'the input string is null.'
      );
    });

    test('setTemplateArbFile fails if l10nDirectory is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setTemplateArbFile(null);
      } on L10nException catch (e) {
        expect(e.message, 'Input string cannot be null');
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
        expect(e.message, 'Input string cannot be null');
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
        expect(e.message, 'Input string cannot be null');
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setOutputFile should fail if the '
        'the input string is null.'
      );
    });

    test('setClassName fails if input string is null', () {
      _standardFlutterDirectoryL10nSetup(fs);
      final LocalizationsGenerator generator = LocalizationsGenerator(fs);
      try {
        generator.setClassName(null);
      } on L10nException catch (e) {
        expect(e.message, 'Input string cannot be null');
        return;
      }

      fail(
        'Attempting to set LocalizationsGenerator.setClassName should fail if the '
        'the input string is null.'
      );
    });

    group('setClassName should only take valid Dart class names:', () {
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
          generator.setClassName('String with spaces');
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.setClassName should fail if the '
          'the input string is not a valid Dart class name.'
        );
      });

      test('fails on non-alphanumeric symbols', () {
        try {
          generator.setClassName('TestClass@123');
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.setClassName should fail if the '
          'the input string is not a valid Dart class name.'
        );
      });

      test('fails on camel-case', () {
        try {
          generator.setClassName('camelCaseClassName');
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.setClassName should fail if the '
          'the input string is not a valid Dart class name.'
        );
      });

      test('fails when starting with a number', () {
        try {
          generator.setClassName('123ClassName');
        } on L10nException catch (e) {
          expect(e.message, contains('is not a valid Dart class name'));
          return;
        }
        fail(
          'Attempting to set LocalizationsGenerator.setClassName should fail if the '
          'the input string is not a valid Dart class name.'
        );
      });
    });
  });
}
