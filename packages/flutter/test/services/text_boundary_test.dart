// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

  test('word boundary works', () {
    final WordBoundary boundary = WordBoundary(TestTextLayoutMetrics());
    expect(boundary.getLeadingTextBoundaryAt(3), TestTextLayoutMetrics.wordBoundaryAt3.start);
    expect(boundary.getTrailingTextBoundaryAt(3), TestTextLayoutMetrics.wordBoundaryAt3.end);
    expect(boundary.getTextBoundaryAt(3), TestTextLayoutMetrics.wordBoundaryAt3);
  });

  test('wordBoundary.until', () {
    final List<int> forwardList = <int>[];
    final List<int> backwardList = <int>[];

    bool predicate(int offset, bool forward) {
      final List<int> listToAdd = forward ? forwardList : backwardList;
      listToAdd.add(offset);
      return offset <= 0 || offset >= 111;
    }

    final TextBoundary boundary = WordBoundary(TestWordBoundary()).until(predicate);

    expect(boundary.getLeadingTextBoundaryAt(50), 0);
    expect(boundary.getTrailingTextBoundaryAt(50), 111);
    expect(backwardList, <int>[for (int i = 50 ~/ 3; i >= 0; i--) i * 3]);
    expect(forwardList, <int>[for (int i = 50 ~/ 3 + 1; i <= 111 ~/ 3; i++) i * 3]);

    expect(boundary.getTextBoundaryAt(3), const TextRange(start: 0, end: 111));
    forwardList.clear();
    backwardList.clear();

    bool predicate2(int offset, bool forward) {
      final List<int> listToAdd = forward ? forwardList : backwardList;
      listToAdd.add(offset);
      return offset >= 111;
    }
    final TextBoundary boundary2 = WordBoundary(TestWordBoundary()).until(predicate2);
    expect(boundary2.getLeadingTextBoundaryAt(50), isNull);
    expect(boundary2.getTrailingTextBoundaryAt(50), 111);
    expect(backwardList, <int>[for (int i = 50 ~/ 3; i >= 0; i--) i * 3]);
    expect(forwardList, <int>[for (int i = 50 ~/ 3 + 1; i <= 111 ~/ 3; i++) i * 3]);

    expect(boundary2.getTextBoundaryAt(3), const TextRange(start: -1, end: 111));
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

class TestWordBoundary extends TestTextLayoutMetrics {
  @override
  TextRange getWordBoundary(TextPosition position) {
    final int start = (position.offset ~/ 3) * 3;
    return TextRange(start: start, end: start + 3);
  }
}
