// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';


class _ConsistentTextRangeImplementationMatcher extends Matcher {
  _ConsistentTextRangeImplementationMatcher(int length)
    : range = TextRange(start: -1, end: length + 1),
      assert(length >= 0);

  final TextRange range;
  @override
  Description describe(Description description) {
    return description.add('The implementation of TextBoundary.getTextBoundaryAt is consistent with its other methods.');
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    final TextBoundary boundary = matchState['textBoundary'] as TextBoundary;
    final int position = matchState['position'] as int;
    final int leading = boundary.getLeadingTextBoundaryAt(position) ?? -1;
    final int trailing = boundary.getTrailingTextBoundaryAt(position) ?? -1;

    return mismatchDescription.add(
      'at position $position, expected ${TextRange(start: leading, end: trailing)} but got ${boundary.getTextBoundaryAt(position)}',
    );
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    for (int i = range.start; i <= range.end; i++) {
      final int? leading = (item as TextBoundary).getLeadingTextBoundaryAt(i);
      final int? trailing = item.getTrailingTextBoundaryAt(i);
      final TextRange boundary = item.getTextBoundaryAt(i);
      final bool consistent = boundary.start == (leading ?? -1) && boundary.end == (trailing ?? -1);
      if (!consistent) {
        matchState['textBoundary'] = item;
        matchState['position'] = i;
        return false;
      }
    }
    return true;
  }
}

Matcher _hasConsistentTextRangeImplementationWithinRange(int length) => _ConsistentTextRangeImplementationMatcher(length);

void main() {
  test('Character boundary works', () {
    const CharacterBoundary boundary = CharacterBoundary('abc');
    expect(boundary, _hasConsistentTextRangeImplementationWithinRange(3));

    expect(boundary.getLeadingTextBoundaryAt(-1), null);
    expect(boundary.getTrailingTextBoundaryAt(-1), 0);

    expect(boundary.getLeadingTextBoundaryAt(0), 0);
    expect(boundary.getTrailingTextBoundaryAt(0), 1);

    expect(boundary.getLeadingTextBoundaryAt(1), 1);
    expect(boundary.getTrailingTextBoundaryAt(1), 2);

    expect(boundary.getLeadingTextBoundaryAt(2), 2);
    expect(boundary.getTrailingTextBoundaryAt(2), 3);

    expect(boundary.getLeadingTextBoundaryAt(3), 3);
    expect(boundary.getTrailingTextBoundaryAt(3), null);

    expect(boundary.getLeadingTextBoundaryAt(4), 3);
    expect(boundary.getTrailingTextBoundaryAt(4), null);
  });

  test('Character boundary works with grapheme', () {
    const String text = 'a❄︎c';
    const CharacterBoundary boundary = CharacterBoundary(text);
    expect(boundary, _hasConsistentTextRangeImplementationWithinRange(text.length));

    expect(boundary.getLeadingTextBoundaryAt(-1), null);
    expect(boundary.getTrailingTextBoundaryAt(-1), 0);

    expect(boundary.getLeadingTextBoundaryAt(0), 0);
    expect(boundary.getTrailingTextBoundaryAt(0), 1);

    // The `❄` takes two character length.
    expect(boundary.getLeadingTextBoundaryAt(1), 1);
    expect(boundary.getTrailingTextBoundaryAt(1), 3);

    expect(boundary.getLeadingTextBoundaryAt(2), 1);
    expect(boundary.getTrailingTextBoundaryAt(2), 3);

    expect(boundary.getLeadingTextBoundaryAt(3), 3);
    expect(boundary.getTrailingTextBoundaryAt(3), 4);

    expect(boundary.getLeadingTextBoundaryAt(text.length), text.length);
    expect(boundary.getTrailingTextBoundaryAt(text.length), null);
  });

  test('wordBoundary.moveByWordBoundary', () {
    const String text = 'ABC   ABC\n'       // [0, 10)
                        'AÁ   AÁ\n'         // [10, 20)
                        '         \n'       // [20, 30)
                        'ABC!!!ABC\n'       // [30, 40)
                        'A  𑗋𑗋 A\n';     // [40, 50)

    final TextPainter textPainter = TextPainter()
      ..textDirection = TextDirection.ltr
      ..text = const TextSpan(text: text);

    final TextBoundary boundary = textPainter.wordBoundaries.moveByWordBoundary;

    // 4 points to the 2nd whitespace in the first line.
    // Don't break between horizontal spaces and letters/numbers.
    expect(boundary.getLeadingTextBoundaryAt(4), 0);
    expect(boundary.getTrailingTextBoundaryAt(4), 9);

    expect(boundary.getLeadingTextBoundaryAt(14), 10);
    expect(boundary.getTrailingTextBoundaryAt(14), 19);

    // Breaks after newlines.
    expect(boundary.getLeadingTextBoundaryAt(21), 20);
    // Breaks before newlines.
    expect(boundary.getTrailingTextBoundaryAt(21), 29);

    // Don't break between punctuations and
    expect(boundary.getLeadingTextBoundaryAt(34), 30);
    // Breaks before newlines.
    expect(boundary.getTrailingTextBoundaryAt(34), 39);

    // 44 points to a low surrogate of a punctuation.
    expect(boundary.getLeadingTextBoundaryAt(44), 40);
    expect(boundary.getTrailingTextBoundaryAt(44), 49);
  });

  test('line boundary works', () {
    final LineBoundary boundary = LineBoundary(TestTextLayoutMetrics());
    expect(boundary.getLeadingTextBoundaryAt(3), TestTextLayoutMetrics.lineAt3.start);
    expect(boundary.getTrailingTextBoundaryAt(3), TestTextLayoutMetrics.lineAt3.end);
    expect(boundary.getTextBoundaryAt(3), TestTextLayoutMetrics.lineAt3);
  });

  test('document boundary works', () {
    const String text = 'abcd efg hi\njklmno\npqrstuv';
    const DocumentBoundary boundary = DocumentBoundary(text);
    expect(boundary, _hasConsistentTextRangeImplementationWithinRange(text.length));

    expect(boundary.getLeadingTextBoundaryAt(-1), null);
    expect(boundary.getTrailingTextBoundaryAt(-1), text.length);

    expect(boundary.getLeadingTextBoundaryAt(0), 0);
    expect(boundary.getTrailingTextBoundaryAt(0), text.length);

    expect(boundary.getLeadingTextBoundaryAt(10), 0);
    expect(boundary.getTrailingTextBoundaryAt(10), text.length);

    expect(boundary.getLeadingTextBoundaryAt(text.length), 0);
    expect(boundary.getTrailingTextBoundaryAt(text.length), null);

    expect(boundary.getLeadingTextBoundaryAt(text.length + 1), 0);
    expect(boundary.getTrailingTextBoundaryAt(text.length + 1), null);
  });
}

class TestTextLayoutMetrics extends TextLayoutMetrics {
  static const TextSelection lineAt3 = TextSelection(baseOffset: 0, extentOffset: 10);
  static const TextRange wordBoundaryAt3 = TextRange(start: 4, end: 7);

  @override
  TextSelection getLineAtOffset(TextPosition position) {
    if (position.offset == 3) {
      return lineAt3;
    }
    throw UnimplementedError();
  }

  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    throw UnimplementedError();
  }

  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    throw UnimplementedError();
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    if (position.offset == 3) {
      return wordBoundaryAt3;
    }
    throw UnimplementedError();
  }
}
