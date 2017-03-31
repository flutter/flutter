// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'media_query.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';
import 'text_selection.dart';

export 'package:flutter/services.dart' show TextSelection, TextInputType;

const Duration _kCursorBlinkHalfPeriod = const Duration(milliseconds: 500);

InputValue _getInputValueFromEditingValue(TextEditingValue value) {
  return new InputValue(
    text: value.text,
    selection: value.selection,
    composing: value.composing,
  );
}

TextEditingValue _getTextEditingValueFromInputValue(InputValue value) {
  return new TextEditingValue(
    text: value.text,
    selection: value.selection,
    composing: value.composing,
  );
}

/// Configuration information for a text input field.
///
/// An [InputValue] contains the text for the input field as well as the
/// selection extent and the composing range.
class InputValue {
  // TODO(abarth): This class is really the same as TextEditingState.
  // We should merge them into one object.

  /// Creates configuration information for an input field
  ///
  /// The selection and composing range must be within the text.
  ///
  /// The [text], [selection], and [composing] arguments must not be null but
  /// each have default values.
  const InputValue({
    this.text: '',
    this.selection: const TextSelection.collapsed(offset: -1),
    this.composing: TextRange.empty
  });

  /// The current text being edited.
  final String text;

  /// The range of text that is currently selected.
  final TextSelection selection;

  /// The range of text that is still being composed.
  final TextRange composing;

  /// An input value that corresponds to the empty string with no selection and no composing range.
  static const InputValue empty = const InputValue();

  @override
  String toString() => '$runtimeType(text: \u2524$text\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! InputValue)
      return false;
    final InputValue typedOther = other;
    return typedOther.text == text
        && typedOther.selection == selection
        && typedOther.composing == composing;
  }

  @override
  int get hashCode => hashValues(
    text.hashCode,
    selection.hashCode,
    composing.hashCode
  );

  /// Creates a copy of this input value but with the given fields replaced with the new values.
  InputValue copyWith({
    String text,
    TextSelection selection,
    TextRange composing
  }) {
    return new InputValue (
      text: text ?? this.text,
      selection: selection ?? this.selection,
      composing: composing ?? this.composing
    );
  }
}

/// A basic text input field.
///
/// This widget interacts with the [TextInput] service to let the user edit the
/// text it contains. It also provides scrolling, selection, and cursor
/// movement. This widget does not provide any focus management (e.g.,
/// tap-to-focus).
///
/// Rather than using this widget directly, consider using [InputField], which
/// adds tap-to-focus and cut, copy, and paste commands, or [TextField], which
/// is a full-featured, material-design text input field with placeholder text,
/// labels, and [Form] integration.
///
/// See also:
///
///  * [InputField], which adds tap-to-focus and cut, copy, and paste commands.
///  * [TextField], which is a full-featured, material-design text input field
///    with placeholder text, labels, and [Form] integration.
class EditableText extends StatefulWidget {
  /// Creates a basic text input control.
  ///
  /// The [value], [focusNode], [style], and [cursorColor] arguments must not
  /// be null.
  EditableText({
    Key key,
    @required this.value,
    @required this.focusNode,
    this.obscureText: false,
    @required this.style,
    @required this.cursorColor,
    this.textScaleFactor,
    this.maxLines: 1,
    this.autofocus: false,
    this.selectionColor,
    this.selectionControls,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key) {
    assert(value != null);
    assert(focusNode != null);
    assert(obscureText != null);
    assert(style != null);
    assert(cursorColor != null);
    assert(maxLines != null);
    assert(autofocus != null);
  }

  /// The string being displayed in this widget.
  final InputValue value;

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// Whether to hide the text being edited (e.g., for passwords).
  ///
  /// Defaults to false.
  final bool obscureText;

  /// The text style to use for the editable text.
  final TextStyle style;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// Defaults to [MediaQuery.textScaleFactor].
  final double textScaleFactor;

  /// The color to use when painting the cursor.
  final Color cursorColor;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  /// If this is 1 (the default), the text will not wrap, but will scroll
  /// horizontally instead.
  final int maxLines;

  /// Whether this input field should focus itself if nothing else is already focused.
  /// If true, the keyboard will open as soon as this input obtains focus. Otherwise,
  /// the keyboard is only shown after the user taps the text field.
  ///
  /// Defaults to false.
  final bool autofocus;

  /// The color to use when painting the selection.
  final Color selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  final TextSelectionControls selectionControls;

  /// The type of keyboard to use for editing the text.
  final TextInputType keyboardType;

  /// Called when the text being edited changes.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  EditableTextState createState() => new EditableTextState();
}

/// State for a [EditableText].
class EditableTextState extends State<EditableText> implements TextInputClient {
  Timer _cursorTimer;
  bool _showCursor = false;

