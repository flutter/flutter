// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/base/terminal.dart';

import 'src/common.dart';

void main() {
  group('SettingsFile', () {
    test('parse', () {
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

  group('uuid', () {
    // xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    test('simple', () {
      final Uuid uuid = Uuid();
      final String result = uuid.generateV4();
      expect(result.length, 36);
      expect(result[8], '-');
      expect(result[13], '-');
      expect(result[18], '-');
      expect(result[23], '-');
    });

    test('can parse', () {
      final Uuid uuid = Uuid();
      final String result = uuid.generateV4();
      expect(int.parse(result.substring(0, 8), radix: 16), isNotNull);
      expect(int.parse(result.substring(9, 13), radix: 16), isNotNull);
      expect(int.parse(result.substring(14, 18), radix: 16), isNotNull);
      expect(int.parse(result.substring(19, 23), radix: 16), isNotNull);
      expect(int.parse(result.substring(24, 36), radix: 16), isNotNull);
    });

    test('special bits', () {
      final Uuid uuid = Uuid();
      String result = uuid.generateV4();
      expect(result[14], '4');
      expect(result[19].toLowerCase(), isIn('89ab'));

      result = uuid.generateV4();
      expect(result[19].toLowerCase(), isIn('89ab'));

      result = uuid.generateV4();
      expect(result[19].toLowerCase(), isIn('89ab'));
    });

    test('is pretty random', () {
      final Set<String> set = Set<String>();

      Uuid uuid = Uuid();
      for (int i = 0; i < 64; i++) {
        final String val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }

      uuid = Uuid();
      for (int i = 0; i < 64; i++) {
        final String val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }

      uuid = Uuid();
      for (int i = 0; i < 64; i++) {
        final String val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }
    });
  });

  group('Version', () {
    test('can parse and compare', () {
      expect(Version.unknown.toString(), equals('unknown'));
      expect(Version(null, null, null).toString(), equals('0'));

      final Version v1 = Version.parse('1');
      expect(v1.major, equals(1));
      expect(v1.minor, equals(0));
      expect(v1.patch, equals(0));

      expect(v1, greaterThan(Version.unknown));

      final Version v2 = Version.parse('1.2');
      expect(v2.major, equals(1));
      expect(v2.minor, equals(2));
      expect(v2.patch, equals(0));

      final Version v3 = Version.parse('1.2.3');
      expect(v3.major, equals(1));
      expect(v3.minor, equals(2));
      expect(v3.patch, equals(3));

      final Version v4 = Version.parse('1.12');
      expect(v4, greaterThan(v2));

      expect(v3, greaterThan(v2));
      expect(v2, greaterThan(v1));

      final Version v5 = Version(1, 2, 0, text: 'foo');
      expect(v5, equals(v2));

      expect(Version.parse('Preview2.2'), isNull);
    });
  });

  group('Poller', () {
    const Duration kShortDelay = Duration(milliseconds: 100);

    Poller poller;

    tearDown(() {
      poller?.cancel();
    });

    test('fires at start', () async {
      bool called = false;
      poller = Poller(() async {
        called = true;
      }, const Duration(seconds: 1));
      expect(called, false);
      await Future<void>.delayed(kShortDelay);
      expect(called, true);
    });

    test('runs periodically', () async {
      // Ensure we get the first (no-delay) callback, and one of the periodic callbacks.
      int callCount = 0;
      poller = Poller(() async {
        callCount++;
      }, Duration(milliseconds: kShortDelay.inMilliseconds ~/ 2));
      expect(callCount, 0);
      await Future<void>.delayed(kShortDelay);
      expect(callCount, greaterThanOrEqualTo(2));
    });

    test('no quicker then the periodic delay', () async {
      // Make sure that the poller polls at delay + the time it took to run the callback.
      final Completer<Duration> completer = Completer<Duration>();
      DateTime firstTime;
      poller = Poller(() async {
        if (firstTime == null)
          firstTime = DateTime.now();
        else
          completer.complete(DateTime.now().difference(firstTime));

        // introduce a delay
        await Future<void>.delayed(kShortDelay);
      }, kShortDelay);
      final Duration duration = await completer.future;
      expect(duration, greaterThanOrEqualTo(Duration(milliseconds: kShortDelay.inMilliseconds * 2)));
    });
  });

  group('Misc', () {
    test('snakeCase', () async {
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
        'needs to be wrapped.\n\n' +
        '0123456789' * 5;
    final String _longAnsiLineWithNewlines = '${AnsiTerminal.red}This${AnsiTerminal.reset} is a long line with newlines that\n'
        'needs to be wrapped.\n\n'
        '${AnsiTerminal.green}0123456789${AnsiTerminal.reset}' +
        '0123456789' * 3 +
        '${AnsiTerminal.green}0123456789${AnsiTerminal.reset}';
    const String _onlyAnsiSequences = '${AnsiTerminal.red}${AnsiTerminal.reset}';
    final String _indentedLongLineWithNewlines = '    This is an indented long line with newlines that\n'
        'needs to be wrapped.\n\tAnd preserves tabs.\n      \n  ' +
        '0123456789' * 5;
    const String _shortLine = 'Short line.';
    const String _indentedLongLine = '    This is an indented long line that needs to be '
        'wrapped and indentation preserved.';

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

${AnsiTerminal.green}0123456789${AnsiTerminal.reset}012345678901234567890123456789
${AnsiTerminal.green}0123456789${AnsiTerminal.reset}'''));
    });
    test('wraps text with only ANSI sequences', () {
      expect(wrapText(_onlyAnsiSequences, columnWidth: _lineLength),
          equals('${AnsiTerminal.red}${AnsiTerminal.reset}'));
    });
    test('preserves indentation in the presence of newlines', () {
      expect(wrapText(_indentedLongLineWithNewlines, columnWidth: _lineLength), equals('''
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
      expect(wrapText(_longLine, columnWidth: _lineLength, hangingIndent: 6), equals('''
This is a long line that needs to be
      wrapped.'''));
    });
    test('handles hangingIndent with a single unwrapped line.', () {
      expect(wrapText(_shortLine, columnWidth: _lineLength, hangingIndent: 6), equals('''
Short line.'''));
    });
    test('handles hangingIndent with two unwrapped lines and the second is empty.', () {
      expect(wrapText('$_shortLine\n', columnWidth: _lineLength, hangingIndent: 6), equals('''
Short line.
'''));
    });
    test('honors hangingIndent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, hangingIndent: 6), equals('''
    This is an indented long line that
          needs to be wrapped and
          indentation preserved.'''));
    });
    test('honors hangingIndent and indent parameters at the same time.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, indent: 6, hangingIndent: 6), equals('''
          This is an indented long line
                that needs to be wrapped
                and indentation
                preserved.'''));
    });
    test('honors indent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLine, columnWidth: _lineLength, indent: 6), equals('''
          This is an indented long line
          that needs to be wrapped and
          indentation preserved.'''));
    });
    test('honors hangingIndent parameter on already indented line.', () {
      expect(wrapText(_indentedLongLineWithNewlines, columnWidth: _lineLength, hangingIndent: 6), equals('''
    This is an indented long line with
          newlines that
needs to be wrapped.
	And preserves tabs.

  01234567890123456789012345678901234567
        890123456789'''));
    });
  });
}
