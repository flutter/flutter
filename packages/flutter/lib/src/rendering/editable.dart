// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//ignore: Remove this once Google catches up with dev.4 Dart.
import 'dart:async';
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

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [RenderEditable.onSelectionChanged].
typedef SelectionChangedHandler = void Function(TextSelection selection, RenderEditable renderObject, SelectionChangedCause cause);

/// Indicates what triggered the change in selected text (including changes to
/// the cursor location).
enum SelectionChangedCause {
  /// The user tapped on the text and that caused the selection (or the location
  /// of the cursor) to change.
  tap,

  /// The user tapped twice in quick succession on the text and that caused
  /// the selection (or the location of the cursor) to change.
  doubleTap,

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
typedef CaretChangedHandler = void Function(Rect caretRect);

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
  ///
  /// The [enableInteractiveSelection] argument must not be null.
  RenderEditable({
    TextSpan text,
    @required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    Color cursorColor,
    ValueNotifier<bool> showCursor,
    bool hasFocus,
    int maxLines = 1,
    Color selectionColor,
    double textScaleFactor = 1.0,
    TextSelection selection,
    @required ViewportOffset offset,
    this.onSelectionChanged,
    this.onCaretChanged,
    this.ignorePointer = false,
    bool obscureText = false,
    Locale locale,
    double cursorWidth = 1.0,
    Radius cursorRadius,
    bool enableInteractiveSelection = true,
    @required this.textSelectionDelegate,
  }) : assert(textAlign != null),
       assert(textDirection != null, 'RenderEditable created without a textDirection.'),
       assert(maxLines == null || maxLines > 0),
       assert(textScaleFactor != null),
       assert(offset != null),
       assert(ignorePointer != null),
       assert(obscureText != null),
       assert(enableInteractiveSelection != null),
       assert(textSelectionDelegate != null),
       _textPainter = TextPainter(
         text: text,
         textAlign: textAlign,
         textDirection: textDirection,
         textScaleFactor: textScaleFactor,
         locale: locale,
       ),
       _cursorColor = cursorColor,
       _showCursor = showCursor ?? ValueNotifier<bool>(false),
       _hasFocus = hasFocus ?? false,
       _maxLines = maxLines,
       _selectionColor = selectionColor,
       _selection = selection,
       _offset = offset,
       _cursorWidth = cursorWidth,
       _cursorRadius = cursorRadius,
       _enableInteractiveSelection = enableInteractiveSelection,
       _obscureText = obscureText {
    assert(_showCursor != null);
    assert(!_showCursor.value || cursorColor != null);
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = _handleLongPress;
  }

  /// Character used to obscure text if [obscureText] is true.
  static const String obscuringCharacter = '•';

  /// Called when the selection changes.
  SelectionChangedHandler onSelectionChanged;

  double _textLayoutLastWidth;

  /// Called during the paint phase when the caret location changes.
  CaretChangedHandler onCaretChanged;

  /// If true [handleEvent] does nothing and it's assumed that this
  /// renderer will be notified of input gestures via [handleTapDown],
  /// [handleTap], [handleDoubleTap], and [handleLongPress].
  ///
  /// The default value of this property is false.
  bool ignorePointer;

  /// Whether to hide the text being edited (e.g., for passwords).
  bool get obscureText => _obscureText;
  bool _obscureText;
  set obscureText(bool value) {
    if (_obscureText == value)
      return;
    _obscureText = value;
    markNeedsSemanticsUpdate();
  }

  /// The object that controls the text selection, used by this render object
  /// for implementing cut, copy, and paste keyboard shortcuts.
  ///
  /// It must not be null. It will make cut, copy and paste functionality work
  /// with the most recently set [TextSelectionDelegate].
  TextSelectionDelegate textSelectionDelegate;

  Rect _lastCaretRect;

  static const int _kLeftArrowCode = 21;
  static const int _kRightArrowCode = 22;
  static const int _kUpArrowCode = 19;
  static const int _kDownArrowCode = 20;
  static const int _kXKeyCode = 52;
  static const int _kCKeyCode = 31;
  static const int _kVKeyCode = 50;
  static const int _kAKeyCode = 29;
  static const int _kDelKeyCode = 112;

