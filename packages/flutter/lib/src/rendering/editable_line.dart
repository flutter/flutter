// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextBox;

import 'package:flutter/gestures.dart';

import 'box.dart';
import 'object.dart';
import 'viewport.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels
const double _kCaretWidth = 1.0; // pixels

final String _kZeroWidthSpace = new String.fromCharCode(0x200B);

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [RenderEditable.onSelectionChanged].
typedef void SelectionChangedHandler(TextSelection selection, RenderEditable renderObject, bool longPress);

/// Represents a global screen coordinate of the point in a selection, and the
/// text direction at that point.
class TextSelectionPoint {
  /// Creates a description of a point in a text selection.
  ///
  /// The [point] argument must not be null.
  TextSelectionPoint(this.point, this.direction) {
    assert(point != null);
  }

  /// Screen coordinates of the lower left or lower right corner of the selection.
  final Point point;

  /// Direction of the text at this edge of the selection.
  final TextDirection direction;
}

/// Signature for the callback used by [RenderEditable] to determine the paint offset when
/// the dimensions of the render box change.
///
/// The return value should be the new paint offset to use.
///
/// Used by [RenderEditable.onPaintOffsetUpdateNeeded].
typedef Offset RenderEditablePaintOffsetNeededCallback(ViewportDimensions dimensions, Rect caretRect);

/// A single line of editable text.
class RenderEditable extends RenderBox {
  /// Creates a render object for a single line of editable text.
  RenderEditable({
    TextSpan text,
    Color cursorColor,
    bool showCursor: false,
    int maxLines: 1,
    Color selectionColor,
    double textScaleFactor: 1.0,
    TextSelection selection,
    this.onSelectionChanged,
    Offset paintOffset: Offset.zero,
    this.onPaintOffsetUpdateNeeded,
  }) : _textPainter = new TextPainter(text: text, textScaleFactor: textScaleFactor),
       _cursorColor = cursorColor,
       _showCursor = showCursor,
       _maxLines = maxLines,
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

  /// Called when the selection changes.
  SelectionChangedHandler onSelectionChanged;

  /// Called when the inner or outer dimensions of this render object change.
  RenderEditablePaintOffsetNeededCallback onPaintOffsetUpdateNeeded;

  /// The text to display
  TextSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  set text(TextSpan value) {
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    markNeedsLayout();
  }

  /// The color to use when painting the cursor.
  Color get cursorColor => _cursorColor;
  Color _cursorColor;
  set cursorColor(Color value) {
    if (_cursorColor == value)
      return;
    _cursorColor = value;
    markNeedsPaint();
  }

  /// Whether to paint the cursor.
  bool get showCursor => _showCursor;
  bool _showCursor;
  set showCursor(bool value) {
    if (_showCursor == value)
      return;
    _showCursor = value;
    markNeedsPaint();
  }

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will extend
  /// indefinitely instead.
  int get maxLines => _maxLines;
  int _maxLines;
  set maxLines(int value) {
    if (_maxLines == value)
      return;
    _maxLines = value;
    markNeedsLayout();
  }

