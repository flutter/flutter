// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextBox;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

// This file contains tests for deprecated members from paragraph_tests.dart
// ignore: deprecated_member_use

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
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    if (selection == emptyListSelection) {
      return <ui.TextBox>[];
    }
    return super.getBoxesForSelection(selection);
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
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    if (text.getSpanForPosition(selection.base) is WidgetSpan) {
      return <ui.TextBox>[];
    }
    return super.getBoxesForSelection(selection);
  }
}

void main() {
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
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

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
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

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
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

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
