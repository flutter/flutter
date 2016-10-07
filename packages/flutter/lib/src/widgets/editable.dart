// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart' show RenderEditableLine, SelectionChangedHandler;
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:flutter_services/editing.dart' as mojom;

import 'basic.dart';
import 'focus.dart';
import 'framework.dart';
import 'media_query.dart';
import 'scroll_behavior.dart';
import 'scrollable.dart';
import 'text_selection.dart';

export 'package:flutter/painting.dart' show TextSelection;
export 'package:flutter_services/editing.dart' show KeyboardType;

const Duration _kCursorBlinkHalfPeriod = const Duration(milliseconds: 500);

TextSelection _getTextSelectionFromEditingState(mojom.EditingState state) {
  return new TextSelection(
    baseOffset: state.selectionBase,
    extentOffset: state.selectionExtent,
    affinity: TextAffinity.values[state.selectionAffinity.mojoEnumValue],
    isDirectional: state.selectionIsDirectional
  );
}

class _KeyboardClientImpl implements mojom.KeyboardClient {
  _KeyboardClientImpl({
    this.inputValue,
    this.onUpdated,
    this.onSubmitted
  }) {
    assert(inputValue != null);
    assert(onUpdated != null);
    assert(onSubmitted != null);
  }

  InputValue inputValue;

  /// Called whenever the text changes.
  final VoidCallback onUpdated;

  /// Called whenever the user indicates they are done editing the string.
  final VoidCallback onSubmitted;

  /// A keyboard client stub that can be attached to a keyboard service.
  mojom.KeyboardClientStub createStub() {
    return new mojom.KeyboardClientStub.unbound()..impl = this;
  }

  mojom.EditingState get editingState {
    return new mojom.EditingState()
      ..text = inputValue.text
      ..selectionBase = inputValue.selection.baseOffset
      ..selectionExtent = inputValue.selection.extentOffset
      ..selectionAffinity = mojom.TextAffinity.values[inputValue.selection.affinity.index]
      ..selectionIsDirectional = inputValue.selection.isDirectional
      ..composingBase = inputValue.composing.start
      ..composingExtent = inputValue.composing.end;
  }

  @override
  void updateEditingState(mojom.EditingState state) {
    inputValue = new InputValue(
      text: state.text,
      selection: _getTextSelectionFromEditingState(state),
      composing: new TextRange(start: state.composingBase, end: state.composingExtent)
    );
    onUpdated();
  }

  void clearComposing() {
    inputValue = inputValue.copyWith(composing: TextRange.empty);
  }

  @override
  void submit(mojom.SubmitAction action) {
    clearComposing();
    onSubmitted();
  }
}

/// Configuration information for an input field.
///
/// An [InputValue] contains the text for the input field as well as the
/// selection extent and the composing range.
class InputValue {
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
    InputValue typedOther = other;
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

/// A basic single-line input control.
///
/// This control is not intended to be used directly. Instead, consider using
/// [Input], which provides focus management and material design.
//
// TODO(mpcomplete): rename RawInput since it can span multiple lines.
class RawInputLine extends Scrollable {
  /// Creates a basic single-line input control.
  ///
  /// The [value] argument must not be null.
  RawInputLine({
    Key key,
    @required this.value,
    this.focusKey,
    this.hideText: false,
    this.style,
    this.cursorColor,
    this.textScaleFactor,
    this.multiline,
    this.selectionColor,
    this.selectionControls,
    @required this.platform,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted
  }) : super(
    key: key,
    initialScrollOffset: 0.0,
    scrollDirection: Axis.horizontal
  ) {
    assert(value != null);
  }

  /// The string being displayed in this widget.
  final InputValue value;

  /// Key of the enclosing widget that holds the focus.
  final GlobalKey focusKey;

  /// Whether to hide the text being edited (e.g., for passwords).
  final bool hideText;

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

  /// True if the text should wrap and span multiple lines, false if it should
  /// stay on a single line and scroll when overflowed.
  final bool multiline;

  /// The color to use when painting the selection.
  final Color selectionColor;

  /// Optional delegate for building the text selection handles and toolbar.
  final TextSelectionControls selectionControls;

  /// The platform whose behavior should be approximated, in particular
  /// for scroll physics. (See [ScrollBehavior.platform].)
  ///
  /// Must not be null.
  final TargetPlatform platform;

  /// The type of keyboard to use for editing the text.
  final KeyboardType keyboardType;

  /// Called when the text being edited changes.
  final ValueChanged<InputValue> onChanged;

  /// Called when the user indicates that they are done editing the text in the field.
  final ValueChanged<InputValue> onSubmitted;

  @override
  RawInputLineState createState() => new RawInputLineState();
}

/// State for a [RawInputLine].
class RawInputLineState extends ScrollableState<RawInputLine> {
  Timer _cursorTimer;
  bool _showCursor = false;

  _KeyboardClientImpl _keyboardClient;
  KeyboardHandle _keyboardHandle;
  TextSelectionOverlay _selectionOverlay;

  @override
  ExtentScrollBehavior createScrollBehavior() => new BoundedBehavior(platform: config.platform);

  @override
  BoundedBehavior get scrollBehavior => super.scrollBehavior;

  @override
  void initState() {
    super.initState();
    _keyboardClient = new _KeyboardClientImpl(
      inputValue: config.value,
      onUpdated: _handleTextUpdated,
      onSubmitted: _handleTextSubmitted
    );
  }

  @override
  void didUpdateConfig(RawInputLine oldConfig) {
    if (_keyboardClient.inputValue != config.value) {
      _keyboardClient.inputValue = config.value;
      if (_isAttachedToKeyboard)
        _keyboardHandle.setEditingState(_keyboardClient.editingState);
    }
  }

