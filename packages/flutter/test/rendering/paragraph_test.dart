// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextBox;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

const String _kText = 'I polished up that handle so carefullee\nThat now I am the Ruler of the Queen\'s Navee!';

void main() {
  test('getOffsetForCaret control test', () {
    final RenderParagraph paragraph = new RenderParagraph(const TextSpan(text: _kText));
    layout(paragraph);

    final Rect caret = new Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);

    final Offset offset5 = paragraph.getOffsetForCaret(const TextPosition(offset: 5), caret);
    expect(offset5.dx, greaterThan(0.0));

    final Offset offset25 = paragraph.getOffsetForCaret(const TextPosition(offset: 25), caret);
    expect(offset25.dx, greaterThan(offset5.dx));

    final Offset offset50 = paragraph.getOffsetForCaret(const TextPosition(offset: 50), caret);
    expect(offset50.dy, greaterThan(offset5.dy));
  });

  test('getPositionForOffset control test', () {
    final RenderParagraph paragraph = new RenderParagraph(const TextSpan(text: _kText));
    layout(paragraph);

    final TextPosition position20 = paragraph.getPositionForOffset(const Offset(20.0, 5.0));
    expect(position20.offset, greaterThan(0.0));

    final TextPosition position40 = paragraph.getPositionForOffset(const Offset(40.0, 5.0));
    expect(position40.offset, greaterThan(position20.offset));

    final TextPosition positionBelow = paragraph.getPositionForOffset(const Offset(5.0, 20.0));
    expect(positionBelow.offset, greaterThan(position40.offset));
  });

  test('getBoxesForSelection control test', () {
    final RenderParagraph paragraph = new RenderParagraph(const TextSpan(text: _kText));
    layout(paragraph);

    List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 5, extentOffset: 25)
    );

    expect(boxes.length, equals(1));

    boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 25, extentOffset: 50)
    );

    expect(boxes.length, equals(3));
  });

  test('getWordBoundary control test', () {
    final RenderParagraph paragraph = new RenderParagraph(const TextSpan(text: _kText));
    layout(paragraph);

    final TextRange range5 = paragraph.getWordBoundary(const TextPosition(offset: 5));
    expect(range5.textInside(_kText), equals('polished'));

    final TextRange range50 = paragraph.getWordBoundary(const TextPosition(offset: 50));
    expect(range50.textInside(_kText), equals(' '));

    final TextRange range85 = paragraph.getWordBoundary(const TextPosition(offset: 75));
    expect(range85.textInside(_kText), equals('Queen\'s'));
  });

  test('overflow test', () {
    final RenderParagraph paragraph = new RenderParagraph(
      const TextSpan(
        text: 'This\n' // 4 characters * 10px font size = 40px width on the first line
              'is a wrapping test. It should wrap at manual newlines, and if softWrap is true, also at spaces.',
        style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
      ),
      maxLines: 1,
      softWrap: true,
    );

    void relayoutWith({ int maxLines, bool softWrap, TextOverflow overflow }) {
      paragraph
        ..maxLines = maxLines
        ..softWrap = softWrap
        ..overflow = overflow;
      pumpFrame();
    }

    // Lay out in a narrow box to force wrapping.
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 50.0)); // enough to fit "This" but not "This is"
    final double lineHeight = paragraph.size.height;

    relayoutWith(maxLines: 3, softWrap: true, overflow: TextOverflow.clip);
    expect(paragraph.size.height, equals(3 * lineHeight));

    relayoutWith(maxLines: null, softWrap: true, overflow: TextOverflow.clip);
    expect(paragraph.size.height, greaterThan(5 * lineHeight));

    // Try again with ellipsis overflow. We can't test that the ellipsis are
    // drawn, but we can test the sizing.
    relayoutWith(maxLines: 1, softWrap: true, overflow: TextOverflow.ellipsis);
    expect(paragraph.size.height, equals(lineHeight));

    relayoutWith(maxLines: 3, softWrap: true, overflow: TextOverflow.ellipsis);
    expect(paragraph.size.height, equals(3 * lineHeight));

    // This is the one weird case. If maxLines is null, we would expect to allow
    // infinite wrapping. However, if we did, we'd never know when to append an
    // ellipsis, so this really means "append ellipsis as soon as we exceed the
    // width".
    relayoutWith(maxLines: null, softWrap: true, overflow: TextOverflow.ellipsis);
    expect(paragraph.size.height, equals(2 * lineHeight));

    // Now with no soft wrapping.
    relayoutWith(maxLines: 1, softWrap: false, overflow: TextOverflow.clip);
    expect(paragraph.size.height, equals(lineHeight));

    relayoutWith(maxLines: 3, softWrap: false, overflow: TextOverflow.clip);
    expect(paragraph.size.height, equals(2 * lineHeight));

    relayoutWith(maxLines: null, softWrap: false, overflow: TextOverflow.clip);
    expect(paragraph.size.height, equals(2 * lineHeight));

    relayoutWith(maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis);
    expect(paragraph.size.height, equals(lineHeight));

    relayoutWith(maxLines: 3, softWrap: false, overflow: TextOverflow.ellipsis);
    expect(paragraph.size.height, equals(2 * lineHeight));

    relayoutWith(maxLines: null, softWrap: false, overflow: TextOverflow.ellipsis);
    expect(paragraph.size.height, equals(2 * lineHeight));

    // Test presence of the fade effect.
    relayoutWith(maxLines: 3, softWrap: true, overflow: TextOverflow.fade);
    expect(paragraph.debugHasOverflowShader, isTrue);

    // Change back to ellipsis and check that the fade shader is cleared.
    relayoutWith(maxLines: 3, softWrap: true, overflow: TextOverflow.ellipsis);
    expect(paragraph.debugHasOverflowShader, isFalse);

    relayoutWith(maxLines: 100, softWrap: true, overflow: TextOverflow.fade);
    expect(paragraph.debugHasOverflowShader, isFalse);
  });


  test('maxLines', () {
    final RenderParagraph paragraph = new RenderParagraph(
      const TextSpan(
        text: 'How do you write like you\'re running out of time? Write day and night like you\'re running out of time?',
            // 0123456789 0123456789 012 345 0123456 012345 01234 012345678 012345678 0123 012 345 0123456 012345 01234
            // 0          1          2       3       4      5     6         7         8    9       10      11     12
        style: const TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
      ),
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 100.0));
    void layoutAt(int maxLines) {
      paragraph.maxLines = maxLines;
      pumpFrame();
    }

    layoutAt(null);
    expect(paragraph.size.height, 130.0);

    layoutAt(1);
    expect(paragraph.size.height, 10.0);

    layoutAt(2);
    expect(paragraph.size.height, 20.0);

    layoutAt(3);
    expect(paragraph.size.height, 30.0);
  });
}

