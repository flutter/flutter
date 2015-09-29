// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/src/painting/text_painter.dart';
import 'package:sky/src/rendering/box.dart';
import 'package:sky/src/rendering/object.dart';

export 'package:sky/src/painting/text_painter.dart';

/// A render object that displays a paragraph of text
class RenderParagraph extends RenderBox {

  RenderParagraph(
    TextSpan text
  ) : textPainter = new TextPainter(text) {
    assert(text != null);
  }

  final TextPainter textPainter;

  BoxConstraints _constraintsForCurrentLayout; // when null, we don't have a current layout

  /// The text to display
  TextSpan get text => textPainter.text;
  void set text(TextSpan value) {
    if (textPainter.text == value)
      return;
    textPainter.text = value;
    _constraintsForCurrentLayout = null;
    markNeedsLayout();
  }

  // Whether the text should be allowed to wrap to multiple lines.
  bool get allowLineWrap => true;

  void layoutText(BoxConstraints constraints) {
    assert(constraints != null);
    if (_constraintsForCurrentLayout == constraints)
      return; // already cached this layout
    textPainter.maxWidth = allowLineWrap ? constraints.maxWidth : double.INFINITY;
    textPainter.minWidth = constraints.minWidth;
    textPainter.minHeight = constraints.minHeight;
    textPainter.maxHeight = constraints.maxHeight;
    textPainter.layout();
    _constraintsForCurrentLayout = constraints;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    layoutText(constraints);
    return constraints.constrainWidth(textPainter.minContentWidth);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    layoutText(constraints);
    return constraints.constrainWidth(textPainter.maxContentWidth);
  }

  double _getIntrinsicHeight(BoxConstraints constraints) {
    layoutText(constraints);
    return constraints.constrainHeight(textPainter.height);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    return _getIntrinsicHeight(constraints);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    layoutText(constraints);
    return textPainter.computeDistanceToActualBaseline(baseline);
  }

  void performLayout() {
    layoutText(constraints);

    // We use textPainter.maxContentWidth here, rather that textPainter.width,
    // because the latter is the width that it used to wrap the text, whereas
    // the former is the actual width of the text.
    size = constraints.constrain(new Size(textPainter.maxContentWidth,
                                          textPainter.height));
  }

  void paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    layoutText(constraints);
    textPainter.paint(context.canvas, offset);
  }

  // we should probably expose a way to do precise (inter-glpyh) hit testing

  String debugDescribeSettings(String prefix) {
    String result = '${super.debugDescribeSettings(prefix)}';
    result += '${prefix}text:\n${text.toString("$prefix  ")}\n';
    return result;
  }
}
