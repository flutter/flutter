// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/src/utils.dart';
import 'package:test/test.dart';

const _lineLength = 40;
const _longLine = 'This is a long line that needs to be wrapped.';
final _longLineWithNewlines = 'This is a long line with newlines that\n'
        'needs to be wrapped.\n\n' +
    '0123456789' * 5;
final _indentedLongLineWithNewlines =
    '    This is an indented long line with newlines that\n'
            'needs to be wrapped.\n\tAnd preserves tabs.\n      \n  ' +
        '0123456789' * 5;
const _shortLine = 'Short line.';
const _indentedLongLine = '    This is an indented long line that needs to be '
    'wrapped and indentation preserved.';

void main() {
  group('padding', () {
    test('can pad on the right.', () {
      expect(padRight('foo', 6), equals('foo   '));
    });
  });
  group('text wrapping', () {
    test("doesn't wrap short lines.", () {
      expect(wrapText(_shortLine, length: _lineLength), equals(_shortLine));
    });
    test("doesn't wrap at all if not given a length", () {
      expect(wrapText(_longLine), equals(_longLine));
    });
    test('able to wrap long lines', () {
      expect(wrapText(_longLine, length: _lineLength), equals('''
This is a long line that needs to be
wrapped.'''));
    });
    test('wrap long lines with no whitespace', () {
      expect(wrapText('0123456789' * 5, length: _lineLength), equals('''
0123456789012345678901234567890123456789
0123456789'''));
    });
    test('refuses to wrap to a column smaller than 10 characters', () {
      expect(wrapText('$_longLine ' + '0123456789' * 4, length: 1), equals('''
This is a
long line
that needs
to be
wrapped.
0123456789
0123456789
0123456789
0123456789'''));
    });
    test('preserves indentation', () {
      expect(wrapText(_indentedLongLine, length: _lineLength), equals('''
    This is an indented long line that
    needs to be wrapped and indentation
    preserved.'''));
    });
    test('preserves indentation and stripping trailing whitespace', () {
      expect(wrapText('$_indentedLongLine   ', length: _lineLength), equals('''
    This is an indented long line that
    needs to be wrapped and indentation
    preserved.'''));
    });
    test('wraps text with newlines', () {
      expect(wrapText(_longLineWithNewlines, length: _lineLength), equals('''
This is a long line with newlines that
needs to be wrapped.

0123456789012345678901234567890123456789
0123456789'''));
    });
    test('preserves indentation in the presence of newlines', () {
      expect(wrapText(_indentedLongLineWithNewlines, length: _lineLength),
          equals('''
    This is an indented long line with
    newlines that
needs to be wrapped.
\tAnd preserves tabs.

  01234567890123456789012345678901234567
  890123456789'''));
    });
    test('removes trailing whitespace when wrapping', () {
      expect(wrapText('$_longLine     \t', length: _lineLength), equals('''
This is a long line that needs to be
wrapped.'''));
    });
    test('preserves trailing whitespace when not wrapping', () {
      expect(wrapText('$_longLine     \t'), equals('$_longLine     \t'));
    });
    test('honors hangingIndent parameter', () {
      expect(
          wrapText(_longLine, length: _lineLength, hangingIndent: 6), equals('''
This is a long line that needs to be
      wrapped.'''));
    });
    test('handles hangingIndent with a single unwrapped line.', () {
      expect(wrapText(_shortLine, length: _lineLength, hangingIndent: 6),
          equals('''
Short line.'''));
    });
    test(
        'handles hangingIndent with two unwrapped lines and the second is empty.',
        () {
      expect(wrapText('$_shortLine\n', length: _lineLength, hangingIndent: 6),
          equals('''
Short line.
'''));
    });
    test('honors hangingIndent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, length: _lineLength, hangingIndent: 6),
          equals('''
    This is an indented long line that
          needs to be wrapped and
          indentation preserved.'''));
    });
    test('honors hangingIndent parameter on already indented line.', () {
      expect(
          wrapText(_indentedLongLineWithNewlines,
              length: _lineLength, hangingIndent: 6),
          equals('''
    This is an indented long line with
          newlines that
needs to be wrapped.
	And preserves tabs.

  01234567890123456789012345678901234567
        890123456789'''));
    });
  });
  group('text wrapping as lines', () {
    test("doesn't wrap short lines.", () {
      expect(wrapTextAsLines(_shortLine, length: _lineLength),
          equals([_shortLine]));
    });
    test("doesn't wrap at all if not given a length", () {
      expect(wrapTextAsLines(_longLine), equals([_longLine]));
    });
    test('able to wrap long lines', () {
      expect(wrapTextAsLines(_longLine, length: _lineLength),
          equals(['This is a long line that needs to be', 'wrapped.']));
    });
    test('wrap long lines with no whitespace', () {
      expect(wrapTextAsLines('0123456789' * 5, length: _lineLength),
          equals(['0123456789012345678901234567890123456789', '0123456789']));
    });

    test('refuses to wrap to a column smaller than 10 characters', () {
      expect(
          wrapTextAsLines('$_longLine ' + '0123456789' * 4, length: 1),
          equals([
            'This is a',
            'long line',
            'that needs',
            'to be',
            'wrapped.',
            '0123456789',
            '0123456789',
            '0123456789',
            '0123456789'
          ]));
    });
    test("doesn't preserve indentation", () {
      expect(
          wrapTextAsLines(_indentedLongLine, length: _lineLength),
          equals([
            'This is an indented long line that needs',
            'to be wrapped and indentation preserved.'
          ]));
    });
    test('strips trailing whitespace', () {
      expect(
          wrapTextAsLines('$_indentedLongLine   ', length: _lineLength),
          equals([
            'This is an indented long line that needs',
            'to be wrapped and indentation preserved.'
          ]));
    });
    test('splits text with newlines properly', () {
      expect(
          wrapTextAsLines(_longLineWithNewlines, length: _lineLength),
          equals([
            'This is a long line with newlines that',
            'needs to be wrapped.',
            '',
            '0123456789012345678901234567890123456789',
            '0123456789'
          ]));
    });
    test('does not preserves indentation in the presence of newlines', () {
      expect(
          wrapTextAsLines(_indentedLongLineWithNewlines, length: _lineLength),
          equals([
            'This is an indented long line with',
            'newlines that',
            'needs to be wrapped.',
            'And preserves tabs.',
            '',
            '0123456789012345678901234567890123456789',
            '0123456789'
          ]));
    });
    test('removes trailing whitespace when wrapping', () {
      expect(wrapTextAsLines('$_longLine     \t', length: _lineLength),
          equals(['This is a long line that needs to be', 'wrapped.']));
    });
    test('preserves trailing whitespace when not wrapping', () {
      expect(
          wrapTextAsLines('$_longLine     \t'), equals(['$_longLine     \t']));
    });
  });
}