  InputValue _currentValue;
  TextInputConnection _textInputConnection;
  TextSelectionOverlay _selectionOverlay;

  final ScrollController _scrollController = new ScrollController();
  bool _didAutoFocus = false;

  @override
  void initState() {
    super.initState();
    _currentValue = config.value;
    config.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoFocus && config.autofocus) {
      _didRequestKeyboard = true;
      FocusScope.of(context).autofocus(config.focusNode);
      _didAutoFocus = true;
    }
  }

  @override
  void didUpdateConfig(EditableText oldConfig) {
    if (_currentValue != config.value) {
      _currentValue = config.value;
      if (_isAttachedToKeyboard)
        _textInputConnection.setEditingState(_getTextEditingValueFromInputValue(_currentValue));
    }
    if (config.focusNode != oldConfig.focusNode) {
      oldConfig.focusNode.removeListener(_handleFocusChanged);
      config.focusNode.addListener(_handleFocusChanged);
    }
  }

  bool get _isAttachedToKeyboard => _textInputConnection != null && _textInputConnection.attached;

  bool get _isMultiline => config.maxLines > 1;

  // Calculate the new scroll offset so the cursor remains visible.
  double _getScrollOffsetForCaret(Rect caretRect) {
    final double caretStart = _isMultiline ? caretRect.top : caretRect.left;
    final double caretEnd = _isMultiline ? caretRect.bottom : caretRect.right;
    double scrollOffset = _scrollController.offset;
    final double viewportExtent = _scrollController.position.viewportDimension;
    if (caretStart < 0.0)  // cursor before start of bounds
      scrollOffset += caretStart;
    else if (caretEnd >= viewportExtent)  // cursor after end of bounds
      scrollOffset += caretEnd - viewportExtent;
    return scrollOffset;
  }

  bool _didRequestKeyboard = false;

  void _attachOrDetachKeyboard(bool focused) {
    if (focused && !_isAttachedToKeyboard && _didRequestKeyboard) {
      _textInputConnection = TextInput.attach(this, new TextInputConfiguration(inputType: config.keyboardType))
        ..setEditingState(_getTextEditingValueFromInputValue(_currentValue))
        ..show();
    } else if (!focused) {
      if (_isAttachedToKeyboard) {
        _textInputConnection.close();
        _textInputConnection = null;
      }
      _clearComposing();
    }
    _didRequestKeyboard = false;
  }

