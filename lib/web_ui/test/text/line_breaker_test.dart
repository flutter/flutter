// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'line_breaker_test_data.dart';

void main() {
  group('nextLineBreak', () {
    test('Does not go beyond the ends of a string', () {
      expect(split('foo'), <Line>[
        Line('foo', LineBreakType.endOfText),
      ]);

      final LineBreakResult result = nextLineBreak('foo', 'foo'.length);
      expect(result.index, 'foo'.length);
      expect(result.type, LineBreakType.endOfText);
    });

    test('whitespace', () {
      expect(split('foo bar'), <Line>[
        Line('foo ', LineBreakType.opportunity),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('  foo    bar  '), <Line>[
        Line('  ', LineBreakType.opportunity),
        Line('foo    ', LineBreakType.opportunity),
        Line('bar  ', LineBreakType.endOfText),
      ]);
    });

    test('single-letter lines', () {
      expect(split('foo a bar'), <Line>[
        Line('foo ', LineBreakType.opportunity),
        Line('a ', LineBreakType.opportunity),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('a b c'), <Line>[
        Line('a ', LineBreakType.opportunity),
        Line('b ', LineBreakType.opportunity),
        Line('c', LineBreakType.endOfText),
      ]);
      expect(split(' a b '), <Line>[
        Line(' ', LineBreakType.opportunity),
        Line('a ', LineBreakType.opportunity),
        Line('b ', LineBreakType.endOfText),
      ]);
    });

    test('new line characters', () {
      final String bk = String.fromCharCode(0x000B);
      // Can't have a line break between CR×LF.
      expect(split('foo\r\nbar'), <Line>[
        Line('foo\r\n', LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);

      // Any other new line is considered a line break on its own.

      expect(split('foo\n\nbar'), <Line>[
        Line('foo\n', LineBreakType.mandatory),
        Line('\n', LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('foo\r\rbar'), <Line>[
        Line('foo\r', LineBreakType.mandatory),
        Line('\r', LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('foo$bk${bk}bar'), <Line>[
        Line('foo$bk', LineBreakType.mandatory),
        Line(bk, LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);

      expect(split('foo\n\rbar'), <Line>[
        Line('foo\n', LineBreakType.mandatory),
        Line('\r', LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('foo$bk\rbar'), <Line>[
        Line('foo$bk', LineBreakType.mandatory),
        Line('\r', LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('foo\r${bk}bar'), <Line>[
        Line('foo\r', LineBreakType.mandatory),
        Line(bk, LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('foo$bk\nbar'), <Line>[
        Line('foo$bk', LineBreakType.mandatory),
        Line('\n', LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);
      expect(split('foo\n${bk}bar'), <Line>[
        Line('foo\n', LineBreakType.mandatory),
        Line(bk, LineBreakType.mandatory),
        Line('bar', LineBreakType.endOfText),
      ]);

      // New lines at the beginning and end.

      expect(split('foo\n'), <Line>[
        Line('foo\n', LineBreakType.mandatory),
        Line('', LineBreakType.endOfText),
      ]);
      expect(split('foo\r'), <Line>[
        Line('foo\r', LineBreakType.mandatory),
        Line('', LineBreakType.endOfText),
      ]);
      expect(split('foo$bk'), <Line>[
        Line('foo$bk', LineBreakType.mandatory),
        Line('', LineBreakType.endOfText),
      ]);

      expect(split('\nfoo'), <Line>[
        Line('\n', LineBreakType.mandatory),
        Line('foo', LineBreakType.endOfText),
      ]);
      expect(split('\rfoo'), <Line>[
        Line('\r', LineBreakType.mandatory),
        Line('foo', LineBreakType.endOfText),
      ]);
      expect(split('${bk}foo'), <Line>[
        Line(bk, LineBreakType.mandatory),
        Line('foo', LineBreakType.endOfText),
      ]);

      // Whitespace with new lines.

      expect(split('foo  \n'), <Line>[
        Line('foo  \n', LineBreakType.mandatory),
        Line('', LineBreakType.endOfText),
      ]);

      expect(split('foo  \n   '), <Line>[
        Line('foo  \n', LineBreakType.mandatory),
        Line('   ', LineBreakType.endOfText),
      ]);

      expect(split('foo  \n   bar'), <Line>[
        Line('foo  \n', LineBreakType.mandatory),
        Line('   ', LineBreakType.opportunity),
        Line('bar', LineBreakType.endOfText),
      ]);

      expect(split('\n  foo'), <Line>[
        Line('\n', LineBreakType.mandatory),
        Line('  ', LineBreakType.opportunity),
        Line('foo', LineBreakType.endOfText),
      ]);
      expect(split('   \n  foo'), <Line>[
        Line('   \n', LineBreakType.mandatory),
        Line('  ', LineBreakType.opportunity),
        Line('foo', LineBreakType.endOfText),
      ]);
    });

    test('comprehensive test', () {
      for (int t = 0; t < data.length; t++) {
        final TestCase testCase = data[t];
        final String text = testCase.toText();

        int lastLineBreak = 0;
        int surrogateCount = 0;
        // `s` is the index in the `testCase.signs` list.
        for (int s = 0; s < testCase.signs.length; s++) {
          // `i` is the index in the `text`.
          final int i = s + surrogateCount;
          if (s < testCase.chars.length && testCase.chars[s].isSurrogatePair) {
            surrogateCount++;
          }

          final Sign sign = testCase.signs[s];
          final LineBreakResult result = nextLineBreak(text, lastLineBreak);
          if (sign.isBreakOpportunity) {
            // The line break should've been found at index `i`.
            expect(
              result.index,
              i,
              reason: 'Failed at test case number $t:\n'
                  '${testCase.toString()}\n'
                  '"$text"\n'
                  '\nExpected line break at {$lastLineBreak - $i} but found line break at {$lastLineBreak - ${result.index}}.',
            );
            lastLineBreak = i;
          } else {
            // This isn't a line break opportunity so the line break should be
            // somewhere after index `i`.
            expect(
              result.index,
              greaterThan(i),
              reason: 'Failed at test case number $t:\n'
                  '${testCase.toString()}\n'
                  '"$text"\n'
                  '\nUnexpected line break found at {$lastLineBreak - $i}.',
            );
          }
        }
      }
    });
  });
}

/// Holds information about how a line was split from a string.
class Line {
  Line(this.text, this.breakType);

  final String text;
  final LineBreakType breakType;

  @override
  int get hashCode => hashValues(text, breakType);

  @override
  bool operator ==(Object other) {
    return other is Line
        && other.text == text
        && other.breakType == breakType;
  }

  String get escapedText {
    final String bk = String.fromCharCode(0x000B);
    final String nl = String.fromCharCode(0x0085);
    return text
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll(bk, '{BK}')
        .replaceAll(nl, '{NL}');
  }

  @override
  String toString() {
    return '"$escapedText" ($breakType)';
  }
}

List<Line> split(String text) {
  final List<Line> lines = <Line>[];

  int i = 0;
  LineBreakType breakType;
  while (breakType != LineBreakType.endOfText) {
    final LineBreakResult result = nextLineBreak(text, i);
    lines.add(Line(text.substring(i, result.index), result.type));

    i = result.index;
    breakType = result.type;
  }
  return lines;
}
