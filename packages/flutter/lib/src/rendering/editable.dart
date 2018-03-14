// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show TextBox;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'object.dart';
import 'viewport_offset.dart';

const double _kCaretGap = 1.0; // pixels
const double _kCaretHeightOffset = 2.0; // pixels
const double _kCaretWidth = 1.0; // pixels

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [RenderEditable.onSelectionChanged].
typedef void SelectionChangedHandler(TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause);

/// Indicates what triggered the change in selected text (including changes to
/// the cursor location).
enum SelectionChangedCause {
  /// The user tapped on the text and that caused the selection (or the location
  /// of the cursor) to change.
  tap,

  /// The user long-pressed the text and that caused the selection (or the
  /// location of the cursor) to change.
  longPress,

  /// The user used the keyboard to change the selection or the location of the
  /// cursor.
  ///
  /// Keyboard-triggered selection changes may be caused by the IME as well as
  /// by accessibility tools (e.g. TalkBack on Android).
  keyboard,
}

/// Signature for the callback that reports when the caret location changes.
///
/// Used by [RenderEditable.onCaretChanged].
typedef void CaretChangedHandler(Rect caretRect);

/// Represents the coordinates of the point in a selection, and the text
/// direction at that point, relative to top left of the [RenderEditable] that
/// holds the selection.
@immutable
class TextSelectionPoint {
  /// Creates a description of a point in a text selection.
  ///
  /// The [point] argument must not be null.
  const TextSelectionPoint(this.point, this.direction)
      : assert(point != null);

  /// Coordinates of the lower left or lower right corner of the selection,
  /// relative to the top left of the [RenderEditable] object.
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

/// Displays some text in a scrollable container with a potentially blinking
/// cursor and with gesture recognizers.
///
/// This is the renderer for an editable text field. It does not directly
/// provide affordances for editing the text, but it does handle text selection
/// and manipulation of the text cursor.
///
/// The [text] is displayed, scrolled by the given [offset], aligned according
/// to [textAlign]. The [maxLines] property controls whether the text displays
/// on one line or many. The [selection], if it is not collapsed, is painted in
/// the [selectionColor]. If it _is_ collapsed, then it represents the cursor
/// position. The cursor is shown while [showCursor] is true. It is painted in
/// the [cursorColor].
///
/// If, when the render object paints, the caret is found to have changed
/// location, [onCaretChanged] is called.
///
/// The user may interact with the render object by tapping or long-pressing.
/// When the user does so, the selection is updated, and [onSelectionChanged] is
/// called.
///
/// Keyboard handling, IME handling, scrolling, toggling the [showCursor] value
/// to actually blink the cursor, and other features not mentioned above are the
/// responsibility of higher layers and not handled by this object.
class RenderEditable extends RenderBox {
  /// Creates a render object that implements the visual aspects of a text field.
  ///
  /// The [textAlign] argument must not be null. It defaults to [TextAlign.start].
  ///
  /// The [textDirection] argument must not be null.
  ///
  /// If [showCursor] is not specified, then it defaults to hiding the cursor.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is 1, meaning this is a single-line
  /// text field. If it is not null, it must be greater than zero.
  ///
  /// The [offset] is required and must not be null. You can use [new
  /// ViewportOffset.zero] if you have no need for scrolling.
  RenderEditable({
    TextSpan text,
    @required TextDirection textDirection,
    TextAlign textAlign: TextAlign.start,
    Color cursorColor,
    ValueNotifier<bool> showCursor,
    bool hasFocus,
    int maxLines: 1,
    Color selectionColor,
    double textScaleFactor: 1.0,
    TextSelection selection,
    @required ViewportOffset offset,
    this.onSelectionChanged,
    this.onCaretChanged,
    this.ignorePointer: false,
  }) : assert(textAlign != null),
       assert(textDirection != null, 'RenderEditable created without a textDirection.'),
       assert(maxLines == null || maxLines > 0),
       assert(textScaleFactor != null),
       assert(offset != null),
       assert(ignorePointer != null),
       _textPainter = new TextPainter(
         text: text,
         textAlign: textAlign,
         textDirection: textDirection,
         textScaleFactor: textScaleFactor,
       ),
       _cursorColor = cursorColor,
       _showCursor = showCursor ?? new ValueNotifier<bool>(false),
       _hasFocus = hasFocus ?? false,
       _maxLines = maxLines,
       _selectionColor = selectionColor,
       _selection = selection,
       _offset = offset {
    assert(_showCursor != null);
    assert(!_showCursor.value || cursorColor != null);
    _tap = new TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = new LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = _handleLongPress;
  }

  /// Called when the selection changes.
  SelectionChangedHandler onSelectionChanged;

  double _textLayoutLastWidth;

