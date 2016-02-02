// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky_services/editing/editing.mojom.dart' as mojom;
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'scrollable.dart';
import 'scroll_behavior.dart';

export 'package:flutter/painting.dart' show TextSelection;

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
    String text: '',
    TextSelection selection,
    this.onUpdated,
    this.onSubmitted
  }) : text = text, selection = selection ?? new TextSelection.collapsed(offset: text.length) {
    assert(onUpdated != null);
    assert(onSubmitted != null);
  }

  /// The current text being edited.
  String text;

  /// Called whenever the text changes.
  final VoidCallback onUpdated;

  /// Called whenever the user indicates they are done editing the string.
  final VoidCallback onSubmitted;

  // The range of text that is still being composed.
  TextRange composing = TextRange.empty;

  /// The range of text that is currently selected.
  TextSelection selection;

  /// A keyboard client stub that can be attached to a keyboard service.
  mojom.KeyboardClientStub createStub() {
    return new mojom.KeyboardClientStub.unbound()..impl = this;
  }

  mojom.EditingState get editingState {
    return new mojom.EditingState()
      ..text = text
      ..selectionBase = selection.baseOffset
      ..selectionExtent = selection.extentOffset
      ..selectionAffinity = mojom.TextAffinity.values[selection.affinity.index]
      ..selectionIsDirectional = selection.isDirectional
      ..composingBase = composing.start
      ..composingExtent = composing.end;
  }

  void updateEditingState(mojom.EditingState state) {
    text = state.text;
    selection = _getTextSelectionFromEditingState(state);
    composing = new TextRange(start: state.composingBase, end: state.composingExtent);
    onUpdated();
  }

  void submit(mojom.SubmitAction action) {
    composing = TextRange.empty;
    onSubmitted();
  }
}

/// A string that can be manipulated by a keyboard.
///
/// Can be displayed with [RawEditableLine]. For a more featureful input widget,
/// consider using [Input].
class EditableString {
  EditableString({
    String text: '',
    TextSelection selection,
    VoidCallback onUpdated,
    VoidCallback onSubmitted
  }) : _client = new _KeyboardClientImpl(
      text: text,
      selection: selection,
      onUpdated: onUpdated,
      onSubmitted: onSubmitted
    );

  final _KeyboardClientImpl _client;

  /// The current text being edited.
  String get text => _client.text;

  // The range of text that is still being composed.
  TextRange get composing => _client.composing;

  /// The range of text that is currently selected.
  TextSelection get selection => _client.selection;

  void setSelection(TextSelection selection) {
    _client.selection = selection;
  }

  mojom.EditingState get editingState => _client.editingState;

  /// A keyboard client stub that can be attached to a keyboard service.
  ///
  /// See [Keyboard].
  mojom.KeyboardClientStub createStub() => _client.createStub();

  void didDetachKeyboard() {
    _client.composing = TextRange.empty;
  }
}

/// A basic single-line input control.
///
/// This control is not intended to be used directly. Instead, consider using
/// [Input], which provides focus management and material design.
class RawEditableLine extends Scrollable {
  RawEditableLine({
    Key key,
    this.value,
    this.focused: false,
    this.hideText: false,
    this.style,
    this.cursorColor,
    this.selectionColor,
    this.onSelectionChanged
  }) : super(
    key: key,
    initialScrollOffset: 0.0,
    scrollDirection: Axis.horizontal
  );

  /// The editable string being displayed in this widget.
  final EditableString value;

  /// Whether this widget is focused.
  final bool focused;

  /// Whether to hide the text being edited (e.g., for passwords).
  final bool hideText;

  /// The text style to use for the editable text.
  final TextStyle style;

  /// The color to use when painting the cursor.
  final Color cursorColor;

  /// The color to use when painting the selection.
  final Color selectionColor;

  /// Called when the user requests a change to the selection.
  final ValueChanged<TextSelection> onSelectionChanged;

  RawEditableTextState createState() => new RawEditableTextState();
}

class RawEditableTextState extends ScrollableState<RawEditableLine> {
  Timer _cursorTimer;
  bool _showCursor = false;