  // The extent offset of the current selection
  int _extentOffset = -1;

  // The base offset of the current selection
  int _baseOffset = -1;

  // Holds the last location the user selected in the case that he selects all
  // the way to the end or beginning of the field.
  int _previousCursorLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // selects all the way to the end or the beginning of a field.
  bool _resetCursor = false;

  static const int _kShiftMask = 1; // https://developer.android.com/reference/android/view/KeyEvent.html#META_SHIFT_ON
  static const int _kControlMask = 1 << 12; // https://developer.android.com/reference/android/view/KeyEvent.html#META_CTRL_ON

  // TODO(goderbauer): doesn't handle extended grapheme clusters with more than one Unicode scalar value (https://github.com/flutter/flutter/issues/13404).
  void _handleKeyEvent(RawKeyEvent keyEvent) {
    if (defaultTargetPlatform != TargetPlatform.android)
      return;

    if (keyEvent is RawKeyUpEvent)
      return;

    final RawKeyEventDataAndroid rawAndroidEvent = keyEvent.data;
    final int pressedKeyCode = rawAndroidEvent.keyCode;
    final int pressedKeyMetaState = rawAndroidEvent.metaState;

    if (selection.isCollapsed) {
      _extentOffset = selection.extentOffset;
      _baseOffset = selection.baseOffset;
    }

    // Update current key states
    final bool shift = pressedKeyMetaState & _kShiftMask > 0;
    final bool ctrl = pressedKeyMetaState & _kControlMask > 0;

    final bool rightArrow = pressedKeyCode == _kRightArrowCode;
    final bool leftArrow = pressedKeyCode == _kLeftArrowCode;
    final bool upArrow = pressedKeyCode == _kUpArrowCode;
    final bool downArrow = pressedKeyCode == _kDownArrowCode;
    final bool arrow = leftArrow || rightArrow || upArrow || downArrow;
    final bool aKey = pressedKeyCode == _kAKeyCode;
    final bool xKey = pressedKeyCode == _kXKeyCode;
    final bool vKey = pressedKeyCode == _kVKeyCode;
    final bool cKey = pressedKeyCode == _kCKeyCode;
    final bool del = pressedKeyCode == _kDelKeyCode;

    // We will only move select or more the caret if an arrow is pressed
    if (arrow) {
      int newOffset = _extentOffset;

      // Because the user can use multiple keys to change how he selects
      // the new offset variable is threaded through these four functions
      // and potentially changes after each one.
      if (ctrl)
        newOffset = _handleControl(rightArrow, leftArrow, ctrl, newOffset);
      newOffset = _handleHorizontalArrows(rightArrow, leftArrow, shift, newOffset);
      if (downArrow || upArrow)
        newOffset = _handleVerticalArrows(upArrow, downArrow, shift, newOffset);
      newOffset = _handleShift(rightArrow, leftArrow, shift, newOffset);

      _extentOffset = newOffset;
    } else if (ctrl && (xKey || vKey || cKey || aKey)) {
      // _handleShortcuts depends on being started in the same stack invocation as the _handleKeyEvent method
      _handleShortcuts(pressedKeyCode);
    }
    if (del)
      _handleDelete();
  }

  // Handles full word traversal using control.
  int _handleControl(bool rightArrow, bool leftArrow, bool ctrl, int newOffset) {
    // If control is pressed, we will decide which way to look for a word
    // based on which arrow is pressed.
    if (leftArrow && _extentOffset > 2) {
      final TextSelection textSelection = _selectWordAtOffset(TextPosition(offset: _extentOffset - 2));
      newOffset = textSelection.baseOffset + 1;
    } else if (rightArrow && _extentOffset < text.text.length - 2) {
      final TextSelection textSelection = _selectWordAtOffset(TextPosition(offset: _extentOffset + 1));
      newOffset = textSelection.extentOffset - 1;
    }
    return newOffset;
  }

