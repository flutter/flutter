// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Character boundary works', () {
    const CharacterBoundary boundary = CharacterBoundary('abc');
    const TextPosition midPosition = TextPosition(offset: 1);
    expect(boundary.getLeadingTextBoundaryAt(midPosition), const TextPosition(offset: 1));
    expect(boundary.getTrailingTextBoundaryAt(midPosition), const TextPosition(offset: 2, affinity: TextAffinity.upstream));

    const TextPosition startPosition = TextPosition(offset: 0);
    expect(boundary.getLeadingTextBoundaryAt(startPosition), const TextPosition(offset: 0));
    expect(boundary.getTrailingTextBoundaryAt(startPosition), const TextPosition(offset: 1, affinity: TextAffinity.upstream));

    const TextPosition endPosition = TextPosition(offset: 3);
    expect(boundary.getLeadingTextBoundaryAt(endPosition), const TextPosition(offset: 3, affinity: TextAffinity.upstream));
    expect(boundary.getTrailingTextBoundaryAt(endPosition), const TextPosition(offset: 3, affinity: TextAffinity.upstream));
  });

  test('Character boundary works with grapheme', () {
    const String text = 'a❄︎c';
    const CharacterBoundary boundary = CharacterBoundary(text);
    TextPosition position = const TextPosition(offset: 1);
    expect(boundary.getLeadingTextBoundaryAt(position), const TextPosition(offset: 1));
    // The `❄` takes two character length.
    expect(boundary.getTrailingTextBoundaryAt(position), const TextPosition(offset: 3, affinity: TextAffinity.upstream));

    position = const TextPosition(offset: 2);
    expect(boundary.getLeadingTextBoundaryAt(position), const TextPosition(offset: 1));
    expect(boundary.getTrailingTextBoundaryAt(position), const TextPosition(offset: 3, affinity: TextAffinity.upstream));

    position = const TextPosition(offset: 0);
    expect(boundary.getLeadingTextBoundaryAt(position), const TextPosition(offset: 0));
    expect(boundary.getTrailingTextBoundaryAt(position), const TextPosition(offset: 1, affinity: TextAffinity.upstream));

    position = const TextPosition(offset: text.length);
    expect(boundary.getLeadingTextBoundaryAt(position), const TextPosition(offset: text.length, affinity: TextAffinity.upstream));
    expect(boundary.getTrailingTextBoundaryAt(position), const TextPosition(offset: text.length, affinity: TextAffinity.upstream));
  });

  test('word boundary works', () {
    final WordBoundary boundary = WordBoundary(TestTextLayoutMetrics());
    const TextPosition position = TextPosition(offset: 3);
    expect(boundary.getLeadingTextBoundaryAt(position).offset, TestTextLayoutMetrics.wordBoundaryAt3.start);
    expect(boundary.getTrailingTextBoundaryAt(position).offset, TestTextLayoutMetrics.wordBoundaryAt3.end);
  });

  test('line boundary works', () {
    final LineBreak boundary = LineBreak(TestTextLayoutMetrics());
    const TextPosition position = TextPosition(offset: 3);
    expect(boundary.getLeadingTextBoundaryAt(position).offset, TestTextLayoutMetrics.lineAt3.start);
    expect(boundary.getTrailingTextBoundaryAt(position).offset, TestTextLayoutMetrics.lineAt3.end);
  });

  test('document boundary works', () {
    const String text = 'abcd efg hi\njklmno\npqrstuv';
    const DocumentBoundary boundary = DocumentBoundary(text);
    const TextPosition position = TextPosition(offset: 10);
    expect(boundary.getLeadingTextBoundaryAt(position), const TextPosition(offset: 0));
    expect(boundary.getTrailingTextBoundaryAt(position), const TextPosition(offset: text.length, affinity: TextAffinity.upstream));
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
