// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/paragraph_painter.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

export 'package:sky/painting/paragraph_painter.dart' show TextSpan, PlainTextSpan, StyledTextSpan;

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

  RenderParagraph(TextSpan text)
   : _paragraphPainter = new ParagraphPainter(text) {
    assert(text != null);
  }

  ParagraphPainter _paragraphPainter;

  BoxConstraints _constraintsForCurrentLayout; // when null, we don't have a current layout

  TextSpan get text => _paragraphPainter.text;
  void set text(TextSpan value) {
    if (_paragraphPainter.text == value)
      return;
    _paragraphPainter.text = value;
    _constraintsForCurrentLayout = null;
    markNeedsLayout();
  }

  void _layout(BoxConstraints constraints) {
    assert(constraints != null);
    if (_constraintsForCurrentLayout == constraints)
      return; // already cached this layout
    _paragraphPainter.maxWidth = constraints.maxWidth;
    _paragraphPainter.minWidth = constraints.minWidth;
    _paragraphPainter.minHeight = constraints.minHeight;
    _paragraphPainter.maxHeight = constraints.maxHeight;
    _paragraphPainter.layout();
    _constraintsForCurrentLayout = constraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainWidth(
        _applyFloatingPointHack(_paragraphPainter.minContentWidth));
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainWidth(
        _applyFloatingPointHack(_paragraphPainter.maxContentWidth));
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    _layout(constraints);
    return constraints.constrainHeight(
        _applyFloatingPointHack(_paragraphPainter.height));
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
    return _paragraphPainter.computeDistanceToActualBaseline(baseline);
  }

  void performLayout() {
    _layout(constraints);
    // _paragraphPainter.width always expands to fill, use maxContentWidth instead.
    size = constraints.constrain(new Size(_applyFloatingPointHack(_paragraphPainter.maxContentWidth),
                                          _applyFloatingPointHack(_paragraphPainter.height)));
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
    _paragraphPainter.paint(context.canvas, offset);
  }

  // we should probably expose a way to do precise (inter-glpyh) hit testing

  String debugDescribeSettings(String prefix) {
    String result = '${super.debugDescribeSettings(prefix)}';
    result += '${prefix}text:\n${text.toString("$prefix  ")}\n';
    return result;
  }
}
