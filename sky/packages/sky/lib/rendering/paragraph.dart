// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_painter.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

export 'package:sky/painting/text_painter.dart';

// Unfortunately, using full precision floating point here causes bad layouts
// because floating point math isn't associative. If we add and subtract
// padding, for example, we'll get different values when we estimate sizes and
// when we actually compute layout because the operations will end up associated
// differently. To work around this problem for now, we round fractional pixel
// values up to the nearest whole pixel value. The right long-term fix is to do
// layout using fixed precision arithmetic.
double _applyFloatingPointHack(double layoutValue) {
  return layoutValue.ceilToDouble();
}

class RenderParagraph extends RenderBox {

  RenderParagraph(TextSpan text) : _textPainter = new TextPainter(text) {
    assert(text != null);
  }

  TextPainter _textPainter;

  BoxConstraints _constraintsForCurrentLayout; // when null, we don't have a current layout

  TextSpan get text => _textPainter.text;
  void set text(TextSpan value) {
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    _constraintsForCurrentLayout = null;
    markNeedsLayout();
  }

  void _layout(BoxConstraints constraints) {
    assert(constraints != null);
    if (_constraintsForCurrentLayout == constraints)
      return; // already cached this layout
    _textPainter.maxWidth = constraints.maxWidth;
    _textPainter.minWidth = constraints.minWidth;
    _textPainter.minHeight = constraints.minHeight;
    _textPainter.maxHeight = constraints.maxHeight;
    _textPainter.layout();
    _constraintsForCurrentLayout = constraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainWidth(
        _applyFloatingPointHack(_textPainter.minContentWidth));
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainWidth(
        _applyFloatingPointHack(_textPainter.maxContentWidth));
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainHeight(
        _applyFloatingPointHack(_textPainter.height));
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    _layout(constraints);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  void performLayout() {
    _layout(constraints);
    // _paragraphPainter.width always expands to fill, use maxContentWidth instead.
    size = constraints.constrain(new Size(_applyFloatingPointHack(_textPainter.maxContentWidth),
                                          _applyFloatingPointHack(_textPainter.height)));
  }

  void paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    _layout(constraints);
    _textPainter.paint(context.canvas, offset);
  }

  // we should probably expose a way to do precise (inter-glpyh) hit testing

  String debugDescribeSettings(String prefix) {
    String result = '${super.debugDescribeSettings(prefix)}';
    result += '${prefix}text:\n${text.toString("$prefix  ")}\n';
    return result;
  }
}
