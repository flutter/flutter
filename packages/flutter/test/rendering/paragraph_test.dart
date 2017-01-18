// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextBox;

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

const String _kText = 'I polished up that handle so carefullee\nThat now I am the Ruler of the Queen\'s Navee!';

void main() {
  test('getOffsetForCaret control test', () {
    RenderParagraph paragraph = new RenderParagraph(new TextSpan(text: _kText));
    layout(paragraph);

    Rect caret = new Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);

    Offset offset5 = paragraph.getOffsetForCaret(new TextPosition(offset: 5), caret);
    expect(offset5.dx, greaterThan(0.0));

    Offset offset25 = paragraph.getOffsetForCaret(new TextPosition(offset: 25), caret);
    expect(offset25.dx, greaterThan(offset5.dx));

    Offset offset50 = paragraph.getOffsetForCaret(new TextPosition(offset: 50), caret);
    expect(offset50.dy, greaterThan(offset5.dy));
  });

  test('getPositionForOffset control test', () {
    RenderParagraph paragraph = new RenderParagraph(new TextSpan(text: _kText));
    layout(paragraph);

    TextPosition position20 = paragraph.getPositionForOffset(new Offset(20.0, 5.0));
    expect(position20.offset, greaterThan(0.0));

    TextPosition position40 = paragraph.getPositionForOffset(new Offset(40.0, 5.0));
    expect(position40.offset, greaterThan(position20.offset));

    TextPosition positionBelow = paragraph.getPositionForOffset(new Offset(5.0, 20.0));
    expect(positionBelow.offset, greaterThan(position40.offset));
  });

  test('getBoxesForSelection control test', () {
    RenderParagraph paragraph = new RenderParagraph(new TextSpan(text: _kText));
    layout(paragraph);

    List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      new TextSelection(baseOffset: 5, extentOffset: 25)
    );

    expect(boxes.length, equals(1));

    boxes = paragraph.getBoxesForSelection(
      new TextSelection(baseOffset: 25, extentOffset: 50)
    );

    expect(boxes.length, equals(3));
  });

  test('getWordBoundary control test', () {
    RenderParagraph paragraph = new RenderParagraph(new TextSpan(text: _kText));
    layout(paragraph);

    TextRange range5 = paragraph.getWordBoundary(new TextPosition(offset: 5));
    expect(range5.textInside(_kText), equals('polished'));

    TextRange range50 = paragraph.getWordBoundary(new TextPosition(offset: 50));
    expect(range50.textInside(_kText), equals(' '));

    TextRange range85 = paragraph.getWordBoundary(new TextPosition(offset: 75));
    expect(range85.textInside(_kText), equals('Queen\'s'));
  });

  test('overflow test', () {
    RenderParagraph paragraph = new RenderParagraph(
      new TextSpan(text: 'This is\na wrapping test. It should wrap at manual newlines, and if softWrap is true, also at spaces.'),
      maxLines: 1,
      softWrap: true,
    );

    void relayoutWith({int maxLines, bool softWrap, TextOverflow overflow}) {
      paragraph
        ..maxLines = maxLines
        ..softWrap = softWrap
        ..overflow = overflow;
      pumpFrame();
    }

    // Lay out in a narrow box to force wrapping.
    layout(paragraph, constraints: new BoxConstraints(maxWidth: 50.0));
    double lineHeight = paragraph.size.height;

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
  });
}
