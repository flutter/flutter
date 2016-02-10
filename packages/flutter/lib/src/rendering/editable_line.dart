// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

import 'box.dart';
import 'object.dart';
import 'paragraph.dart';

const _kCaretGap = 1.0; // pixels
const _kCaretHeightOffset = 2.0; // pixels
const _kCaretWidth = 1.0; // pixels

final String _kZeroWidthSpace = new String.fromCharCode(0x200B);

/// A single line of editable text.
class RenderEditableLine extends RenderBox {
  RenderEditableLine({
    StyledTextSpan text,
    Color cursorColor,
    bool showCursor: false,
    Color selectionColor,
    TextSelection selection,
    Offset paintOffset: Offset.zero,
    this.onSelectionChanged,
    this.onContentSizeChanged
  }) : _textPainter = new TextPainter(text),
       _cursorColor = cursorColor,
       _showCursor = showCursor,
       _selection = selection,
       _paintOffset = paintOffset {
    assert(!showCursor || cursorColor != null);
    // TODO(abarth): These min/max values should be the default for TextPainter.
    _textPainter
      ..minWidth = 0.0
      ..maxWidth = double.INFINITY
      ..minHeight = 0.0
      ..maxHeight = double.INFINITY;
    _tap = new TapGestureRecognizer(router: Gesturer.instance.pointerRouter, gestureArena: Gesturer.instance.gestureArena)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapCancel = _handleTapCancel;
  }

  ValueChanged<Size> onContentSizeChanged;
  ValueChanged<TextSelection> onSelectionChanged;

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

  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  void set selectionColor(Color value) {
    if (_selectionColor == value)
      return;
    _selectionColor = value;
    markNeedsPaint();
  }

  List<ui.TextBox> _selectionRects;

  TextSelection get selection => _selection;
  TextSelection _selection;
  void set selection(TextSelection value) {
    if (_selection == value)
      return;
    _selection = value;
    _selectionRects = null;
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
    assert(constraints.debugAssertIsNormalized);
    return constraints.constrainWidth(0.0);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return constraints.constrainWidth(0.0);
  }

  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return constraints.constrainHeight(_preferredHeight);
  }

  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsNormalized);
    return constraints.constrainHeight(_preferredHeight);
  }

  bool hitTestSelf(Point position) => true;

  TapGestureRecognizer _tap;
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && onSelectionChanged != null)
      _tap.addPointer(event);
  }

  Point _lastTapDownPosition;
  void _handleTapDown(Point globalPosition) {
    _lastTapDownPosition = globalPosition;
  }

  void _handleTap() {
    assert(_lastTapDownPosition != null);
    final Point global = _lastTapDownPosition;
    _lastTapDownPosition = null;
    if (onSelectionChanged != null) {
      TextPosition position = _textPainter.getPositionForOffset(globalToLocal(global).toOffset());
      onSelectionChanged(new TextSelection.fromPosition(position));
    }
  }

  void _handleTapCancel() {
    _lastTapDownPosition = null;
  }

  BoxConstraints _constraintsForCurrentLayout; // when null, we don't have a current layout

  // TODO(abarth): This logic should live in TextPainter and be shared with RenderParagraph.
  void _layoutText(BoxConstraints constraints) {
    assert(constraints != null);
    assert(constraints.debugAssertIsNormalized);
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

  Rect _caretPrototype;

  void performLayout() {
    size = new Size(constraints.maxWidth, constraints.constrainHeight(_preferredHeight));
    _caretPrototype = new Rect.fromLTWH(0.0, _kCaretHeightOffset, _kCaretWidth, size.height - 2.0 * _kCaretHeightOffset);
    _selectionRects = null;
    _layoutText(new BoxConstraints(minHeight: constraints.minHeight, maxHeight: constraints.maxHeight));
    Size contentSize = new Size(_textPainter.width + _kCaretGap + _kCaretWidth, _textPainter.height);
    if (_contentSize != contentSize) {
      _contentSize = contentSize;
      if (onContentSizeChanged != null)
        onContentSizeChanged(_contentSize);
    }
  }

  void _paintCaret(Canvas canvas, Offset effectiveOffset) {
    Offset caretOffset = _textPainter.getOffsetForCaret(_selection.extent, _caretPrototype);
    Paint paint = new Paint()..color = _cursorColor;
    canvas.drawRect(_caretPrototype.shift(caretOffset + effectiveOffset), paint);
  }

  void _paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(_selectionRects != null);
    Paint paint = new Paint()..color = _selectionColor;
    for (ui.TextBox box in _selectionRects) {
      Rect selectionRect = new Rect.fromLTWH(
        effectiveOffset.dx + box.left,
        effectiveOffset.dy + _kCaretHeightOffset,
        box.right - box.left,
        size.height - 2.0 * _kCaretHeightOffset
      );
      canvas.drawRect(selectionRect, paint);
    }
  }

  void _paintContents(PaintingContext context, Offset offset) {
    Offset effectiveOffset = offset + _paintOffset;

    if (_selection != null) {
      if (_selection.isCollapsed && _showCursor && cursorColor != null) {
        _paintCaret(context.canvas, effectiveOffset);
      } else if (!_selection.isCollapsed && _selectionColor != null) {
        _selectionRects ??= _textPainter.getBoxesForSelection(_selection);
        _paintSelection(context.canvas, effectiveOffset);
      }
    }

    _textPainter.paint(context.canvas, effectiveOffset);
  }

  bool get _hasVisualOverflow => _contentSize.width > size.width;

  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
    else
      _paintContents(context, offset);
  }

  Rect describeApproximatePaintClip(RenderObject child) => _hasVisualOverflow ? Point.origin & size : null;
}
