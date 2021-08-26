// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextBox, BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

const String _kText = "I polished up that handle so carefullee\nThat now I am the Ruler of the Queen's Navee!";

// A subclass of RenderParagraph that returns an empty list in getBoxesForSelection
// for a given TextSelection.
// This is intended to simulate SkParagraph's implementation of Paragraph.getBoxesForRange,
// which may return an empty list in some situations where Libtxt would return a list
// containing an empty box.
class RenderParagraphWithEmptySelectionBoxList extends RenderParagraph {
  RenderParagraphWithEmptySelectionBoxList(
    InlineSpan text, {
    required TextDirection textDirection,
    required this.emptyListSelection,
  }) : super(text, textDirection: textDirection);

  TextSelection emptyListSelection;

  @override
  List<ui.TextBox> getBoxesForSelection(
    TextSelection selection, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    if (selection == emptyListSelection) {
      return <ui.TextBox>[];
    }
    return super.getBoxesForSelection(
      selection,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
  }
}

// A subclass of RenderParagraph that returns an empty list in getBoxesForSelection
// for a selection representing a WidgetSpan.
// This is intended to simulate how SkParagraph's implementation of Paragraph.getBoxesForRange
// can return an empty list for a WidgetSpan with empty dimensions.
class RenderParagraphWithEmptyBoxListForWidgetSpan extends RenderParagraph {
  RenderParagraphWithEmptyBoxListForWidgetSpan(
    InlineSpan text, {
    required List<RenderBox> children,
    required TextDirection textDirection,
  }) : super(text, children: children, textDirection: textDirection);

  @override
  List<ui.TextBox> getBoxesForSelection(
    TextSelection selection, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    if (text.getSpanForPosition(selection.base) is WidgetSpan) {
      return <ui.TextBox>[];
    }
    return super.getBoxesForSelection(
      selection,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
  }
}

void main() {
  test('getOffsetForCaret control test', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph);

    const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);

    final Offset offset5 = paragraph.getOffsetForCaret(const TextPosition(offset: 5), caret);
    expect(offset5.dx, greaterThan(0.0));

    final Offset offset25 = paragraph.getOffsetForCaret(const TextPosition(offset: 25), caret);
    expect(offset25.dx, greaterThan(offset5.dx));

