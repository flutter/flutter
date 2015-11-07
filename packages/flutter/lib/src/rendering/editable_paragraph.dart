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

  Color _cursorColor;
  bool _showCursor;
  SizeChangedCallback onContentSizeChanged;
  Offset _scrollOffset;

  Size _contentSize;

  Color get cursorColor => _cursorColor;
  void set cursorColor(Color value) {
    if (_cursorColor == value)
      return;
    _cursorColor = value;
    markNeedsPaint();
  }

  bool get showCursor => _showCursor;
  void set showCursor(bool value) {
    if (_showCursor == value)
      return;
    _showCursor = value;
    markNeedsPaint();
  }

  Offset get scrollOffset => _scrollOffset;
  void set scrollOffset(Offset value) {
    if (_scrollOffset == value)
      return;
    _scrollOffset = value;
    markNeedsPaint();
  }

  // Editable text does not support line wrap.
  bool get allowLineWrap => false;

  double _getIntrinsicWidth(BoxConstraints constraints) {
    // There should be no difference between the minimum and maximum width
    // because we only support single-line text.
    layoutText(constraints);
    return constraints.constrainWidth(
      textPainter.size.width + _kCursorGap + _kCursorWidth
    );
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicWidth(constraints);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    return _getIntrinsicWidth(constraints);
  }

  void performLayout() {
    layoutText(constraints);

    Offset cursorPadding = const Offset(_kCursorGap + _kCursorWidth, 0.0);
    Size newContentSize = textPainter.size + cursorPadding;
    size = constraints.constrain(newContentSize);

    if (_contentSize == null || _contentSize != newContentSize) {
      _contentSize = newContentSize;
      if (onContentSizeChanged != null)
        onContentSizeChanged(newContentSize);
    }
  }

  void paint(PaintingContext context, Offset offset) {
    layoutText(constraints);

    bool needsClipping = (_contentSize.width > size.width);
    if (needsClipping) {
      context.canvas.save();
      context.canvas.clipRect(offset & size);
    }

    textPainter.paint(context.canvas, offset - _scrollOffset);

    if (_showCursor) {
      Rect cursorRect =  new Rect.fromLTWH(
        textPainter.size.width + _kCursorGap,
        _kCursorHeightOffset,
        _kCursorWidth,
        size.height - 2.0 * _kCursorHeightOffset
      );
      context.canvas.drawRect(
        cursorRect.shift(offset - _scrollOffset),
        new Paint()..color = _cursorColor
      );
    }

    if (needsClipping)
      context.canvas.restore();
  }

}
