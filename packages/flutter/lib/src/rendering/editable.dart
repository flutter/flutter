// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show TextBox;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'object.dart';
import 'viewport_offset.dart';

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
@immutable
class TextSelectionPoint {
  /// Creates a description of a point in a text selection.
  ///
  /// The [point] argument must not be null.
  const TextSelectionPoint(this.point, this.direction)
      : assert(point != null);

  /// Screen coordinates of the lower left or lower right corner of the selection.
  final Offset point;

  /// Direction of the text at this edge of the selection.
  final TextDirection direction;

  @override
  String toString() {
    switch (direction) {
      case TextDirection.ltr:
        return '$point-ltr';
      case TextDirection.rtl:
        return '$point-rtl';
    }
    return '$point';
  }
}

class RenderEditable extends RenderBox {
  RenderEditable({
    TextSpan text,
    TextAlign textAlign,
    Color cursorColor,
    ValueNotifier<bool> showCursor,
    int maxLines: 1,
    Color selectionColor,
    double textScaleFactor: 1.0,
    TextSelection selection,
    @required ViewportOffset offset,
    this.onSelectionChanged,
  }) : _textPainter = new TextPainter(text: text, textAlign: textAlign, textScaleFactor: textScaleFactor),
       _cursorColor = cursorColor,
       _showCursor = showCursor ?? new ValueNotifier<bool>(false),
       _maxLines = maxLines,
       _selection = selection,
       _offset = offset {
    assert(_showCursor != null);
    assert(maxLines != null);
    assert(textScaleFactor != null);
    assert(offset != null);
    assert(!_showCursor.value || cursorColor != null);
    _tap = new TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapCancel = _handleTapCancel;
    _longPress = new LongPressGestureRecognizer()
      ..onLongPress = _handleLongPress;
  }

  /// Called when the selection changes.
  SelectionChangedHandler onSelectionChanged;