  /// Called during the paint phase when the caret location changes.
  CaretChangedHandler onCaretChanged;

  /// If true [handleEvent] does nothing and it's assumed that this
  /// renderer will be notified of input gestures via [handleTapDown],
  /// [handleTap], and [handleLongPress].
  ///
  /// The default value of this property is false.
  bool ignorePointer;

  Rect _lastCaretRect;

  /// Marks the render object as needing to be laid out again and have its text
  /// metrics recomputed.
  ///
  /// Implies [markNeedsLayout].
  @protected
  void markNeedsTextLayout() {
    _textLayoutLastWidth = null;
    markNeedsLayout();
  }

  /// The text to display.
  TextSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  set text(TextSpan value) {
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  /// How the text should be aligned horizontally.
  ///
  /// This must not be null.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value)
      return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  TextDirection get textDirection => _textPainter.textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value)
      return;
    _textPainter.textDirection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
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

  /// Whether the editable is currently focused.
  bool get hasFocus => _hasFocus;
  bool _hasFocus;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value)
      return;
    _hasFocus = value;
    markNeedsSemanticsUpdate();
  }

  /// The maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If this is 1 (the default), the text will not wrap, but will extend
  /// indefinitely instead.
  ///
  /// If this is null, there is no limit to the number of lines.
  ///
  /// When this is not null, the intrinsic height of the render object is the
  /// height of one line of text multiplied by this value. In other words, this
  /// also controls the height of the actual editing widget.
  int get maxLines => _maxLines;
  int _maxLines;
  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int value) {
    assert(value == null || value > 0);
    if (maxLines == value)
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
    markNeedsSemanticsUpdate();
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
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config
      ..value = text.toPlainText()
      ..textDirection = textDirection
      ..isFocused = hasFocus
      ..isTextField = true;

    if (hasFocus)
      config.onSetSelection = _handleSetSelection;

    if (_selection?.isValid == true) {
      config.textSelection = _selection;
      if (_textPainter.getOffsetBefore(_selection.extentOffset) != null)
        config.onMoveCursorBackwardByCharacter = _handleMoveCursorBackwardByCharacter;
      if (_textPainter.getOffsetAfter(_selection.extentOffset) != null)
        config.onMoveCursorForwardByCharacter = _handleMoveCursorForwardByCharacter;
    }
  }

  void _handleSetSelection(TextSelection selection) {
    onSelectionChanged(selection, this, SelectionChangedCause.keyboard);
  }

  void _handleMoveCursorForwardByCharacter(bool extentSelection) {
    final int extentOffset = _textPainter.getOffsetAfter(_selection.extentOffset);
    if (extentOffset == null)
      return;
    final int baseOffset = !extentSelection ? extentOffset : _selection.baseOffset;
    onSelectionChanged(
      new TextSelection(baseOffset: baseOffset, extentOffset: extentOffset), this, SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extentSelection) {
    final int extentOffset = _textPainter.getOffsetBefore(_selection.extentOffset);
    if (extentOffset == null)
      return;
    final int baseOffset = !extentSelection ? extentOffset : _selection.baseOffset;
    onSelectionChanged(
      new TextSelection(baseOffset: baseOffset, extentOffset: extentOffset), this, SelectionChangedCause.keyboard,
    );
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

  bool get _isMultiline => maxLines != 1;

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

  /// Returns the local coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the equivalent but for
  ///    a [TextPosition] rather than a [TextSelection].
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    _layoutText(constraints.maxWidth);

    final Offset paintOffset = _paintOffset;

    if (selection.isCollapsed) {
      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.
      final Offset caretOffset = _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      final Offset start = new Offset(0.0, preferredLineHeight) + caretOffset + paintOffset;
      return <TextSelectionPoint>[new TextSelectionPoint(start, null)];
    } else {
      final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(selection);
      final Offset start = new Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
      final Offset end = new Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
      return <TextSelectionPoint>[
        new TextSelectionPoint(start, boxes.first.direction),
        new TextSelectionPoint(end, boxes.last.direction),
      ];
    }
  }

  /// Returns the position in the text for the given global coordinate.
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the reverse operation, taking
  ///    a [TextPosition] and returning a [Rect].
  ///  * [TextPainter.getPositionForOffset], which is the equivalent method
  ///    for a [TextPainter] object.
  TextPosition getPositionForPoint(Offset globalPosition) {
    _layoutText(constraints.maxWidth);
    globalPosition += -_paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  /// Returns the [Rect] in local coordinates for the caret at the given text
  /// position.
  ///
  /// See also:
  ///
  ///  * [getPositionForPoint], which is the reverse operation, taking
  ///    an [Offset] in global coordinates and returning a [TextPosition].
  ///  * [getEndpointsForSelection], which is the equivalent but for
  ///    a selection rather than a particular text position.
  ///  * [TextPainter.getOffsetForCaret], the equivalent method for a
  ///    [TextPainter] object.
  Rect getLocalRectForCaret(TextPosition caretPosition) {
    _layoutText(constraints.maxWidth);
    final Offset caretOffset = _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);
    // This rect is the same as _caretPrototype but without the vertical padding.
    return new Rect.fromLTWH(0.0, 0.0, _kCaretWidth, preferredLineHeight).shift(caretOffset + _paintOffset);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _textPainter.maxIntrinsicWidth;
  }

  /// An estimate of the height of a line in the text. See [TextPainter.preferredLineHeight].
  /// This does not required the layout to be updated.
  double get preferredLineHeight => _textPainter.preferredLineHeight;

  double _preferredHeight(double width) {
    if (maxLines != null)
      return preferredLineHeight * maxLines;
    if (width == double.infinity) {
      final String text = _textPainter.text.toPlainText();
      int lines = 1;
      for (int index = 0; index < text.length; index += 1) {
        if (text.codeUnitAt(index) == 0x0A) // count explicit line breaks
          lines += 1;
      }
      return preferredLineHeight * lines;
    }
    _layoutText(width);
    return math.max(preferredLineHeight, _textPainter.height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _preferredHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _preferredHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _layoutText(constraints.maxWidth);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (ignorePointer)
      return;
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && onSelectionChanged != null) {
      _tap.addPointer(event);
      _longPress.addPointer(event);
    }
  }

  Offset _lastTapDownPosition;

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition + -_paintOffset;
  }
  void _handleTapDown(TapDownDetails details) {
    assert(!ignorePointer);
    handleTapDown(details);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// events by calling this method.
  void handleTap() {
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(_lastTapDownPosition));
      onSelectionChanged(new TextSelection.fromPosition(position), this, SelectionChangedCause.tap);
    }
  }
  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [LongPressRecognizer.onLongPress]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to long
  /// press events by calling this method.
  void handleLongPress() {
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(_lastTapDownPosition));
      onSelectionChanged(_selectWordAtOffset(position), this, SelectionChangedCause.longPress);
    }
  }
  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
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
    const double caretMargin = _kCaretGap + _kCaretWidth;
    final double availableWidth = math.max(0.0, constraintWidth - caretMargin);
    final double maxWidth = _isMultiline ? availableWidth : double.infinity;
    _textPainter.layout(minWidth: availableWidth, maxWidth: maxWidth);
    _textLayoutLastWidth = constraintWidth;
  }

  @override
  void performLayout() {
    _layoutText(constraints.maxWidth);
    _caretPrototype = new Rect.fromLTWH(0.0, _kCaretHeightOffset, _kCaretWidth, preferredLineHeight - 2.0 * _kCaretHeightOffset);
    _selectionRects = null;
    // We grab _textPainter.size here because assigning to `size` on the next
    // line will trigger us to validate our intrinsic sizes, which will change
    // _textPainter's layout because the intrinsic size calculations are
    // destructive, which would mean we would get different results if we later
    // used properties on _textPainter in this method.
    // Other _textPainter state like didExceedMaxLines will also be affected,
    // though we currently don't use those here.
    // See also RenderParagraph which has a similar issue.
    final Size textPainterSize = _textPainter.size;
    size = new Size(constraints.maxWidth, constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
    final Size contentSize = new Size(textPainterSize.width + _kCaretGap + _kCaretWidth, textPainterSize.height);
    final double _maxScrollExtent = _getMaxScrollExtent(contentSize);
    _hasVisualOverflow = _maxScrollExtent > 0.0;
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  void _paintCaret(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final Offset caretOffset = _textPainter.getOffsetForCaret(_selection.extent, _caretPrototype);
    final Paint paint = new Paint()..color = _cursorColor;
    final Rect caretRect = _caretPrototype.shift(caretOffset + effectiveOffset);
    canvas.drawRect(caretRect, paint);
    if (caretRect != _lastCaretRect) {
      _lastCaretRect = caretRect;
      if (onCaretChanged != null)
        onCaretChanged(caretRect);
    }
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
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<Color>('cursorColor', cursorColor));
    description.add(new DiagnosticsProperty<ValueNotifier<bool>>('showCursor', showCursor));
    description.add(new IntProperty('maxLines', maxLines));
    description.add(new DiagnosticsProperty<Color>('selectionColor', selectionColor));
    description.add(new DoubleProperty('textScaleFactor', textScaleFactor));
    description.add(new DiagnosticsProperty<TextSelection>('selection', selection));
    description.add(new DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
        name: 'text',
        style: DiagnosticsTreeStyle.transition,
      ),
    ];
  }
}
