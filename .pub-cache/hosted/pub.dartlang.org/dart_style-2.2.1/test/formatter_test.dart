// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library dart_style.test.formatter_test;

import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  testDirectory('comments');
  testDirectory('regression');
  testDirectory('selections');
  testDirectory('splitting');
  testDirectory('whitespace');

  test('throws a FormatterException on failed parse', () {
    var formatter = DartFormatter();
    expect(() => formatter.format('wat?!'),
        throwsA(TypeMatcher<FormatterException>()));
  });

  test('FormatterException.message() does not throw', () {
    // This is a regression test for #358 where an error whose position is
    // past the end of the source caused FormatterException to throw.
    try {
      DartFormatter().format('library');
    } on FormatterException catch (err) {
      var message = err.message();
      expect(message, contains('Could not format'));
    }
  });

  test('FormatterException describes parse errors', () {
    try {
      DartFormatter().format('''

      var a = some error;

      var b = another one;
      ''', uri: 'my_file.dart');

      fail('Should throw.');
    } on FormatterException catch (err) {
      var message = err.message();
      expect(message, contains('my_file.dart'));
      expect(message, contains('line 2'));
      expect(message, contains('line 4'));
    }
  });

  test('adds newline to unit', () {
    expect(DartFormatter().format('var x = 1;'), equals('var x = 1;\n'));
  });

  test('adds newline to unit after trailing comment', () {
    expect(DartFormatter().format('library foo; //zamm'),
        equals('library foo; //zamm\n'));
  });

  test('removes extra newlines', () {
    expect(DartFormatter().format('var x = 1;\n\n\n'), equals('var x = 1;\n'));
  });

  test('does not add newline to statement', () {
    expect(DartFormatter().formatStatement('var x = 1;'), equals('var x = 1;'));
  });

  test('fails if anything is after the statement', () {
    try {
      DartFormatter().formatStatement('var x = 1;;');

      fail('Should throw.');
    } on FormatterException catch (ex) {
      expect(ex.errors.length, equals(1));
      expect(ex.errors.first.offset, equals(10));
    }
  });

  test('preserves initial indent', () {
    var formatter = DartFormatter(indent: 3);
    expect(
        formatter.formatStatement('if (foo) {bar;}'),
        equals('   if (foo) {\n'
            '     bar;\n'
            '   }'));
  });

  group('line endings', () {
    test('uses given line ending', () {
      // Use zero width no-break space character as the line ending. We have
      // to use a whitespace character for the line ending as the formatter
      // will throw an error if it accidentally makes non-whitespace changes
      // as will occur
      var lineEnding = '\t';
      expect(DartFormatter(lineEnding: lineEnding).format('var i = 1;'),
          equals('var i = 1;\t'));
    });

    test('infers \\r\\n if the first newline uses that', () {
      expect(DartFormatter().format('var\r\ni\n=\n1;\n'),
          equals('var i = 1;\r\n'));
    });

    test('infers \\n if the first newline uses that', () {
      expect(DartFormatter().format('var\ni\r\n=\r\n1;\r\n'),
          equals('var i = 1;\n'));
    });

    test('defaults to \\n if there are no newlines', () {
      expect(DartFormatter().format('var i =1;'), equals('var i = 1;\n'));
    });

    test('handles Windows line endings in multiline strings', () {
      expect(
          DartFormatter(lineEnding: '\r\n').formatStatement('  """first\r\n'
              'second\r\n'
              'third"""  ;'),
          equals('"""first\r\n'
              'second\r\n'
              'third""";'));
    });
  });

  test('throws an UnexpectedOutputException on non-whitespace changes', () {
    // Use an invalid line ending character to ensure the formatter will
    // attempt to make non-whitespace changes.
    var formatter = DartFormatter(lineEnding: '%');
    expect(() => formatter.format('var i = 1;'),
        throwsA(TypeMatcher<UnexpectedOutputException>()));
  });
}
