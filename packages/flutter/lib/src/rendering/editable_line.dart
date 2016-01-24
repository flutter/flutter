// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'box.dart';
import 'object.dart';
import 'paragraph.dart';
import 'proxy_box.dart' show SizeChangedCallback;

const _kCursorGap = 1.0; // pixels
const _kCursorHeightOffset = 2.0; // pixels
const _kCursorWidth = 1.0; // pixels

final String _kZeroWidthSpace = new String.fromCharCode(0x200B);

/// A single line of editable text.
class RenderEditableLine extends RenderBox {
  RenderEditableLine({
    StyledTextSpan text,
    Color cursorColor,
    bool showCursor: false,
    Offset paintOffset: Offset.zero,
    this.onContentSizeChanged
  }) : _textPainter = new TextPainter(text),
       _cursorColor = cursorColor,
       _showCursor = showCursor,
       _paintOffset = paintOffset {
  assert(!showCursor || cursorColor != null);
  // TODO(abarth): These min/max values should be the default for TextPainter.
  _textPainter
    ..minWidth = 0.0
    ..maxWidth = double.INFINITY
    ..minHeight = 0.0
    ..maxHeight = double.INFINITY;
  }

  SizeChangedCallback onContentSizeChanged;

  /// The text to display
  StyledTextSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  void set text(StyledTextSpan value) {
    if (_textPainter.text == value)
      return;
    StyledTextSpan oldStyledText = _textPainter.text;
    if (oldStyledText.style != value.style)
      _layoutTemplate = null;
    _textPainter.text = value;
    _constraintsForCurrentLayout = null;
    markNeedsLayout();
  }

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

  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  void set paintOffset(Offset value) {
    if (_paintOffset == value)
      return;
    _paintOffset = value;
    markNeedsPaint();
  }

  Size _contentSize;

  ui.Paragraph _layoutTemplate;
  double get _preferredHeight {
    if (_layoutTemplate == null) {
      ui.ParagraphBuilder builder = new ui.ParagraphBuilder()
        ..pushStyle(text.style.textStyle)
        ..addText(_kZeroWidthSpace);
      // TODO(abarth): ParagraphBuilder#build's argument should be optional.
      // TODO(abarth): These min/max values should be the default for ui.Paragraph.
      _layoutTemplate = builder.build(new ui.ParagraphStyle())
        ..minWidth = 0.0
        ..maxWidth = double.INFINITY
        ..minHeight = 0.0
        ..maxHeight = double.INFINITY
        ..layout();
    }
    return _layoutTemplate.height;
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainHeight(_preferredHeight);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.isNormalized);
    return constraints.constrainHeight(_preferredHeight);
  }

  bool hitTestSelf(Point position) => true;

  BoxConstraints _constraintsForCurrentLayout; // when null, we don't have a current layout

  // TODO(abarth): This logic should live in TextPainter and be shared with RenderParagraph.
  void _layoutText(BoxConstraints constraints) {
    assert(constraints != null);
    assert(constraints.isNormalized);
    if (_constraintsForCurrentLayout == constraints)
      return; // already cached this layout
    _textPainter.maxWidth = constraints.maxWidth;
    _textPainter.minWidth = constraints.minWidth;
    _textPainter.minHeight = constraints.minHeight;
    _textPainter.maxHeight = constraints.maxHeight;
    _textPainter.layout();
    // By default, we shrinkwrap to the intrinsic width.
    double width = constraints.constrainWidth(_textPainter.maxIntrinsicWidth);
    _textPainter.minWidth = width;
    _textPainter.maxWidth = width;
    _textPainter.layout();
    _constraintsForCurrentLayout = constraints;
  }

  void performLayout() {
    size = new Size(constraints.maxWidth, constraints.constrainHeight(_preferredHeight));
    _layoutText(new BoxConstraints(minHeight: constraints.minHeight, maxHeight: constraints.maxHeight));
    Size contentSize = new Size(_textPainter.width + _kCursorGap + _kCursorWidth, _textPainter.height);
    if (_contentSize != contentSize) {
      _contentSize = contentSize;
      if (onContentSizeChanged != null)
        onContentSizeChanged(_contentSize);
    }
  }

  void _paintContents(PaintingContext context, Offset offset) {
    _textPainter.paint(context.canvas, offset + _paintOffset);

    if (_showCursor) {
      Rect cursorRect =  new Rect.fromLTWH(
        offset.dx + _paintOffset.dx + _contentSize.width - _kCursorWidth,
        offset.dy + _paintOffset.dy + _kCursorHeightOffset,
        _kCursorWidth,
        size.height - 2.0 * _kCursorHeightOffset
      );
      context.canvas.drawRect(cursorRect, new Paint()..color = _cursorColor);
    }
  }

  void paint(PaintingContext context, Offset offset) {
    final bool hasVisualOverflow = (_contentSize.width > size.width);
    if (hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
    else
      _paintContents(context, offset);
  }
}