    final Offset offset50 = paragraph.getOffsetForCaret(const TextPosition(offset: 50), caret);
    expect(offset50.dy, greaterThan(offset5.dy));
  });

  test('getFullHeightForCaret control test', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText,style: TextStyle(fontSize: 10.0)),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph);

    final double height5 = paragraph.getFullHeightForCaret(const TextPosition(offset: 5))!;
    expect(height5, equals(10.0));
  });

  test('getPositionForOffset control test', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph);

    final TextPosition position20 = paragraph.getPositionForOffset(const Offset(20.0, 5.0));
    expect(position20.offset, greaterThan(0.0));

    final TextPosition position40 = paragraph.getPositionForOffset(const Offset(40.0, 5.0));
    expect(position40.offset, greaterThan(position20.offset));

    final TextPosition positionBelow = paragraph.getPositionForOffset(const Offset(5.0, 20.0));
    expect(positionBelow.offset, greaterThan(position40.offset));
  });

  test('getBoxesForSelection control test', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText, style: TextStyle(fontSize: 10.0)),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph);

    List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 5, extentOffset: 25),
    );

    expect(boxes.length, equals(1));

    boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 25, extentOffset: 50),
    );

    expect(boxes.any((ui.TextBox box) => box.left == 250 && box.top == 0), isTrue);
    expect(boxes.any((ui.TextBox box) => box.right == 100 && box.top == 10), isTrue);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61016

  test('getBoxesForSelection test with multiple TextSpans and lines', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        text: 'First ',
        style: TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
        children: <InlineSpan>[
          TextSpan(text: 'smallsecond ', style: TextStyle(fontSize: 5.0)),
          TextSpan(text: 'third fourth fifth'),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    // Do layout with width chosen so that this splits as
    // First smallsecond |
    // third fourth |
    // fifth|
    // The corresponding line widths come out to be:
    // 1st line: 120px wide: 6 chars * 10px plus 12 chars * 5px.
    // 2nd line: 130px wide: 13 chars * 10px.
    // 3rd line: 50px wide.
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 140.0));

    final List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 36),
    );

    expect(boxes.length, equals(4));

    // The widths of the boxes should match the calculations above.
    // The heights should all be 10, except for the box for 'smallsecond ',
    // which should have height 5, and be alphabetic baseline-aligned with
    // 'First '. The Ahem font specifies alphabetic baselines at 0.2em above the
    // bottom extent, and 0.8em below the top, so the difference in top
    // alignment becomes (10px * 0.8 - 5px * 0.8) = 4px.

    // 'First ':
    expect(boxes[0], const TextBox.fromLTRBD(0.0, 0.0, 60.0, 10.0, TextDirection.ltr));
    // 'smallsecond ' in size 5:
    expect(boxes[1], const TextBox.fromLTRBD(60.0, 4.0, 120.0, 9.0, TextDirection.ltr));
    // 'third fourth ':
    expect(boxes[2], const TextBox.fromLTRBD(0.0, 10.0, 130.0, 20.0, TextDirection.ltr));
    // 'fifth':
    expect(boxes[3], const TextBox.fromLTRBD(0.0, 20.0, 50.0, 30.0, TextDirection.ltr));
  }, skip: !isLinux); // mac typography values can differ https://github.com/flutter/flutter/issues/12357

  test('getBoxesForSelection test with boxHeightStyle and boxWidthStyle set to max', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        text: 'First ',
        style: TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
        children: <InlineSpan>[
          TextSpan(text: 'smallsecond ', style: TextStyle(fontSize: 8.0)),
          TextSpan(text: 'third fourth fifth'),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    // Do layout with width chosen so that this splits as
    // First smallsecond |
    // third fourth |
    // fifth|
    // The corresponding line widths come out to be:
    // 1st line: 156px wide: 6 chars * 10px plus 12 chars * 8px.
    // 2nd line: 130px wide: 13 chars * 10px.
    // 3rd line: 50px wide.
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 160.0));

    final List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 36),
      boxHeightStyle: ui.BoxHeightStyle.max,
      boxWidthStyle: ui.BoxWidthStyle.max,
    );

    expect(boxes.length, equals(5));

    // 'First ':
    expect(boxes[0], const TextBox.fromLTRBD(0.0, 0.0, 60.0, 10.0, TextDirection.ltr));
    // 'smallsecond ' in size 8, but on same line as previous box, so height remains 10:
    expect(boxes[1], const TextBox.fromLTRBD(60.0, 0.0, 156.0, 10.0, TextDirection.ltr));
    // 'third fourth ':
    expect(boxes[2], const TextBox.fromLTRBD(0.0, 10.0, 130.0, 20.0, TextDirection.ltr));
    // extra box added to extend width, as per definition of ui.BoxWidthStyle.max:
    expect(boxes[3], const TextBox.fromLTRBD(130.0, 10.0, 156.0, 20.0, TextDirection.ltr));
    // 'fifth':
    expect(boxes[4], const TextBox.fromLTRBD(0.0, 20.0, 50.0, 30.0, TextDirection.ltr));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61016

  test('getWordBoundary control test', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph);

    final TextRange range5 = paragraph.getWordBoundary(const TextPosition(offset: 5));
    expect(range5.textInside(_kText), equals('polished'));

    final TextRange range50 = paragraph.getWordBoundary(const TextPosition(offset: 50));
    expect(range50.textInside(_kText), equals(' '));

    final TextRange range85 = paragraph.getWordBoundary(const TextPosition(offset: 75));
    expect(range85.textInside(_kText), equals("Queen's"));
  });

  test('overflow test', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        text: 'This\n' // 4 characters * 10px font size = 40px width on the first line
              'is a wrapping test. It should wrap at manual newlines, and if softWrap is true, also at spaces.',
        style: TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      softWrap: true,
    );

    void relayoutWith({
      int? maxLines,
      required bool softWrap,
      required TextOverflow overflow,
    }) {
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
    expect(paragraph.size.height, equals(3 * lineHeight));

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
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61018

  test('maxLines', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        text: "How do you write like you're running out of time? Write day and night like you're running out of time?",
            // 0123456789 0123456789 012 345 0123456 012345 01234 012345678 012345678 0123 012 345 0123456 012345 01234
            // 0          1          2       3       4      5     6         7         8    9       10      11     12
        style: TextStyle(fontFamily: 'Ahem', fontSize: 10.0),
      ),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 100.0));
    void layoutAt(int? maxLines) {
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
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61018

  test('changing color does not do layout', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        text: 'Hello',
        style: TextStyle(color: Color(0xFF000000)),
      ),
      textDirection: TextDirection.ltr,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 100.0), phase: EnginePhase.paint);
    expect(paragraph.debugNeedsLayout, isFalse);
    expect(paragraph.debugNeedsPaint, isFalse);
    paragraph.text = const TextSpan(
      text: 'Hello World',
      style: TextStyle(color: Color(0xFF000000)),
    );
    expect(paragraph.debugNeedsLayout, isTrue);
    expect(paragraph.debugNeedsPaint, isFalse);
    pumpFrame(phase: EnginePhase.paint);
    expect(paragraph.debugNeedsLayout, isFalse);
    expect(paragraph.debugNeedsPaint, isFalse);
    paragraph.text = const TextSpan(
      text: 'Hello World',
      style: TextStyle(color: Color(0xFFFFFFFF)),
    );
    expect(paragraph.debugNeedsLayout, isFalse);
    expect(paragraph.debugNeedsPaint, isTrue);
    pumpFrame(phase: EnginePhase.paint);
    expect(paragraph.debugNeedsLayout, isFalse);
    expect(paragraph.debugNeedsPaint, isFalse);
  });

  test('nested TextSpans in paragraph handle textScaleFactor correctly.', () {
    const TextSpan testSpan = TextSpan(
      text: 'a',
      style: TextStyle(
        fontSize: 10.0,
      ),
      children: <TextSpan>[
        TextSpan(
          text: 'b',
          children: <TextSpan>[
            TextSpan(text: 'c'),
          ],
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
        TextSpan(
          text: 'd',
        ),
      ],
    );
    final RenderParagraph paragraph = RenderParagraph(
        testSpan,
        textDirection: TextDirection.ltr,
        textScaleFactor: 1.3,
    );
    paragraph.layout(const BoxConstraints());
    // anyOf is needed here because Linux and Mac have different text
    // rendering widths in tests.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(paragraph.size.width, anyOf(79.0, 78.0));
    expect(paragraph.size.height, 26.0);

    // Test the sizes of nested spans.
    final String text = testSpan.toStringDeep();
    final List<ui.TextBox> boxes = <ui.TextBox>[
      for (int i = 0; i < text.length; ++i)
        ...paragraph.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1),
        ),
    ];
    expect(boxes.length, equals(4));

    // anyOf is needed here and below because Linux and Mac have different text
    // rendering widths in tests.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(boxes[0].toRect().width, anyOf(14.0, 13.0));
    expect(boxes[0].toRect().height, moreOrLessEquals(13.0, epsilon: 0.0001));
    expect(boxes[1].toRect().width, anyOf(27.0, 26.0));
    expect(boxes[1].toRect().height, moreOrLessEquals(26.0, epsilon: 0.0001));
    expect(boxes[2].toRect().width, anyOf(27.0, 26.0));
    expect(boxes[2].toRect().height, moreOrLessEquals(26.0, epsilon: 0.0001));
    expect(boxes[3].toRect().width, anyOf(14.0, 13.0));
    expect(boxes[3].toRect().height, moreOrLessEquals(13.0, epsilon: 0.0001));
  });

  test('toStringDeep', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText),
      textDirection: TextDirection.ltr,
      locale: const Locale('ja', 'JP'),
    );
    expect(paragraph, hasAGoodToStringDeep);
    expect(
      paragraph.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderParagraph#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
        ' │ parentData: MISSING\n'
        ' │ constraints: MISSING\n'
        ' │ size: MISSING\n'
        ' │ textAlign: start\n'
        ' │ textDirection: ltr\n'
        ' │ softWrap: wrapping at box width\n'
        ' │ overflow: clip\n'
        ' │ locale: ja_JP\n'
        ' │ maxLines: unlimited\n'
        ' ╘═╦══ text ═══\n'
        '   ║ TextSpan:\n'
        '   ║   "I polished up that handle so carefullee\n'
        '   ║   That now I am the Ruler of the Queen\'s Navee!"\n'
        '   ╚═══════════\n',
      ),
    );
  });

  test('locale setter', () {
    // Regression test for https://github.com/flutter/flutter/issues/18175

    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: _kText),
      locale: const Locale('zh', 'HK'),
      textDirection: TextDirection.ltr,
    );
    expect(paragraph.locale, const Locale('zh', 'HK'));

    paragraph.locale = const Locale('ja', 'JP');
    expect(paragraph.locale, const Locale('ja', 'JP'));
  });

  test('inline widgets test', () {
    const TextSpan text = TextSpan(
      text: 'a',
      style: TextStyle(fontSize: 10.0),
      children: <InlineSpan>[
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        TextSpan(text: 'a'),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
      ],
    );
    // Fake the render boxes that correspond to the WidgetSpans. We use
    // RenderParagraph to reduce dependencies this test has.
    final List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
    ];

    final RenderParagraph paragraph = RenderParagraph(
      text,
      textDirection: TextDirection.ltr,
      children: renderBoxes,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 100.0));

    final List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 8),
    );

    expect(boxes.length, equals(5));
    expect(boxes[0], const TextBox.fromLTRBD(0.0, 4.0, 10.0, 14.0, TextDirection.ltr));
    expect(boxes[1], const TextBox.fromLTRBD(10.0, 0.0, 24.0, 14.0, TextDirection.ltr));
    expect(boxes[2], const TextBox.fromLTRBD(24.0, 0.0, 38.0, 14.0, TextDirection.ltr));
    expect(boxes[3], const TextBox.fromLTRBD(38.0, 4.0, 48.0, 14.0, TextDirection.ltr));
    expect(boxes[4], const TextBox.fromLTRBD(48.0, 0.0, 62.0, 14.0, TextDirection.ltr));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

  test('getBoxesForSelection with boxHeightStyle for inline widgets', () {
    const TextSpan text = TextSpan(
      text: 'a',
      style: TextStyle(fontSize: 10.0),
      children: <InlineSpan>[
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        TextSpan(text: 'a'),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
      ],
    );
    // Fake the render boxes that correspond to the WidgetSpans. We use
    // RenderParagraph to reduce the dependencies this test has. The dimensions
    // of these get used in place of the widths and heights specified in the
    // SizedBoxes above: each comes out as (w,h) = (14,14).
    final List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
    ];

    final RenderParagraph paragraph = RenderParagraph(
      text,
      textDirection: TextDirection.ltr,
      children: renderBoxes,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 100.0));

    final List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 8),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );

    expect(boxes.length, equals(5));
    expect(boxes[0], const TextBox.fromLTRBD(0.0, 0.0, 10.0, 14.0, TextDirection.ltr));
    expect(boxes[1], const TextBox.fromLTRBD(10.0, 0.0, 24.0, 14.0, TextDirection.ltr));
    expect(boxes[2], const TextBox.fromLTRBD(24.0, 0.0, 38.0, 14.0, TextDirection.ltr));
    expect(boxes[3], const TextBox.fromLTRBD(38.0, 0.0, 48.0, 14.0, TextDirection.ltr));
    expect(boxes[4], const TextBox.fromLTRBD(48.0, 0.0, 62.0, 14.0, TextDirection.ltr));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

  test('can compute IntrinsicHeight for widget span', () {
    // Regression test for https://github.com/flutter/flutter/issues/59316
    const double screenWidth = 100.0;
    const String sentence = 'one two';
    List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: sentence), textDirection: TextDirection.ltr),
    ];
    RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        children: <InlineSpan> [
          WidgetSpan(child: Text(sentence)),
        ],
      ),
      textScaleFactor: 1.0,
      children: renderBoxes,
      textDirection: TextDirection.ltr,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: screenWidth));
    final double singleLineHeight = paragraph.computeMaxIntrinsicHeight(screenWidth);
    expect(singleLineHeight, 14.0);

    pumpFrame();
    renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: sentence), textDirection: TextDirection.ltr),
    ];
    paragraph = RenderParagraph(
      const TextSpan(
        children: <InlineSpan> [
          WidgetSpan(child: Text(sentence)),
        ],
      ),
      textScaleFactor: 2.0,
      children: renderBoxes,
      textDirection: TextDirection.ltr,
    );

    layout(paragraph, constraints: const BoxConstraints(maxWidth: screenWidth));
    final double maxIntrinsicHeight = paragraph.computeMaxIntrinsicHeight(screenWidth);
    final double minIntrinsicHeight = paragraph.computeMinIntrinsicHeight(screenWidth);
    // intrinsicHeight = singleLineHeight * textScaleFactor * two lines.
    expect(maxIntrinsicHeight, singleLineHeight * 2.0 * 2);
    expect(maxIntrinsicHeight, minIntrinsicHeight);
  });

  test('can compute IntrinsicWidth for widget span', () {
    // Regression test for https://github.com/flutter/flutter/issues/59316
    const double screenWidth = 1000.0;
    const double fixedHeight = 1000.0;
    const String sentence = 'one two';
    List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: sentence), textDirection: TextDirection.ltr),
    ];
    RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        children: <InlineSpan> [
          WidgetSpan(child: Text(sentence)),
        ],
      ),
      textScaleFactor: 1.0,
      children: renderBoxes,
      textDirection: TextDirection.ltr,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: screenWidth));
    final double widthForOneLine = paragraph.computeMaxIntrinsicWidth(fixedHeight);
    expect(widthForOneLine, 98.0);

    pumpFrame();
    renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: sentence), textDirection: TextDirection.ltr),
    ];
    paragraph = RenderParagraph(
      const TextSpan(
        children: <InlineSpan> [
          WidgetSpan(child: Text(sentence)),
        ],
      ),
      textScaleFactor: 2.0,
      children: renderBoxes,
      textDirection: TextDirection.ltr,
    );

    layout(paragraph, constraints: const BoxConstraints(maxWidth: screenWidth));
    final double maxIntrinsicWidth = paragraph.computeMaxIntrinsicWidth(fixedHeight);
    // maxIntrinsicWidth = widthForOneLine * textScaleFactor
    expect(maxIntrinsicWidth, widthForOneLine * 2.0);
  });

  test('inline widgets multiline test', () {
    const TextSpan text = TextSpan(
      text: 'a',
      style: TextStyle(fontSize: 10.0),
      children: <InlineSpan>[
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        TextSpan(text: 'a'),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
        WidgetSpan(child: SizedBox(width: 21, height: 21)),
      ],
    );
    // Fake the render boxes that correspond to the WidgetSpans. We use
    // RenderParagraph to reduce dependencies this test has.
    final List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
    ];

    final RenderParagraph paragraph = RenderParagraph(
      text,
      textDirection: TextDirection.ltr,
      children: renderBoxes,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 50.0));

    final List<ui.TextBox> boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 12),
    );

    expect(boxes.length, equals(9));
    expect(boxes[0], const TextBox.fromLTRBD(0.0, 4.0, 10.0, 14.0, TextDirection.ltr));
    expect(boxes[1], const TextBox.fromLTRBD(10.0, 0.0, 24.0, 14.0, TextDirection.ltr));
    expect(boxes[2], const TextBox.fromLTRBD(24.0, 0.0, 38.0, 14.0, TextDirection.ltr));
    expect(boxes[3], const TextBox.fromLTRBD(38.0, 4.0, 48.0, 14.0, TextDirection.ltr));
    // Wraps
    expect(boxes[4], const TextBox.fromLTRBD(0.0, 14.0, 14.0, 28.0 , TextDirection.ltr));
    expect(boxes[5], const TextBox.fromLTRBD(14.0, 14.0, 28.0, 28.0, TextDirection.ltr));
    expect(boxes[6], const TextBox.fromLTRBD(28.0, 14.0, 42.0, 28.0, TextDirection.ltr));
    // Wraps
    expect(boxes[7], const TextBox.fromLTRBD(0.0, 28.0, 14.0, 42.0, TextDirection.ltr));
    expect(boxes[8], const TextBox.fromLTRBD(14.0, 28.0, 28.0, 42.0 , TextDirection.ltr));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

  test('Does not include the semantics node of truncated rendering children', () {
    // Regression test for https://github.com/flutter/flutter/issues/88180
    const double screenWidth = 100;
    const String sentence = 'truncated';
    final List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(
          const TextSpan(text: sentence), textDirection: TextDirection.ltr),
    ];
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(
        text: 'a long line to be truncated.',
        children: <InlineSpan>[
          WidgetSpan(child: Text(sentence)),
        ],
      ),
      overflow: TextOverflow.ellipsis,
      textScaleFactor: 1.0,
      children: renderBoxes,
      textDirection: TextDirection.ltr,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: screenWidth));
    final SemanticsNode result = SemanticsNode();
    final SemanticsNode truncatedChild = SemanticsNode();
    truncatedChild.tags = <SemanticsTag>{const PlaceholderSpanIndexSemanticsTag(0)};
    paragraph.assembleSemanticsNode(result, SemanticsConfiguration(), <SemanticsNode>[truncatedChild]);
    // It should only contain the semantics node of the TextSpan.
    expect(result.childrenCount, 1);
    result.visitChildren((SemanticsNode node) {
      expect(node != truncatedChild, isTrue);
      return true;
    });
  });

    test('Supports gesture recognizer semantics', () {
    final RenderParagraph paragraph = RenderParagraph(
      TextSpan(text: _kText, children: <InlineSpan>[
        TextSpan(text: 'one', recognizer: TapGestureRecognizer()..onTap = () {}),
        TextSpan(text: 'two', recognizer: LongPressGestureRecognizer()..onLongPress = () {}),
        TextSpan(text: 'three', recognizer: DoubleTapGestureRecognizer()..onDoubleTap = () {}),
      ]),
      textDirection: TextDirection.rtl,
    );
    layout(paragraph);

    paragraph.assembleSemanticsNode(SemanticsNode(), SemanticsConfiguration(), <SemanticsNode>[]);
  });

  test('Supports empty text span with spell out', () {
    final RenderParagraph paragraph = RenderParagraph(
      const TextSpan(text: '', spellOut: true),
      textDirection: TextDirection.rtl,
    );
    layout(paragraph);
    final SemanticsNode node = SemanticsNode();
    paragraph.assembleSemanticsNode(node, SemanticsConfiguration(), <SemanticsNode>[]);
    expect(node.attributedLabel.string, '');
    expect(node.attributedLabel.attributes.length, 0);
  });

  test('Asserts on unsupported gesture recognizer', () {
    final RenderParagraph paragraph = RenderParagraph(
      TextSpan(text: _kText, children: <InlineSpan>[
        TextSpan(text: 'three', recognizer: MultiTapGestureRecognizer()..onTap = (int id) {}),
      ]),
      textDirection: TextDirection.rtl,
    );
    layout(paragraph);

    bool failed = false;
    try {
      paragraph.assembleSemanticsNode(SemanticsNode(), SemanticsConfiguration(), <SemanticsNode>[]);
    } on AssertionError catch (e) {
      failed = true;
      expect(e.message, 'MultiTapGestureRecognizer is not supported.');
    }
    expect(failed, true);
  });

  test('assembleSemanticsNode handles text spans that do not yield selection boxes', () {
    final RenderParagraph paragraph = RenderParagraphWithEmptySelectionBoxList(
      TextSpan(text: '', children: <InlineSpan>[
        TextSpan(text: 'A', recognizer: TapGestureRecognizer()..onTap = () {}),
        TextSpan(text: 'B', recognizer: TapGestureRecognizer()..onTap = () {}),
        TextSpan(text: 'C', recognizer: TapGestureRecognizer()..onTap = () {}),
      ]),
      textDirection: TextDirection.rtl,
      emptyListSelection: const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    layout(paragraph);

    final SemanticsNode node = SemanticsNode();
    paragraph.assembleSemanticsNode(node, SemanticsConfiguration(), <SemanticsNode>[]);
    expect(node.childrenCount, 2);
  });

  test('assembleSemanticsNode handles empty WidgetSpans that do not yield selection boxes', () {
    final TextSpan text = TextSpan(text: '', children: <InlineSpan>[
      TextSpan(text: 'A', recognizer: TapGestureRecognizer()..onTap = () {}),
      const WidgetSpan(child: SizedBox(width: 0, height: 0)),
      TextSpan(text: 'C', recognizer: TapGestureRecognizer()..onTap = () {}),
    ]);
    final List<RenderBox> renderBoxes = <RenderBox>[
      RenderParagraph(const TextSpan(text: 'b'), textDirection: TextDirection.ltr),
    ];
    final RenderParagraph paragraph = RenderParagraphWithEmptyBoxListForWidgetSpan(
      text,
      children: renderBoxes,
      textDirection: TextDirection.ltr,
    );
    layout(paragraph);

    final SemanticsNode node = SemanticsNode();
    paragraph.assembleSemanticsNode(node, SemanticsConfiguration(), <SemanticsNode>[]);
    expect(node.childrenCount, 2);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020
}