  int _handleHorizontalArrows(bool rightArrow, bool leftArrow, bool shift, int newOffset) {
    // Set the new offset to be +/- 1 depending on which arrow is pressed
    // If shift is down, we also want to update the previous cursor location
    if (rightArrow && _extentOffset < text.text.length) {
      newOffset += 1;
      if (shift)
        _previousCursorLocation += 1;
    }
    if (leftArrow && _extentOffset > 0) {
      newOffset -= 1;
      if (shift)
        _previousCursorLocation -= 1;
    }
    return newOffset;
  }

  // Handles moving the cursor vertically as well as taking care of the
  // case where the user moves the cursor to the end or beginning of the text
  // and then back up or down.
  int _handleVerticalArrows(bool upArrow, bool downArrow, bool shift, int newOffset) {
    // The caret offset gives a location in the upper left hand corner of
    // the caret so the middle of the line above is a half line above that
    // point and the line below is 1.5 lines below that point.
    final double plh = _textPainter.preferredLineHeight;
    final double verticalOffset = upArrow ? -0.5 * plh : 1.5 * plh;

    final Offset caretOffset = _textPainter.getOffsetForCaret(TextPosition(offset: _extentOffset), _caretPrototype);
    final Offset caretOffsetTranslated = caretOffset.translate(0.0, verticalOffset);
    final TextPosition position = _textPainter.getPositionForOffset(caretOffsetTranslated);

    // To account for the possibility where the user vertically highlights
    // all the way to the top or bottom of the text, we hold the previous
    // cursor location. This allows us to restore to this position in the
    // case that the user wants to unhighlight some text.
    if (position.offset == _extentOffset) {
      if (downArrow)
        newOffset = text.text.length;
      else if (upArrow)
        newOffset = 0;
      _resetCursor = shift;
    } else if (_resetCursor && shift) {
      newOffset = _previousCursorLocation;
      _resetCursor = false;
    } else {
      newOffset = position.offset;
      _previousCursorLocation = newOffset;
    }
    return newOffset;
  }

  // Handles the selection of text or removal of the selection and placing
  // of the caret.
  int _handleShift(bool rightArrow, bool leftArrow, bool shift, int newOffset) {
    if (onSelectionChanged == null)
      return newOffset;
    // In the text_selection class, a TextSelection is defined such that the
    // base offset is always less than the extent offset.
    if (shift) {
      if (_baseOffset < newOffset) {
        onSelectionChanged(
          TextSelection(
            baseOffset: _baseOffset,
            extentOffset: newOffset
          ),
          this,
          SelectionChangedCause.keyboard,
        );
      } else {
        onSelectionChanged(
          TextSelection(
            baseOffset: newOffset,
            extentOffset: _baseOffset
          ),
          this,
          SelectionChangedCause.keyboard,
        );
      }
    } else {
      // We want to put the cursor at the correct location depending on which
      // arrow is used while there is a selection.
      if (!selection.isCollapsed) {
        if (leftArrow)
          newOffset = _baseOffset < _extentOffset ? _baseOffset : _extentOffset;
        else if (rightArrow)
          newOffset = _baseOffset > _extentOffset ? _baseOffset : _extentOffset;
      }
      onSelectionChanged(
        TextSelection.fromPosition(
          TextPosition(
            offset: newOffset
          )
        ),
        this,
        SelectionChangedCause.keyboard,
      );
    }
    return newOffset;
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control + (X, C, V, A).
  Future<void> _handleShortcuts(int pressedKeyCode) async {
    switch (pressedKeyCode) {
      case _kCKeyCode:
        if (!selection.isCollapsed) {
          Clipboard.setData(
            ClipboardData(text: selection.textInside(text.text)));
        }
        break;
      case _kXKeyCode:
        if (!selection.isCollapsed) {
          Clipboard.setData(
            ClipboardData(text: selection.textInside(text.text)));
          textSelectionDelegate.textEditingValue = TextEditingValue(
            text: selection.textBefore(text.text)
              + selection.textAfter(text.text),
            selection: TextSelection.collapsed(offset: selection.start),
          );
        }
        break;
      case _kVKeyCode:
        // Snapshot the input before using `await`.
        // See https://github.com/flutter/flutter/issues/11427
        final TextEditingValue value = textSelectionDelegate.textEditingValue;
        final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data != null) {
          textSelectionDelegate.textEditingValue = TextEditingValue(
            text: value.selection.textBefore(value.text)
              + data.text
              + value.selection.textAfter(value.text),
            selection: TextSelection.collapsed(
              offset: value.selection.start + data.text.length
            ),
          );
        }
        break;
      case _kAKeyCode:
        _baseOffset = 0;
        _extentOffset = textSelectionDelegate.textEditingValue.text.length;
        onSelectionChanged(
          TextSelection(
            baseOffset: 0,
            extentOffset: textSelectionDelegate.textEditingValue.text.length,
          ),
          this,
          SelectionChangedCause.keyboard,
        );
        break;
      default:
        assert(false);
    }
  }