  void _clearComposing() {
    // TODO(abarth): We should call config.onChanged to notify our parent of
    // this change in our composing range.
    _currentValue = _currentValue.copyWith(composing: TextRange.empty);
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_isAttachedToKeyboard) {
      _textInputConnection.show();
    } else {
      _didRequestKeyboard = true;
      if (config.focusNode.hasFocus)
        _attachOrDetachKeyboard(true);
      else
        FocusScope.of(context).requestFocus(config.focusNode);
    }
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    _currentValue = _getInputValueFromEditingValue(value);
    if (config.onChanged != null)
      config.onChanged(_currentValue);
    if (_currentValue.text != config.value.text) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;
    }
  }

  @override
  void performAction(TextInputAction action) {
    _clearComposing();
    config.focusNode.unfocus();
    if (config.onSubmitted != null)
      config.onSubmitted(_currentValue);
  }

  void _handleSelectionChanged(TextSelection selection, RenderEditable renderObject, bool longPress) {
    // Note that this will show the keyboard for all selection changes on the
    // EditableWidget, not just changes triggered by user gestures.
    requestKeyboard();

    final InputValue newInput = _currentValue.copyWith(selection: selection, composing: TextRange.empty);
    if (config.onChanged != null)
      config.onChanged(newInput);

    if (_selectionOverlay != null) {
      _selectionOverlay.hide();
      _selectionOverlay = null;
    }

    if (config.selectionControls != null) {
      _selectionOverlay = new TextSelectionOverlay(
        input: newInput,
        context: context,
        debugRequiredFor: config,
        renderObject: renderObject,
        onSelectionOverlayChanged: _handleSelectionOverlayChanged,
        selectionControls: config.selectionControls,
      );
      if (newInput.text.isNotEmpty || longPress)
        _selectionOverlay.showHandles();
      if (longPress)
        _selectionOverlay.showToolbar();
    }
  }

  void _handleSelectionOverlayChanged(InputValue newInput, Rect caretRect) {
    assert(!newInput.composing.isValid);  // composing range must be empty while selecting
    if (config.onChanged != null)
      config.onChanged(newInput);
    _scrollController.jumpTo(_getScrollOffsetForCaret(caretRect));
  }

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  bool get cursorCurrentlyVisible => _showCursor;

  /// The cursor blink interval (the amount of time the cursor is in the "on"
  /// state or the "off" state). A complete cursor blink period is twice this
  /// value (half on, half off).
  Duration get cursorBlinkInterval => _kCursorBlinkHalfPeriod;

  void _cursorTick(Timer timer) {
    setState(() {
      _showCursor = !_showCursor;
    });
  }

  void _startCursorTimer() {
    _showCursor = true;
    _cursorTimer = new Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void _handleFocusChanged() {
    final bool focused = config.focusNode.hasFocus;
    _attachOrDetachKeyboard(focused);

    if (_cursorTimer == null && focused && config.value.selection.isCollapsed)
      _startCursorTimer();
    else if (_cursorTimer != null && (!focused || !config.value.selection.isCollapsed))
      _stopCursorTimer();

    if (_selectionOverlay != null) {
      if (focused) {
        _selectionOverlay.update(config.value);
      } else {
        _selectionOverlay?.dispose();
        _selectionOverlay = null;
      }
    }
  }

  @override
  void dispose() {
    if (_isAttachedToKeyboard) {
      _textInputConnection.close();
      _textInputConnection = null;
    }
    assert(!_isAttachedToKeyboard);
    if (_cursorTimer != null)
      _stopCursorTimer();
    assert(_cursorTimer == null);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    config.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _stopCursorTimer() {
    _cursorTimer.cancel();
    _cursorTimer = null;
    _showCursor = false;
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).reparentIfNeeded(config.focusNode);
    return new Scrollable(
      axisDirection: _isMultiline ? AxisDirection.down : AxisDirection.right,
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return new _Editable(
          value: _currentValue,
          style: config.style,
          cursorColor: config.cursorColor,
          showCursor: _showCursor,
          maxLines: config.maxLines,
          selectionColor: config.selectionColor,
          textScaleFactor: config.textScaleFactor ?? MediaQuery.of(context).textScaleFactor,
          obscureText: config.obscureText,
          offset: offset,
          onSelectionChanged: _handleSelectionChanged,
        );
      },
    );
  }
}

class _Editable extends LeafRenderObjectWidget {
  _Editable({
    Key key,
    this.value,
    this.style,
    this.cursorColor,
    this.showCursor,
    this.maxLines,
    this.selectionColor,
    this.textScaleFactor,
    this.obscureText,
    this.offset,
    this.onSelectionChanged,
  }) : super(key: key);

  final InputValue value;
  final TextStyle style;
  final Color cursorColor;
  final bool showCursor;
  final int maxLines;
  final Color selectionColor;
  final double textScaleFactor;
  final bool obscureText;
  final ViewportOffset offset;
  final SelectionChangedHandler onSelectionChanged;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return new RenderEditable(
      text: _styledTextSpan,
      cursorColor: cursorColor,
      showCursor: showCursor,
      maxLines: maxLines,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      selection: value.selection,
      offset: offset,
      onSelectionChanged: onSelectionChanged,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditable renderObject) {
    renderObject
      ..text = _styledTextSpan
      ..cursorColor = cursorColor
      ..showCursor = showCursor
      ..maxLines = maxLines
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..selection = value.selection
      ..offset = offset
      ..onSelectionChanged = onSelectionChanged;
  }

  TextSpan get _styledTextSpan {
    if (!obscureText && value.composing.isValid) {
      final TextStyle composingStyle = style.merge(
        const TextStyle(decoration: TextDecoration.underline)
      );

      return new TextSpan(
        style: style,
        children: <TextSpan>[
          new TextSpan(text: value.composing.textBefore(value.text)),
          new TextSpan(
            style: composingStyle,
            text: value.composing.textInside(value.text)
          ),
          new TextSpan(text: value.composing.textAfter(value.text))
      ]);
    }

    String text = value.text;
    if (obscureText)
      text = new String.fromCharCodes(new List<int>.filled(text.length, 0x2022));
    return new TextSpan(style: style, text: text);
  }
}
