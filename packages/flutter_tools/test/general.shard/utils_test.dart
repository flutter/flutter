// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/base/version.dart';

import '../src/common.dart';

void main() {
  group('SettingsFile', () {
    testWithoutContext('parse', () {
      final SettingsFile file = SettingsFile.parse('''
# ignore comment
foo=bar
baz=qux
''');
      expect(file.values['foo'], 'bar');
      expect(file.values['baz'], 'qux');
      expect(file.values, hasLength(2));
    });
  });

  group('Version', () {
    testWithoutContext('can parse and compare', () {
      expect(Version.unknown.toString(), equals('unknown'));
      expect(Version(null, null, null).toString(), equals('0'));
      expect(const Version.withText(1, 2, 3, 'versionText').toString(), 'versionText');

      final Version v1 = Version.parse('1')!;
      expect(v1.major, equals(1));
      expect(v1.minor, equals(0));
      expect(v1.patch, equals(0));

      expect(v1, greaterThan(Version.unknown));

      final Version v2 = Version.parse('1.2')!;
      expect(v2.major, equals(1));
      expect(v2.minor, equals(2));
      expect(v2.patch, equals(0));

      final Version v3 = Version.parse('1.2.3')!;
      expect(v3.major, equals(1));
      expect(v3.minor, equals(2));
      expect(v3.patch, equals(3));

      final Version v4 = Version.parse('1.12')!;
      expect(v4, greaterThan(v2));

      expect(v3, greaterThan(v2));
      expect(v2, greaterThan(v1));

      final Version v5 = Version(1, 2, 0, text: 'foo');
      expect(v5, equals(v2));

      expect(Version.parse('Preview2.2'), isNull);
    });
  });

  group('Misc', () {
    testWithoutContext('snakeCase', () async {
      expect(snakeCase('abc'), equals('abc'));
      expect(snakeCase('abC'), equals('ab_c'));
      expect(snakeCase('aBc'), equals('a_bc'));
      expect(snakeCase('aBC'), equals('a_b_c'));
      expect(snakeCase('Abc'), equals('abc'));
      expect(snakeCase('AbC'), equals('ab_c'));
      expect(snakeCase('ABc'), equals('a_bc'));
      expect(snakeCase('ABC'), equals('a_b_c'));
    });
  });

  group('text wrapping', () {
    const int _lineLength = 40;
    const String _longLine = 'This is a long line that needs to be wrapped.';
    final String _longLineWithNewlines = 'This is a long line with newlines that\n'
        'needs to be wrapped.\n\n'
        '${'0123456789' * 5}';
    final String _longAnsiLineWithNewlines = '${AnsiTerminal.red}This${AnsiTerminal.resetAll} is a long line with newlines that\n'
        'needs to be wrapped.\n\n'
        '${AnsiTerminal.green}0123456789${AnsiTerminal.resetAll}'
        '${'0123456789' * 3}'
        '${AnsiTerminal.green}0123456789${AnsiTerminal.resetAll}';
    const String _onlyAnsiSequences = '${AnsiTerminal.red}${AnsiTerminal.resetAll}';
    final String _indentedLongLineWithNewlines = '    This is an indented long line with newlines that\n'
        'needs to be wrapped.\n\tAnd preserves tabs.\n      \n  '
        '${'0123456789' * 5}';
    const String _shortLine = 'Short line.';
    const String _indentedLongLine = '    This is an indented long line that needs to be '
        'wrapped and indentation preserved.';
    testWithoutContext('does not wrap by default in tests', () {
      expect(wrapText(_longLine, columnWidth: 80, shouldWrap: true), equals(_longLine));
    });

    testWithoutContext('can override wrap preference if preference is off', () {
      expect(wrapText(_longLine, columnWidth: _lineLength, shouldWrap: true), equals('''
This is a long line that needs to be
wrapped.'''));
    });

    testWithoutContext('can override wrap preference if preference is on', () {
      expect(wrapText(_longLine, shouldWrap: false, columnWidth: 80), equals(_longLine));
    });

    testWithoutContext('does not wrap at all if not told to wrap', () {
      expect(wrapText(_longLine, columnWidth: 80, shouldWrap: false), equals(_longLine));
    });

    testWithoutContext('does not wrap short lines.', () {
      expect(wrapText(_shortLine, columnWidth: _lineLength, shouldWrap: true), equals(_shortLine));
    });

    testWithoutContext('able to wrap long lines', () {
      expect(wrapText(_longLine, columnWidth: _lineLength, shouldWrap: true), equals('''
This is a long line that needs to be
wrapped.'''));
    });

    testWithoutContext('able to handle dynamically changing terminal column size', () {
      expect(wrapText(_longLine, columnWidth: 20, shouldWrap: true), equals('''
This is a long line
that needs to be
wrapped.'''));

      expect(wrapText(_longLine, columnWidth: _lineLength, shouldWrap: true), equals('''
This is a long line that needs to be
wrapped.'''));
    });

    testWithoutContext('wrap long lines with no whitespace', () {
      expect(wrapText('0123456789' * 5, columnWidth: _lineLength, shouldWrap: true), equals('''
0123456789012345678901234567890123456789
0123456789'''));
    });

    testWithoutContext('refuses to wrap to a column smaller than 10 characters', () {
      expect(wrapText('$_longLine ${'0123456789' * 4}', columnWidth: 1, shouldWrap: true), equals('''
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
    testWithoutContext('preserves indentation', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, shouldWrap: true), equals('''
    This is an indented long line that
    needs to be wrapped and indentation
    preserved.'''));
    });

    testWithoutContext('preserves indentation and stripping trailing whitespace', () {
      expect(wrapText('$_indentedLongLine   ', columnWidth: _lineLength, shouldWrap: true), equals('''
    This is an indented long line that
    needs to be wrapped and indentation
    preserved.'''));
    });

    testWithoutContext('wraps text with newlines', () {
      expect(wrapText(_longLineWithNewlines, columnWidth: _lineLength, shouldWrap: true), equals('''
This is a long line with newlines that
needs to be wrapped.

0123456789012345678901234567890123456789
0123456789'''));
    });

    testWithoutContext('wraps text with ANSI sequences embedded', () {
      expect(wrapText(_longAnsiLineWithNewlines, columnWidth: _lineLength, shouldWrap: true), equals('''
${AnsiTerminal.red}This${AnsiTerminal.resetAll} is a long line with newlines that
needs to be wrapped.

${AnsiTerminal.green}0123456789${AnsiTerminal.resetAll}012345678901234567890123456789
${AnsiTerminal.green}0123456789${AnsiTerminal.resetAll}'''));
    });

    testWithoutContext('wraps text with only ANSI sequences', () {
      expect(wrapText(_onlyAnsiSequences, columnWidth: _lineLength, shouldWrap: true),
          equals('${AnsiTerminal.red}${AnsiTerminal.resetAll}'));
    });

    testWithoutContext('preserves indentation in the presence of newlines', () {
      expect(wrapText(_indentedLongLineWithNewlines, columnWidth: _lineLength, shouldWrap: true), equals('''
    This is an indented long line with
    newlines that
needs to be wrapped.
\tAnd preserves tabs.

  01234567890123456789012345678901234567
  890123456789'''));
    });

    testWithoutContext('removes trailing whitespace when wrapping', () {
      expect(wrapText('$_longLine     \t', columnWidth: _lineLength, shouldWrap: true), equals('''
This is a long line that needs to be
wrapped.'''));
    });

    testWithoutContext('honors hangingIndent parameter', () {
      expect(wrapText(_longLine, columnWidth: _lineLength, hangingIndent: 6, shouldWrap: true), equals('''
This is a long line that needs to be
      wrapped.'''));
    });

    testWithoutContext('handles hangingIndent with a single unwrapped line.', () {
      expect(wrapText(_shortLine, columnWidth: _lineLength, hangingIndent: 6, shouldWrap: true), equals('''
Short line.'''));
    });

    testWithoutContext('handles hangingIndent with two unwrapped lines and the second is empty.', () {
      expect(wrapText('$_shortLine\n', columnWidth: _lineLength, hangingIndent: 6, shouldWrap: true), equals('''
Short line.
'''));
    });

    testWithoutContext('honors hangingIndent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, hangingIndent: 6, shouldWrap: true), equals('''
    This is an indented long line that
          needs to be wrapped and
          indentation preserved.'''));
    });

    testWithoutContext('honors hangingIndent and indent parameters at the same time.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, indent: 6, hangingIndent: 6, shouldWrap: true), equals('''
          This is an indented long line
                that needs to be wrapped
                and indentation
                preserved.'''));
    });

    testWithoutContext('honors indent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, indent: 6, shouldWrap: true), equals('''
          This is an indented long line
          that needs to be wrapped and
          indentation preserved.'''));
    });

    testWithoutContext('honors hangingIndent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLineWithNewlines, columnWidth: _lineLength, hangingIndent: 6, shouldWrap: true), equals('''
    This is an indented long line with
          newlines that
needs to be wrapped.
	And preserves tabs.

  01234567890123456789012345678901234567
        890123456789'''));
    });

    testWithoutContext('', () {
      expect(wrapText(
        '${' ' * 7}abc def ghi', columnWidth: 20, hangingIndent: 5, indent: 3, shouldWrap: true),
        equals(
          '          abc def\n'
          '          ghi'
        ),
      );
      expect(wrapText(
        'abc def ghi', columnWidth: 0, hangingIndent: 5, shouldWrap: true),
        equals(
          'abc def\n'
          'ghi'
        ),
      );
      expect(wrapText(
        'abc def ghi', columnWidth: 0, indent: 5, shouldWrap: true),
        equals(
          'abc def\n'
          'ghi'
        ),
      );
      expect(wrapText(
        '     abc def ghi', columnWidth: 0, shouldWrap: true),
        equals(
          'abc def\n'
          'ghi'
        ),
      );
      expect(wrapText(
        'abc def ghi', columnWidth: kMinColumnWidth - 2, hangingIndent: 5, shouldWrap: true),
        equals(
          'abc def\n'
          'ghi'
        ),
      );
      expect(wrapText(
        'abc def ghi', columnWidth: kMinColumnWidth - 2, indent: 5, shouldWrap: true),
        equals(
          'abc def\n'
          'ghi'
        ),
      );
      expect(wrapText(
        '     abc def ghi', columnWidth: kMinColumnWidth - 2, shouldWrap: true),
        equals(
          'abc def\n'
          'ghi'
        ),
      );
      expect(wrapText(
        'abc def ghi jkl', columnWidth: kMinColumnWidth + 2, hangingIndent: 5, shouldWrap: true),
        equals(
          'abc def ghi\n'
          '  jkl'
        ),
      );
      expect(wrapText(
        'abc def ghi', columnWidth: kMinColumnWidth + 2, indent: 5, shouldWrap: true),
        equals(
          '  abc def\n'
          '  ghi'
        ),
      );
      expect(wrapText(
        '     abc def ghi', columnWidth: kMinColumnWidth + 2, shouldWrap: true),
        equals(
          '  abc def\n'
          '  ghi'
        ),
      );
    });
  });
}
