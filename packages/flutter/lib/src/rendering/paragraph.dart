// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'box.dart';
import 'object.dart';
import 'semantics.dart';

/// A render object that displays a paragraph of text
class RenderParagraph extends RenderBox {

  RenderParagraph(TextSpan text, {
    TextAlign textAlign
  }) : _textPainter = new TextPainter(text: text, textAlign: textAlign) {
    assert(text != null);
    assert(text.debugAssertValid());
  }

  final TextPainter _textPainter;

  /// The text to display
  TextSpan get text => _textPainter.text;
  void set text(TextSpan value) {
    assert(value != null);
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    markNeedsLayout();
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  void set textAlign(TextAlign value) {
    if (_textPainter.textAlign == value)
      return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  void _layoutText(BoxConstraints constraints) {
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _textPainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    _layoutText(constraints);
    return constraints.constrainWidth(_textPainter.minIntrinsicWidth);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    _layoutText(constraints);
    return constraints.constrainWidth(_textPainter.maxIntrinsicWidth);
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    _layoutText(constraints);
    return constraints.constrainHeight(_textPainter.height);
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return _getIntrinsicHeight(constraints);
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return _getIntrinsicHeight(constraints);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    _layoutText(constraints);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerDownEvent)
      return;
    _layoutText(constraints);
    Offset offset = entry.localPosition.toOffset();
    TextPosition position = _textPainter.getPositionForOffset(offset);
    TextSpan span = _textPainter.text.getSpanForPosition(position);
    span?.recognizer?.addPointer(event);
  }

  @override
  void performLayout() {
    _layoutText(constraints);
    size = constraints.constrain(_textPainter.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    _layoutText(constraints);
    _textPainter.paint(context.canvas, offset);
  }

  @override
  Iterable<SemanticAnnotator> getSemanticAnnotators() sync* {
    yield (SemanticsNode node) {
      node.label = text.toPlainText();
    };
  }

  @override
  String debugDescribeChildren(String prefix) {
    return '$prefix \u2558\u2550\u2566\u2550\u2550 text \u2550\u2550\u2550\n'
           '${text.toString("$prefix   \u2551 ")}' // TextSpan includes a newline
           '$prefix   \u255A\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\n'
           '$prefix\n';
  }
}