  void _handleDelete() {
    if (selection.textAfter(text.text).isNotEmpty) {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(text.text)
          + selection.textAfter(text.text).substring(1),
        selection: TextSelection.collapsed(offset: selection.start)
      );
    } else {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(text.text),
        selection: TextSelection.collapsed(offset: selection.start)
      );
    }
  }

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

  /// Used by this renderer's internal [TextPainter] to select a locale-specific
  /// font.
  ///
  /// In some cases the same Unicode character may be rendered differently depending
  /// on the locale. For example the '骨' character is rendered differently in
  /// the Chinese and Japanese locales. In these cases the [locale] may be used
  /// to select a locale-specific font.
  ///
  /// If this value is null, a system-dependent algorithm is used to select
  /// the font.
  Locale get locale => _textPainter.locale;
  set locale(Locale value) {
    if (_textPainter.locale == value)
      return;
    _textPainter.locale = value;
    markNeedsTextLayout();
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
  bool _listenerAttached = false;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value)
      return;
    _hasFocus = value;
    if (_hasFocus) {
      assert(!_listenerAttached);
      RawKeyboard.instance.addListener(_handleKeyEvent);
      _listenerAttached = true;
    }
    else {
      assert(_listenerAttached);
      RawKeyboard.instance.removeListener(_handleKeyEvent);
      _listenerAttached = false;
    }

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

  /// How thick the cursor will be.
  double get cursorWidth => _cursorWidth;
  double _cursorWidth = 1.0;
  set cursorWidth(double value) {
    if (_cursorWidth == value)
      return;
    _cursorWidth = value;
    markNeedsLayout();
  }

  /// How rounded the corners of the cursor should be.
  Radius get cursorRadius => _cursorRadius;
  Radius _cursorRadius;
  set cursorRadius(Radius value) {
    if (_cursorRadius == value)
      return;
    _cursorRadius = value;
    markNeedsPaint();
  }

  /// If false, [describeSemanticsConfiguration] will not set the
  /// configuration's cursor motion or set selection callbacks.
  ///
  /// True by default.
  bool get enableInteractiveSelection => _enableInteractiveSelection;
  bool _enableInteractiveSelection;
  set enableInteractiveSelection(bool value) {
    if (_enableInteractiveSelection == value)
      return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config
      ..value = obscureText
          ? obscuringCharacter * text.toPlainText().length
          : text.toPlainText()
      ..isObscured = obscureText
      ..textDirection = textDirection
      ..isFocused = hasFocus
      ..isTextField = true;

    if (hasFocus && enableInteractiveSelection)
      config.onSetSelection = _handleSetSelection;

    if (enableInteractiveSelection && _selection?.isValid == true) {
      config.textSelection = _selection;
      if (_textPainter.getOffsetBefore(_selection.extentOffset) != null) {
        config
          ..onMoveCursorBackwardByWord = _handleMoveCursorBackwardByWord
          ..onMoveCursorBackwardByCharacter = _handleMoveCursorBackwardByCharacter;
      }
      if (_textPainter.getOffsetAfter(_selection.extentOffset) != null) {
        config
          ..onMoveCursorForwardByWord = _handleMoveCursorForwardByWord
          ..onMoveCursorForwardByCharacter = _handleMoveCursorForwardByCharacter;
      }
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
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset), this, SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extentSelection) {
    final int extentOffset = _textPainter.getOffsetBefore(_selection.extentOffset);
    if (extentOffset == null)
      return;
    final int baseOffset = !extentSelection ? extentOffset : _selection.baseOffset;
    onSelectionChanged(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset), this, SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorForwardByWord(bool extentSelection) {
    final TextRange currentWord = _textPainter.getWordBoundary(_selection.extent);
    if (currentWord == null)
      return;
    final TextRange nextWord = _getNextWord(currentWord.end);
    if (nextWord == null)
      return;
    final int baseOffset = extentSelection ? _selection.baseOffset : nextWord.start;
    onSelectionChanged(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: nextWord.start,
      ),
      this,
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByWord(bool extentSelection) {
    final TextRange currentWord = _textPainter.getWordBoundary(_selection.extent);
    if (currentWord == null)
      return;
    final TextRange previousWord = _getPreviousWord(currentWord.start - 1);
    if (previousWord == null)
      return;
    final int baseOffset = extentSelection ?  _selection.baseOffset : previousWord.start;
    onSelectionChanged(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: previousWord.start,
      ),
      this,
      SelectionChangedCause.keyboard,
    );
  }

  TextRange _getNextWord(int offset) {
    while (true) {
      final TextRange range = _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed)
        return null;
      if (!_onlyWhitespace(range))
        return range;
      offset = range.end;
    }
  }

  TextRange _getPreviousWord(int offset) {
    while (offset >= 0) {
      final TextRange range = _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed)
        return null;
      if (!_onlyWhitespace(range))
        return range;
      offset = range.start - 1;
    }
    return null;
  }

  // Check if the given text range only contains white space or separator
  // characters.
  //
  // newline characters from ascii and separators from the
  // [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  // TODO(jonahwilliams): replace when we expose this ICU information.
  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = text.codeUnitAt(i);
      switch (codeUnit) {
        case 0x9: // horizontal tab
        case 0xA: // line feed
        case 0xB: // vertical tab
        case 0xC: // form feed
        case 0xD: // carriage return
        case 0x1C: // file separator
        case 0x1D: // group separator
        case 0x1E: // record separator
        case 0x1F: // unit separator
        case 0x20: // space
        case 0xA0: // no-break space
        case 0x1680: // ogham space mark
        case 0x2000: // en quad
        case 0x2001: // em quad
        case 0x2002: // en space
        case 0x2003: // em space
        case 0x2004: // three-per-em space
        case 0x2005: // four-er-em space
        case 0x2006: // six-per-em space
        case 0x2007: // figure space
        case 0x2008: // punctuation space
        case 0x2009: // thin space
        case 0x200A: // hair space
        case 0x202F: // narrow no-break space
        case 0x205F: // medium mathematical space
        case 0x3000: // ideographic space
          break;
        default:
          return false;
      }
    }
    return true;
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
    if (_listenerAttached)
      RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.detach();
  }

  bool get _isMultiline => maxLines != 1;

  Axis get _viewportAxis => _isMultiline ? Axis.vertical : Axis.horizontal;

  Offset get _paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return Offset(0.0, -offset.pixels);
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

  double _maxScrollExtent = 0;

  // We need to check the paint offset here because during animation, the start of
  // the text may position outside the visible region even when the text fits.
  bool get _hasVisualOverflow => _maxScrollExtent > 0 || _paintOffset != Offset.zero;

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
      final Offset start = Offset(0.0, preferredLineHeight) + caretOffset + paintOffset;
      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(selection);
      final Offset start = Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
      final Offset end = Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
      return <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
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
    return Rect.fromLTWH(0.0, 0.0, cursorWidth, preferredLineHeight).shift(caretOffset + _paintOffset);
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
    selectPosition(cause: SelectionChangedCause.tap);
  }
  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [DoubleTapGestureRecognizer.onDoubleTap]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to double
  /// tap events by calling this method.
  void handleDoubleTap() {
    selectWord(cause: SelectionChangedCause.doubleTap);
  }

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [LongPressRecognizer.onLongPress]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to long
  /// press events by calling this method.
  void handleLongPress() {
    selectWord(cause: SelectionChangedCause.longPress);
  }
  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
  }

  /// Move selection to the location of the last tap down.
  void selectPosition({@required SelectionChangedCause cause}) {
    assert(cause != null);
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(_lastTapDownPosition));
      onSelectionChanged(TextSelection.fromPosition(position), this, cause);
    }
  }

  /// Select a word around the location of the last tap down.
  void selectWord({@required SelectionChangedCause cause}) {
    assert(cause != null);
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(_lastTapDownPosition));
      onSelectionChanged(_selectWordAtOffset(position), this, cause);
    }
  }

  /// Move the selection to the beginning or end of a word.
  void selectWordEdge({@required SelectionChangedCause cause}) {
    assert(cause != null);
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(globalToLocal(_lastTapDownPosition));
      final TextRange word = _textPainter.getWordBoundary(position);
      if (position.offset - word.start <= 1) {
        onSelectionChanged(
          TextSelection.collapsed(offset: word.start, affinity: TextAffinity.downstream),
          this,
          cause,
        );
      } else {
        onSelectionChanged(
          TextSelection.collapsed(offset: word.end, affinity: TextAffinity.upstream),
          this,
          cause,
        );
      }
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final TextRange word = _textPainter.getWordBoundary(position);
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end)
      return TextSelection.fromPosition(position);
    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  Rect _caretPrototype;

  void _layoutText(double constraintWidth) {
    assert(constraintWidth != null);
    if (_textLayoutLastWidth == constraintWidth)
      return;
    final double caretMargin = _kCaretGap + cursorWidth;
    final double availableWidth = math.max(0.0, constraintWidth - caretMargin);
    final double maxWidth = _isMultiline ? availableWidth : double.infinity;
    _textPainter.layout(minWidth: availableWidth, maxWidth: maxWidth);
    _textLayoutLastWidth = constraintWidth;
  }

  @override
  void performLayout() {
    _layoutText(constraints.maxWidth);
    _caretPrototype = Rect.fromLTWH(0.0, _kCaretHeightOffset, cursorWidth, preferredLineHeight - 2.0 * _kCaretHeightOffset);
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
    size = Size(constraints.maxWidth, constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
    final Size contentSize = Size(textPainterSize.width + _kCaretGap + cursorWidth, textPainterSize.height);
    _maxScrollExtent = _getMaxScrollExtent(contentSize);
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  void _paintCaret(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    final Offset caretOffset = _textPainter.getOffsetForCaret(_selection.extent, _caretPrototype);
    final Paint paint = Paint()
      ..color = _cursorColor;

    final Rect caretRect = _caretPrototype.shift(caretOffset + effectiveOffset);

    if (cursorRadius == null) {
      canvas.drawRect(caretRect, paint);
    } else {
      final RRect caretRRect = RRect.fromRectAndRadius(caretRect, cursorRadius);
      canvas.drawRRect(caretRRect, paint);
    }

    if (caretRect != _lastCaretRect) {
      _lastCaretRect = caretRect;
      if (onCaretChanged != null)
        onCaretChanged(caretRect);
    }
  }

  void _paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth);
    assert(_selectionRects != null);
    final Paint paint = Paint()..color = _selectionColor;
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>('cursorColor', cursorColor));
    properties.add(DiagnosticsProperty<ValueNotifier<bool>>('showCursor', showCursor));
    properties.add(IntProperty('maxLines', maxLines));
    properties.add(DiagnosticsProperty<Color>('selectionColor', selectionColor));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties.add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(DiagnosticsProperty<TextSelection>('selection', selection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
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