  bool get _isAttachedToKeyboard => _keyboardHandle != null && _keyboardHandle.attached;

  double _contentWidth = 0.0;
  double _containerWidth = 0.0;

  Offset _handlePaintOffsetUpdateNeeded(ViewportDimensions dimensions) {
    // We make various state changes here but don't have to do so in a
    // setState() callback because we are called during layout and all
    // we're updating is the new offset, which we are providing to the
    // render object via our return value.
    _containerWidth = dimensions.containerSize.width;
    _contentWidth = dimensions.contentSize.width;
    didUpdateScrollBehavior(scrollBehavior.updateExtents(
      contentExtent: _contentWidth,
      containerExtent: _containerWidth,
      // Set the scroll offset to match the content width so that the
      // cursor (which is always at the end of the text) will be
      // visible.
      // TODO(ianh): We should really only do this when text is added,
      // not generally any time the size changes.
      scrollOffset: pixelOffsetToScrollOffset(-_contentWidth)
    ));
    updateGestureDetector();
    return scrollOffsetToPixelDelta(scrollOffset);
  }

  void _attachOrDetachKeyboard(bool focused) {
    if (focused && !_isAttachedToKeyboard) {
      _keyboardHandle = keyboard.attach(_keyboardClient.createStub(),
                                        new mojom.KeyboardConfiguration()
                                          ..type = config.keyboardType);
      _keyboardHandle.setEditingState(_keyboardClient.editingState);
      _keyboardHandle.show();
    } else if (!focused) {
      if (_isAttachedToKeyboard) {
        _keyboardHandle.release();
        _keyboardHandle = null;
      }
      _keyboardClient.clearComposing();
    }
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
      _keyboardHandle.show();
    } else {
      Focus.moveTo(config.focusKey);
    }
  }

  void _handleTextUpdated() {
    if (config.onChanged != null)
      config.onChanged(_keyboardClient.inputValue);
    if (_keyboardClient.inputValue.text != config.value.text) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;
    }
  }

  void _handleTextSubmitted() {
    Focus.clear(context);
    if (config.onSubmitted != null)
      config.onSubmitted(_keyboardClient.inputValue);
  }

  void _handleSelectionChanged(TextSelection selection, RenderEditableLine renderObject, bool longPress) {
    // Note that this will show the keyboard for all selection changes on the
    // EditableLineWidget, not just changes triggered by user gestures.
    requestKeyboard();

    InputValue newInput = new InputValue(text: _keyboardClient.inputValue.text, selection: selection);
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

  void _handleSelectionOverlayChanged(InputValue newInput) {
    assert(!newInput.composing.isValid);  // composing range must be empty while selecting
    if (config.onChanged != null)
      config.onChanged(newInput);
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

  @override
  void dispose() {
    if (_isAttachedToKeyboard)
      _keyboardHandle.release();
    if (_cursorTimer != null)
      _stopCursorTimer();
    _selectionOverlay?.dispose();
    super.dispose();
  }

  void _stopCursorTimer() {
    _cursorTimer.cancel();
    _cursorTimer = null;
    _showCursor = false;
  }

  @override
  Widget buildContent(BuildContext context) {
    assert(config.style != null);
    assert(config.focusKey != null);
    assert(config.cursorColor != null);

    bool focused = Focus.at(config.focusKey.currentContext);
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

    return new _EditableLineWidget(
      value: _keyboardClient.inputValue,
      style: config.style,
      cursorColor: config.cursorColor,
      showCursor: _showCursor,
      multiline: config.multiline,
      selectionColor: config.selectionColor,
      textScaleFactor: config.textScaleFactor ?? MediaQuery.of(context).textScaleFactor,
      hideText: config.hideText,
      onSelectionChanged: _handleSelectionChanged,
      paintOffset: scrollOffsetToPixelDelta(scrollOffset),
      onPaintOffsetUpdateNeeded: _handlePaintOffsetUpdateNeeded
    );
  }
}

class _EditableLineWidget extends LeafRenderObjectWidget {
  _EditableLineWidget({
    Key key,
    this.value,
    this.style,
    this.cursorColor,
    this.showCursor,
    this.multiline,
    this.selectionColor,
    this.textScaleFactor,
    this.hideText,
    this.onSelectionChanged,
    this.paintOffset,
    this.onPaintOffsetUpdateNeeded
  }) : super(key: key);

  final InputValue value;
  final TextStyle style;
  final Color cursorColor;
  final bool showCursor;
  final bool multiline;
  final Color selectionColor;
  final double textScaleFactor;
  final bool hideText;
  final SelectionChangedHandler onSelectionChanged;
  final Offset paintOffset;
  final ViewportDimensionsChangeCallback onPaintOffsetUpdateNeeded;

  @override
  RenderEditableLine createRenderObject(BuildContext context) {
    return new RenderEditableLine(
      text: _styledTextSpan,
      cursorColor: cursorColor,
      showCursor: showCursor,
      multiline: multiline,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      selection: value.selection,
      onSelectionChanged: onSelectionChanged,
      paintOffset: paintOffset,
      onPaintOffsetUpdateNeeded: onPaintOffsetUpdateNeeded
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditableLine renderObject) {
    renderObject
      ..text = _styledTextSpan
      ..cursorColor = cursorColor
      ..showCursor = showCursor
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..selection = value.selection
      ..onSelectionChanged = onSelectionChanged
      ..paintOffset = paintOffset
      ..onPaintOffsetUpdateNeeded = onPaintOffsetUpdateNeeded;
  }

  TextSpan get _styledTextSpan {
    if (!hideText && value.composing.isValid) {
      TextStyle composingStyle = style.merge(
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
    if (hideText)
      text = new String.fromCharCodes(new List<int>.filled(text.length, 0x2022));
    return new TextSpan(style: style, text: text);
  }
}