  double _textLayoutLastWidth;

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
    _textLayoutLastWidth = null;
    markNeedsLayout();
  }

  /// The text to display
  TextSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  set text(TextSpan value) {
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    markNeedsTextLayout();
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    if (_textPainter.textAlign == value)
      return;
    _textPainter.textAlign = value;
    markNeedsPaint();
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
  ValueNotifier<bool> get showCursor => _showCursor;
  ValueNotifier<bool> _showCursor;
  set showCursor(ValueNotifier<bool> value) {
    assert(value != null);
    if (_showCursor == value)
      return;
    if (attached)
      _showCursor.removeListener(markNeedsPaint);
    _showCursor = value;
    if (attached)
      _showCursor.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will extend
  /// indefinitely instead.
  int get maxLines => _maxLines;
  int _maxLines;
  set maxLines(int value) {
    assert(value != null);
    if (_maxLines == value)
      return;
    _maxLines = value;
    markNeedsTextLayout();
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
    markNeedsTextLayout();
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
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (_offset == value)
      return;
    if (attached)
      _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached)
      _offset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
    _showCursor.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    _showCursor.removeListener(markNeedsPaint);
    super.detach();
  }

  bool get _isMultiline => maxLines > 1;

  Axis get _viewportAxis => _isMultiline ? Axis.vertical : Axis.horizontal;

  Offset get _paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return new Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return new Offset(0.0, -offset.pixels);
    }
    return null;
  }

  double get _viewportExtent {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
    return null;
  }

  double _getMaxScrollExtent(Size contentSize) {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return math.max(0.0, contentSize.width - size.width);
      case Axis.vertical:
        return math.max(0.0, contentSize.height - size.height);
    }
    return null;
  }

  bool _hasVisualOverflow = false;

  /// Returns the global coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    _layoutText(constraints.maxWidth);

    final Offset paintOffset = _paintOffset;

    if (selection.isCollapsed) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.
      final Offset caretOffset = _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      final Offset start = new Offset(0.0, _preferredLineHeight) + caretOffset + paintOffset;
      return <TextSelectionPoint>[new TextSelectionPoint(localToGlobal(start), null)];
    } else {
      final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(selection);
      final Offset start = new Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
      final Offset end = new Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
      return <TextSelectionPoint>[
        new TextSelectionPoint(localToGlobal(start), boxes.first.direction),
        new TextSelectionPoint(localToGlobal(end), boxes.last.direction),
      ];
    }
  }

  /// Returns the position in the text for the given global coordinate.
  TextPosition getPositionForPoint(Offset globalPosition) {
    _layoutText(constraints.maxWidth);
    globalPosition += -_paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  /// Returns the Rect in local coordinates for the caret at the given text
  /// position.
  Rect getLocalRectForCaret(TextPosition caretPosition) {
    _layoutText(constraints.maxWidth);
    final Offset caretOffset = _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);
    // This rect is the same as _caretPrototype but without the vertical padding.
    return new Rect.fromLTWH(0.0, 0.0, _kCaretWidth, _preferredLineHeight).shift(caretOffset + _paintOffset);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText(double.INFINITY);
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText(double.INFINITY);
    return _textPainter.maxIntrinsicWidth;
  }

  // This does not required the layout to be updated.
  double get _preferredLineHeight => _textPainter.preferredLineHeight;

  @override
  double computeMinIntrinsicHeight(double width) {
    return _preferredLineHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _preferredLineHeight * maxLines;
  }

  @override
  bool hitTestSelf(Offset position) => true;

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

  Offset _lastTapDownPosition;
  Offset _longPressPosition;
  void _handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition + -_paintOffset;
  }

  void _handleTap() {
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    final Offset globalPosition = _lastTapDownPosition;
    _lastTapDownPosition = null;
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(globalPosition));
      onSelectionChanged(new TextSelection.fromPosition(position), this, false);
    }
  }

  void _handleTapCancel() {
    // longPress arrives after tapCancel, so remember the tap position.
    _longPressPosition = _lastTapDownPosition;
    _lastTapDownPosition = null;
  }

  void _handleLongPress() {
    _layoutText(constraints.maxWidth);
    final Offset globalPosition = _longPressPosition;
    _longPressPosition = null;
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(globalPosition));
      onSelectionChanged(_selectWordAtOffset(position), this, true);
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final TextRange word = _textPainter.getWordBoundary(position);
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end)
      return new TextSelection.fromPosition(position);
    return new TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  Rect _caretPrototype;

  void _layoutText(double constraintWidth) {
    assert(constraintWidth != null);
    if (_textLayoutLastWidth == constraintWidth)
      return;
    final double caretMargin = _kCaretGap + _kCaretWidth;
    final double availableWidth = math.max(0.0, constraintWidth - caretMargin);
    final double maxWidth = _maxLines > 1 ? availableWidth : double.INFINITY;
    _textPainter.layout(minWidth: availableWidth, maxWidth: maxWidth);
    _textLayoutLastWidth = constraintWidth;
  }

  @override
  void performLayout() {
    _layoutText(constraints.maxWidth);
    _caretPrototype = new Rect.fromLTWH(0.0, _kCaretHeightOffset, _kCaretWidth, _preferredLineHeight - 2.0 * _kCaretHeightOffset);
    _selectionRects = null;
    size = new Size(constraints.maxWidth, constraints.constrainHeight(
      _textPainter.height.clamp(_preferredLineHeight, _preferredLineHeight * _maxLines)
    ));
    final Size contentSize = new Size(_textPainter.width + _kCaretGap + _kCaretWidth, _textPainter.height);
    final double _maxScrollExtent = _getMaxScrollExtent(contentSize);
    _hasVisualOverflow = _maxScrollExtent > 0.0;
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  void _paintCaret(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final Offset caretOffset = _textPainter.getOffsetForCaret(_selection.extent, _caretPrototype);
    final Paint paint = new Paint()..color = _cursorColor;
    canvas.drawRect(_caretPrototype.shift(caretOffset + effectiveOffset), paint);
  }

  void _paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    assert(_selectionRects != null);
    final Paint paint = new Paint()..color = _selectionColor;
    for (ui.TextBox box in _selectionRects)
      canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final Offset effectiveOffset = offset + _paintOffset;

    if (_selection != null) {
      if (_selection.isCollapsed && _showCursor.value && cursorColor != null) {
        _paintCaret(context.canvas, effectiveOffset);
      } else if (!_selection.isCollapsed && _selectionColor != null) {
        _selectionRects ??= _textPainter.getBoxesForSelection(_selection);
        _paintSelection(context.canvas, effectiveOffset);
      }
    }

    _textPainter.paint(context.canvas, effectiveOffset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutText(constraints.maxWidth);
    if (_hasVisualOverflow)
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, _paintContents);
    else
      _paintContents(context, offset);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) => _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('cursorColor: $_cursorColor');
    description.add('showCursor: $_showCursor');
    description.add('maxLines: $_maxLines');
    description.add('selectionColor: $_selectionColor');
    description.add('textScaleFactor: $textScaleFactor');
    description.add('selection: $_selection');
    description.add('offset: $_offset');
  }

  @override
  String debugDescribeChildren(String prefix) {
    return '$prefix \u2558\u2550\u2566\u2550\u2550 text \u2550\u2550\u2550\n'
           '${text.toString("$prefix   \u2551 ")}' // TextSpan includes a newline
           '$prefix   \u255A\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\n'
           '${prefix.trimRight()}\n';
  }
}
