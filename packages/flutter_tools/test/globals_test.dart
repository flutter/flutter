// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/base/terminal.dart';

const int _lineLength = 40;
const String _longLine = 'This is a long line that needs to be wrapped.';
final String _longLineWithNewlines = 'This is a long line with newlines that\n'
  'needs to be wrapped.\n\n' +
  '0123456789' * 5;
final String _longAnsiLineWithNewlines = '${AnsiTerminal.red}This${AnsiTerminal.reset} is a long line with newlines that\n'
    'needs to be wrapped.\n\n' +
    '0123456789' * 4 +
    '${AnsiTerminal.green}0123456789${AnsiTerminal.reset}';
const String _onlyAnsiSequences = '${AnsiTerminal.red}${AnsiTerminal.reset}';
final String _indentedLongLineWithNewlines =
  '    This is an indented long line with newlines that\n'
    'needs to be wrapped.\n\tAnd preserves tabs.\n      \n  ' +
    '0123456789' * 5;
const String _shortLine = 'Short line.';
const String _indentedLongLine = '    This is an indented long line that needs to be '
  'wrapped and indentation preserved.';

void main() {
  group('text wrapping', () {
    test('does not wrap short lines.', () {
      expect(wrapText(_shortLine, columnWidth: _lineLength), equals(_shortLine));
    });
    test('does not wrap at all if not given a length', () {
      expect(wrapText(_longLine), equals(_longLine));
    });
    test('able to wrap long lines', () {
      expect(wrapText(_longLine, columnWidth: _lineLength), equals('''
This is a long line that needs to be
wrapped.'''));
    });
    test('wrap long lines with no whitespace', () {
      expect(wrapText('0123456789' * 5, columnWidth: _lineLength), equals('''
0123456789012345678901234567890123456789
0123456789'''));
    });
    test('refuses to wrap to a column smaller than 10 characters', () {
      expect(wrapText('$_longLine ' + '0123456789' * 4, columnWidth: 1), equals('''
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
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength), equals('''
    This is an indented long line that
    needs to be wrapped and indentation
    preserved.'''));
    });
    test('preserves indentation and stripping trailing whitespace', () {
      expect(wrapText('$_indentedLongLine   ', columnWidth: _lineLength), equals('''
    This is an indented long line that
    needs to be wrapped and indentation
    preserved.'''));
    });
    test('wraps text with newlines', () {
      expect(wrapText(_longLineWithNewlines, columnWidth: _lineLength), equals('''
This is a long line with newlines that
needs to be wrapped.

0123456789012345678901234567890123456789
0123456789'''));
    });
    test('wraps text with ANSI sequences embedded', () {
      expect(wrapText(_longAnsiLineWithNewlines, columnWidth: _lineLength), equals('''
${AnsiTerminal.red}This${AnsiTerminal.reset} is a long line with newlines that
needs to be wrapped.

0123456789012345678901234567890123456789
${AnsiTerminal.green}0123456789${AnsiTerminal.reset}'''));
    });
    test('wraps text with only ANSI sequences', () {
      expect(wrapText(_onlyAnsiSequences, columnWidth: _lineLength), equals('${AnsiTerminal.red}${AnsiTerminal.reset}'));
    });
    test('preserves indentation in the presence of newlines', () {
      expect(wrapText(_indentedLongLineWithNewlines, columnWidth: _lineLength),
        equals('''
    This is an indented long line with
    newlines that
needs to be wrapped.
\tAnd preserves tabs.

  01234567890123456789012345678901234567
  890123456789'''));
    });
    test('removes trailing whitespace when wrapping', () {
      expect(wrapText('$_longLine     \t', columnWidth: _lineLength), equals('''
This is a long line that needs to be
wrapped.'''));
    });
    test('honors hangingIndent parameter', () {
      expect(
        wrapText(_longLine, columnWidth: _lineLength, hangingIndent: 6), equals('''
This is a long line that needs to be
      wrapped.'''));
    });
    test('handles hangingIndent with a single unwrapped line.', () {
      expect(wrapText(_shortLine, columnWidth: _lineLength, hangingIndent: 6),
        equals('''
Short line.'''));
    });
    test(
      'handles hangingIndent with two unwrapped lines and the second is empty.',
        () {
        expect(wrapText('$_shortLine\n', columnWidth: _lineLength, hangingIndent: 6),
          equals('''
Short line.
'''));
      });
    test('honors hangingIndent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, hangingIndent: 6),
        equals('''
    This is an indented long line that
          needs to be wrapped and
          indentation preserved.'''));
    });
    test('honors hangingIndent and indent parameters at the same time.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, indent: 6, hangingIndent: 6),
        equals('''
          This is an indented long line that
                needs to be wrapped and
                indentation preserved.'''));
    });
    test('honors indent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, indent: 6),
        equals('''
          This is an indented long line that
          needs to be wrapped and indentation
          preserved.'''));
    });
    test('honors hangingIndent parameter on already indented line.', () {
      expect(
        wrapText(_indentedLongLineWithNewlines,
          columnWidth: _lineLength, hangingIndent: 6),
        equals('''
    This is an indented long line with
          newlines that
needs to be wrapped.
	And preserves tabs.

  01234567890123456789012345678901234567
        890123456789'''));
    });
  });
}