  double _contentWidth = 0.0;
  double _containerWidth = 0.0;

  ScrollBehavior createScrollBehavior() => new BoundedBehavior();
  BoundedBehavior get scrollBehavior => super.scrollBehavior;

  void _handleContainerSizeChanged(Size newSize) {
    _containerWidth = newSize.width;
    _updateScrollBehavior();
  }

  void _handleContentSizeChanged(Size newSize) {
    _contentWidth = newSize.width;
    _updateScrollBehavior();
  }

  void _updateScrollBehavior() {
    // Set the scroll offset to match the content width so that the cursor
    // (which is always at the end of the text) will be visible.
    scrollTo(scrollBehavior.updateExtents(
      contentExtent: _contentWidth,
      containerExtent: _containerWidth,
      scrollOffset: _contentWidth
    ));
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

  void dispose() {
    if (_cursorTimer != null)
      _stopCursorTimer();
    super.dispose();
  }

  void _stopCursorTimer() {
    _cursorTimer.cancel();
    _cursorTimer = null;
    _showCursor = false;
  }

  Widget buildContent(BuildContext context) {
    assert(config.style != null);
    assert(config.focused != null);
    assert(config.cursorColor != null);

    if (_cursorTimer == null && config.focused && config.value.selection.isCollapsed)
      _startCursorTimer();
    else if (_cursorTimer != null && (!config.focused || !config.value.selection.isCollapsed))
      _stopCursorTimer();

    return new SizeObserver(
      onSizeChanged: _handleContainerSizeChanged,
      child: new _EditableLineWidget(
        value: config.value,
        style: config.style,
        cursorColor: config.cursorColor,
        showCursor: _showCursor,
        selectionColor: config.selectionColor,
        hideText: config.hideText,
        onContentSizeChanged: _handleContentSizeChanged,
        onSelectionChanged: config.onSelectionChanged,
        paintOffset: new Offset(-scrollOffset, 0.0)
      )
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
    this.selectionColor,
    this.hideText,
    this.onContentSizeChanged,
    this.onSelectionChanged,
    this.paintOffset
  }) : super(key: key);

  final EditableString value;
  final TextStyle style;
  final Color cursorColor;
  final bool showCursor;
  final Color selectionColor;
  final bool hideText;
  final ValueChanged<Size> onContentSizeChanged;
  final ValueChanged<TextSelection> onSelectionChanged;
  final Offset paintOffset;

  RenderEditableLine createRenderObject() {
    return new RenderEditableLine(
      text: _styledTextSpan,
      cursorColor: cursorColor,
      showCursor: showCursor,
      selectionColor: selectionColor,
      selection: value.selection,
      onContentSizeChanged: onContentSizeChanged,
      onSelectionChanged: onSelectionChanged,
      paintOffset: paintOffset
    );
  }

  void updateRenderObject(RenderEditableLine renderObject,
                          _EditableLineWidget oldWidget) {
    renderObject
      ..text = _styledTextSpan
      ..cursorColor = cursorColor
      ..showCursor = showCursor
      ..selectionColor = selectionColor
      ..selection = value.selection
      ..onContentSizeChanged = onContentSizeChanged
      ..onSelectionChanged = onSelectionChanged
      ..paintOffset = paintOffset;
  }

  StyledTextSpan get _styledTextSpan {
    if (!hideText && value.composing.isValid) {
      TextStyle composingStyle = style.merge(
        const TextStyle(decoration: TextDecoration.underline)
      );

      return new StyledTextSpan(style, <TextSpan>[
        new PlainTextSpan(value.composing.textBefore(value.text)),
        new StyledTextSpan(composingStyle, <TextSpan>[
          new PlainTextSpan(value.composing.textInside(value.text))
        ]),
        new PlainTextSpan(value.composing.textAfter(value.text))
      ]);
    }

    String text = value.text;
    if (hideText)
      text = new String.fromCharCodes(new List<int>.filled(text.length, 0x2022));
    return new StyledTextSpan(style, <TextSpan>[ new PlainTextSpan(text) ]);
  }
}
