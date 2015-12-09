// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'box.dart';
import 'object.dart';
import 'paragraph.dart';
import 'proxy_box.dart' show SizeChangedCallback;

const _kCursorGap = 1.0; // pixels
const _kCursorHeightOffset = 2.0; // pixels
const _kCursorWidth = 1.0; // pixels

/// A render object used by EditableText widgets.  This is similar to
/// RenderParagraph but also renders a cursor and provides support for
/// scrolling.
class RenderEditableParagraph extends RenderParagraph {

  RenderEditableParagraph({
    TextSpan text,
    Color cursorColor,
    bool showCursor,
    this.onContentSizeChanged,
    Offset scrollOffset
  }) : _cursorColor = cursorColor,
       _showCursor = showCursor,
       _scrollOffset = scrollOffset,
       super(text);

  SizeChangedCallback onContentSizeChanged;
  Size _contentSize;

  Color get cursorColor => _cursorColor;
  Color _cursorColor;
  void set cursorColor(Color value) {
    if (_cursorColor == value)
      return;
    _cursorColor = value;
    markNeedsPaint();
  }

  bool get showCursor => _showCursor;
  bool _showCursor;
  void set showCursor(bool value) {
    if (_showCursor == value)
      return;
    _showCursor = value;
    markNeedsPaint();
  }

  Offset get scrollOffset => _scrollOffset;
  Offset _scrollOffset;
  void set scrollOffset(Offset value) {
    if (_scrollOffset == value)
      return;
    _scrollOffset = value;
    markNeedsPaint();
  }

  BoxConstraints _getTextContraints(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return new BoxConstraints(
      minWidth: 0.0,
      maxWidth: double.INFINITY,
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight
    );
  }

  double _getIntrinsicWidth(BoxConstraints constraints) {
    // There should be no difference between the minimum and maximum width
    // because we only support single-line text.
    layoutText(_getTextContraints(constraints));
    return constraints.constrainWidth(
      textPainter.width + _kCursorGap + _kCursorWidth
    );
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicWidth(constraints);
  }

  void performLayout() {
    layoutText(_getTextContraints(constraints));
    Size contentSize = new Size(textPainter.width + _kCursorGap + _kCursorWidth, textPainter.height);
    size = constraints.constrain(contentSize);

    if (_contentSize == null || _contentSize != contentSize) {
      _contentSize = contentSize;
      if (onContentSizeChanged != null)
        onContentSizeChanged(_contentSize);
    }
  }

  void _paintContents(PaintingContext context, Offset offset) {
    textPainter.paint(context.canvas, offset - _scrollOffset);

    if (_showCursor) {
      Rect cursorRect =  new Rect.fromLTWH(
        offset.dx + _contentSize.width - _kCursorWidth - _scrollOffset.dx,
        offset.dy + _kCursorHeightOffset - _scrollOffset.dy,
        _kCursorWidth,
        size.height - 2.0 * _kCursorHeightOffset
      );
      context.canvas.drawRect(cursorRect, new Paint()..color = _cursorColor);
    }
  }

  void paint(PaintingContext context, Offset offset) {
    layoutText(_getTextContraints(constraints));
    final bool hasVisualOverflow = (_contentSize.width > size.width);
    if (hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
    else
      _paintContents(context, offset);
  }

}