  /// The color to use when painting the selection.
  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value)
      return;
    _selectionColor = value;
    markNeedsPaint();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value)
      return;
    _textPainter.textScaleFactor = value;
    markNeedsLayout();
  }

  List<ui.TextBox> _selectionRects;

  /// The region of text that is selected, if any.
  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value)
      return;
    _selection = value;
    _selectionRects = null;
    markNeedsPaint();
  }

  /// The offset at which the text should be painted.
  ///
  /// If the text content is larger than the editable line itself, the editable
  /// line clips the text. This property controls which part of the text is
  /// visible by shifting the text by the given offset before clipping.
  Offset get paintOffset => _paintOffset;
  Offset _paintOffset;
  set paintOffset(Offset value) {
    if (_paintOffset == value)
      return;
    _paintOffset = value;
    markNeedsPaint();
  }

  /// Returns the global coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    // TODO(mpcomplete): We should be more disciplined about when we dirty the
    // layout state of the text painter so that we can know that the layout is
    // clean at this point.
    _textPainter.layout(maxWidth: _maxContentWidth);

    Offset offset = _paintOffset;

    if (selection.isCollapsed) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.
      Offset caretOffset = _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      Point start = new Point(0.0, _preferredLineHeight) + caretOffset + offset;
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

  /// Returns the position in the text for the given global coordinate.
  TextPosition getPositionForPoint(Point globalPosition) {
    globalPosition += -paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition).toOffset());
  }

  /// Returns the Rect in local coordinates for the caret at the given text
  /// position.
  Rect getLocalRectForCaret(TextPosition caretPosition) {
    Offset caretOffset = _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);
    // This rect is the same as _caretPrototype but without the vertical padding.
    return new Rect.fromLTWH(0.0, 0.0, _kCaretWidth, _preferredLineHeight).shift(caretOffset + _paintOffset);
  }

  Size _contentSize;

  double get _preferredLineHeight => _textPainter.preferredLineHeight;

  double get _maxContentWidth {
    return _maxLines > 1 ?
      constraints.maxWidth - (_kCaretGap + _kCaretWidth) :
      double.INFINITY;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _preferredLineHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _preferredLineHeight * maxLines;
  }

  @override
  bool hitTestSelf(Point position) => true;

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && onSelectionChanged != null) {
      _tap.addPointer(event);
      _longPress.addPointer(event);
    }
  }

  Point _lastTapDownPosition;
  Point _longPressPosition;
  void _handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition + -paintOffset;
  }

  void _handleTap() {
    assert(_lastTapDownPosition != null);
    final Point global = _lastTapDownPosition;
    _lastTapDownPosition = null;
    if (onSelectionChanged != null) {
      TextPosition position = _textPainter.getPositionForOffset(globalToLocal(global).toOffset());
      onSelectionChanged(new TextSelection.fromPosition(position), this, false);
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
      onSelectionChanged(_selectWordAtOffset(position), this, true);
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    TextRange word = _textPainter.getWordBoundary(position);
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end)
      return new TextSelection.fromPosition(position);
    return new TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  Rect _caretPrototype;

  @override
  void performLayout() {
    Size oldSize = hasSize ? size : null;
    _caretPrototype = new Rect.fromLTWH(0.0, _kCaretHeightOffset, _kCaretWidth, _preferredLineHeight - 2.0 * _kCaretHeightOffset);
    _selectionRects = null;
    _textPainter.layout(maxWidth: _maxContentWidth);
    size = new Size(constraints.maxWidth, constraints.constrainHeight(
      _textPainter.height.clamp(_preferredLineHeight, _preferredLineHeight * _maxLines)
    ));
    Size contentSize = new Size(_textPainter.width + _kCaretGap + _kCaretWidth, _textPainter.height);
    assert(_selection != null);
    Rect caretRect = getLocalRectForCaret(_selection.extent);
    if (onPaintOffsetUpdateNeeded != null && (size != oldSize || contentSize != _contentSize || !_withinBounds(caretRect)))
      onPaintOffsetUpdateNeeded(new ViewportDimensions(containerSize: size, contentSize: contentSize), caretRect);
    _contentSize = contentSize;
  }

  bool _withinBounds(Rect caretRect) {
    Rect bounds = new Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    return (bounds.contains(caretRect.topLeft) && bounds.contains(caretRect.bottomRight));
  }

  void _paintCaret(Canvas canvas, Offset effectiveOffset) {
    Offset caretOffset = _textPainter.getOffsetForCaret(_selection.extent, _caretPrototype);
    Paint paint = new Paint()..color = _cursorColor;
    canvas.drawRect(_caretPrototype.shift(caretOffset + effectiveOffset), paint);
  }

  void _paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(_selectionRects != null);
    Paint paint = new Paint()..color = _selectionColor;
    for (ui.TextBox box in _selectionRects)
      canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
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
