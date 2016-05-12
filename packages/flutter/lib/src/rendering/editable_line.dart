// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Paragraph, ParagraphBuilder, ParagraphConstraints, ParagraphStyle, TextBox;

import 'package:flutter/gestures.dart';

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels
const double _kCaretWidth = 1.0; // pixels

final String _kZeroWidthSpace = new String.fromCharCode(0x200B);

/// Called when the user changes the selection (including cursor location).
typedef void SelectionChangedHandler(TextSelection selection, RenderEditableLine renderObject);

/// Represents a global screen coordinate of the point in a selection, and the
/// text direction at that point.
class TextSelectionPoint {
  TextSelectionPoint(this.point, this.direction);

  /// Screen coordinates of the lower left or lower right corner of the selection.
  final Point point;

  /// Direction of the text at this edge of the selection.
  final TextDirection direction;
}

/// A single line of editable text.
class RenderEditableLine extends RenderBox {
  RenderEditableLine({
    TextSpan text,
    Color cursorColor,
    bool showCursor: false,
    Color selectionColor,
    TextSelection selection,
    this.onSelectionChanged,
    Offset paintOffset: Offset.zero,
    this.onPaintOffsetUpdateNeeded
  }) : _textPainter = new TextPainter(text: text),
       _cursorColor = cursorColor,
       _showCursor = showCursor,
       _selection = selection,
       _paintOffset = paintOffset {
    assert(!showCursor || cursorColor != null);
    _tap = new TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapCancel = _handleTapCancel;
    _longPress = new LongPressGestureRecognizer()
      ..onLongPress = _handleLongPress;
  }

  SelectionChangedHandler onSelectionChanged;
  ViewportDimensionsChangeCallback onPaintOffsetUpdateNeeded;

  /// The text to display
  TextSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  set text(TextSpan value) {
    if (_textPainter.text == value)
      return;
    TextSpan oldStyledText = _textPainter.text;
    if (oldStyledText.style != value.style)
      _layoutTemplate = null;
    _textPainter.text = value;
    markNeedsLayout();
  }

  Color get cursorColor => _cursorColor;
  Color _cursorColor;
  set cursorColor(Color value) {
    if (_cursorColor == value)
      return;
    _cursorColor = value;
    markNeedsPaint();
  }

  bool get showCursor => _showCursor;
  bool _showCursor;
  set showCursor(bool value) {
    if (_showCursor == value)
      return;
    _showCursor = value;
    markNeedsPaint();
  }

  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value)
      return;
    _selectionColor = value;
    markNeedsPaint();
  }

  List<ui.TextBox> _selectionRects;

  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value)
      return;
    _selection = value;
    _selectionRects = null;
    markNeedsPaint();
  }

  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  set paintOffset(Offset value) {
    if (_paintOffset == value)
      return;
    _paintOffset = value;
    markNeedsPaint();
  }

  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    _textPainter.layout(); // TODO(mpcomplete): is this hacky?

    Offset offset = _paintOffset + new Offset(0.0, -_kCaretHeightOffset);

    if (selection.isCollapsed) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.
      Offset caretOffset = _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      Point start = new Point(caretOffset.dx, _contentSize.height) + offset;
      return <TextSelectionPoint>[new TextSelectionPoint(localToGlobal(start), null)];
    } else {
      List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(selection);
      Point start = new Point(boxes.first.start, boxes.first.bottom) + offset;
      Point end = new Point(boxes.last.end, boxes.last.bottom) + offset;
      return <TextSelectionPoint>[
        new TextSelectionPoint(localToGlobal(start), boxes.first.direction),
        new TextSelectionPoint(localToGlobal(end), boxes.last.direction),
      ];
    }
  }

  TextPosition getPositionForPoint(Point global) {
    global += -paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(global).toOffset());
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
        ..layout(new ui.ParagraphConstraints(width: double.INFINITY));
    }
    return _layoutTemplate.height;
  }

  @override
  double getMinIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrainWidth(0.0);
  }

  @override
  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrainWidth(0.0);
  }

  @override
  double getMinIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrainHeight(_preferredHeight);
  }

  @override
  double getMaxIntrinsicHeight(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrainHeight(_preferredHeight);
  }

  @override
  bool hitTestSelf(Point position) => true;

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && onSelectionChanged != null) {
      _tap.addPointer(event);
      _longPress.addPointer(event);
    }
  }

  Point _lastTapDownPosition;
  Point _longPressPosition;
  void _handleTapDown(Point globalPosition) {
    _lastTapDownPosition = globalPosition + -paintOffset;
  }

  void _handleTap() {
    assert(_lastTapDownPosition != null);
    final Point global = _lastTapDownPosition;
    _lastTapDownPosition = null;
    if (onSelectionChanged != null) {
      TextPosition position = _textPainter.getPositionForOffset(globalToLocal(global).toOffset());
      onSelectionChanged(new TextSelection.fromPosition(position), this);
    }
  }

  void _handleTapCancel() {
    // longPress arrives after tapCancel, so remember the tap position.
    _longPressPosition = _lastTapDownPosition;
    _lastTapDownPosition = null;
  }

  void _handleLongPress() {
    final Point global = _longPressPosition;
    _longPressPosition = null;
    if (onSelectionChanged != null) {
      TextPosition position = _textPainter.getPositionForOffset(globalToLocal(global).toOffset());
      onSelectionChanged(_selectWordAtOffset(position), this);
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    // TODO(mpcomplete): Placeholder. Need to ask the engine for this info to do
    // it correctly.
    String str = text.toPlainText();
    int start = position.offset - 1;
    while (start >= 0 && str[start] != ' ')
      --start;
    ++start;

    int end = position.offset;
    while (end < str.length && str[end] != ' ')
      ++end;

    return new TextSelection(baseOffset: start, extentOffset: end);
  }

  Rect _caretPrototype;

  @override
  void performLayout() {
    Size oldSize = hasSize ? size : null;
    size = new Size(constraints.maxWidth, constraints.constrainHeight(_preferredHeight));
    _caretPrototype = new Rect.fromLTWH(0.0, _kCaretHeightOffset, _kCaretWidth, size.height - 2.0 * _kCaretHeightOffset);
    _selectionRects = null;
    _textPainter.layout();
    Size contentSize = new Size(_textPainter.width + _kCaretGap + _kCaretWidth, _textPainter.height);
    if (onPaintOffsetUpdateNeeded != null && (size != oldSize || contentSize != _contentSize))
      onPaintOffsetUpdateNeeded(new ViewportDimensions(containerSize: size, contentSize: contentSize));
    _contentSize = contentSize;
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

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Point.origin & size, _paintContents);
    else
      _paintContents(context, offset);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _hasVisualOverflow ? Point.origin & size : null;
}
