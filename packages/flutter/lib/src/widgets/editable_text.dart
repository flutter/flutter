// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:mojo_services/keyboard/keyboard.mojom.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

const _kCursorBlinkHalfPeriod = 500; // milliseconds

class TextRange {
  const TextRange({ this.start, this.end });
  const TextRange.collapsed(int position)
    : start = position,
      end = position;
  const TextRange.empty()
    : start = -1,
      end = -1;

  final int start;
  final int end;

  bool get isValid => start >= 0 && end >= 0;
  bool get isCollapsed => start == end;
}

class EditableString implements KeyboardClient {
  EditableString({this.text: '', this.onUpdated, this.onSubmitted}) {
    assert(onUpdated != null);
    assert(onSubmitted != null);
    stub = new KeyboardClientStub.unbound()..impl = this;
    selection = new TextRange(start: text.length, end: text.length);
  }

  String text;
  TextRange composing = const TextRange.empty();
  TextRange selection;

  final VoidCallback onUpdated;
  final VoidCallback onSubmitted;

  KeyboardClientStub stub;

  String textBefore(TextRange range) {
    return text.substring(0, range.start);
  }

  String textAfter(TextRange range) {
    return text.substring(range.end);
  }

  String textInside(TextRange range) {
    return text.substring(range.start, range.end);
  }

  void _delete(TextRange range) {
    if (range.isCollapsed || !range.isValid) return;
    text = textBefore(range) + textAfter(range);
  }

  TextRange _append(String newText) {
    int start = text.length;
    text += newText;
    return new TextRange(start: start, end: start + newText.length);
  }

  TextRange _replace(TextRange range, String newText) {
    assert(range.isValid);

    String before = textBefore(range);
    String after = textAfter(range);

    text = before + newText + after;
    return new TextRange(
        start: before.length, end: before.length + newText.length);
  }

  TextRange _replaceOrAppend(TextRange range, String newText) {
    if (!range.isValid) return _append(newText);
    return _replace(range, newText);
  }

  void commitCompletion(CompletionData completion) {
    // TODO(abarth): Not implemented.
  }

  void commitCorrection(CorrectionData correction) {
    // TODO(abarth): Not implemented.
  }

  void commitText(String text, int newCursorPosition) {
    // TODO(abarth): Why is |newCursorPosition| always 1?
    TextRange committedRange = _replaceOrAppend(composing, text);
    selection = new TextRange.collapsed(committedRange.end);
    composing = const TextRange.empty();
    onUpdated();
  }

  void deleteSurroundingText(int beforeLength, int afterLength) {
    TextRange beforeRange = new TextRange(
        start: selection.start - beforeLength, end: selection.start);
    int afterRangeEnd = math.min(selection.end + afterLength, text.length);
    TextRange afterRange =
        new TextRange(start: selection.end, end: afterRangeEnd);
    _delete(afterRange);
    _delete(beforeRange);
    selection = new TextRange(
      start: math.max(selection.start - beforeLength, 0),
      end: math.max(selection.end - beforeLength, 0)
    );
    onUpdated();
  }

  void setComposingRegion(int start, int end) {
    composing = new TextRange(start: start, end: end);
    onUpdated();
  }

  void setComposingText(String text, int newCursorPosition) {
    // TODO(abarth): Why is |newCursorPosition| always 1?
    composing = _replaceOrAppend(composing, text);
    selection = new TextRange.collapsed(composing.end);
    onUpdated();
  }

  void setSelection(int start, int end) {
    selection = new TextRange(start: start, end: end);
    onUpdated();
  }

  void submit(SubmitAction action) {
    onSubmitted();
  }
}

class EditableText extends StatefulComponent {
  EditableText({
    Key key,
    this.value,
    this.focused: false,
    this.hideText: false,
    this.style,
    this.cursorColor,
    this.onContentSizeChanged,
    this.scrollOffset
  }) : super(key: key);

  final EditableString value;
  final bool focused;
  final bool hideText;
  final TextStyle style;
  final Color cursorColor;
  final SizeChangedCallback onContentSizeChanged;
  final Offset scrollOffset;

  EditableTextState createState() => new EditableTextState();
}

class EditableTextState extends State<EditableText> {
  Timer _cursorTimer;
  bool _showCursor = false;

  /// Whether the blinking cursor is actually visible at this precise moment
  /// (it's hidden half the time, since it blinks).
  bool get cursorCurrentlyVisible => _showCursor;

  /// The cursor blink interval (the amount of time the cursor is in the "on"
  /// state or the "off" state). A complete cursor blink period is twice this
  /// value (half on, half off).
  Duration get cursorBlinkInterval => new Duration(milliseconds: _kCursorBlinkHalfPeriod);

  void _cursorTick(Timer timer) {
    setState(() {
      _showCursor = !_showCursor;
    });
  }

  void _startCursorTimer() {
    _showCursor = true;
    _cursorTimer = new Timer.periodic(
      new Duration(milliseconds: _kCursorBlinkHalfPeriod),
      _cursorTick
    );
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

  Widget build(BuildContext context) {
    assert(config.style != null);
    assert(config.focused != null);
    assert(config.cursorColor != null);

    if (config.focused && _cursorTimer == null)
      _startCursorTimer();
    else if (!config.focused && _cursorTimer != null)
      _stopCursorTimer();

    return new SizedBox(
      width: double.INFINITY,
      child: new _EditableTextWidget(
        value: config.value,
        style: config.style,
        cursorColor: config.cursorColor,
        showCursor: _showCursor,
        hideText: config.hideText,
        onContentSizeChanged: config.onContentSizeChanged,
        scrollOffset: config.scrollOffset
      )
    );
  }
}

final String _kZeroWidthSpace = new String.fromCharCode(0x200B);

class _EditableTextWidget extends LeafRenderObjectWidget {
  _EditableTextWidget({
    Key key,
    this.value,
    this.style,
    this.cursorColor,
    this.showCursor,
    this.hideText,
    this.onContentSizeChanged,
    this.scrollOffset
  }) : super(key: key);

  final EditableString value;
  final TextStyle style;
  final Color cursorColor;
  final bool showCursor;
  final bool hideText;
  final SizeChangedCallback onContentSizeChanged;
  final Offset scrollOffset;

  RenderEditableParagraph createRenderObject() {
    return new RenderEditableParagraph(
      text: _buildTextSpan(),
      cursorColor: cursorColor,
      showCursor: showCursor,
      onContentSizeChanged: onContentSizeChanged,
      scrollOffset: scrollOffset
    );
  }

  void updateRenderObject(RenderEditableParagraph renderObject,
                          _EditableTextWidget oldWidget) {
    renderObject.text = _buildTextSpan();
    renderObject.cursorColor = cursorColor;
    renderObject.showCursor = showCursor;
    renderObject.onContentSizeChanged = onContentSizeChanged;
    renderObject.scrollOffset = scrollOffset;
  }

  // Construct a TextSpan that renders the EditableString using the chosen style.
  TextSpan _buildTextSpan() {
    if (!hideText && value.composing.isValid) {
      TextStyle composingStyle = style.merge(
        const TextStyle(decoration: underline)
      );

      return new StyledTextSpan(style, <TextSpan>[
        new PlainTextSpan(value.textBefore(value.composing)),
        new StyledTextSpan(composingStyle, <TextSpan>[
          new PlainTextSpan(value.textInside(value.composing))
        ]),
        new PlainTextSpan(value.textAfter(value.composing))
      ]);
    }

    String text = value.text;
    if (hideText)
      text = new String.fromCharCodes(new List<int>.filled(text.length, 0x2022));
    return new StyledTextSpan(style, <TextSpan>[
      new PlainTextSpan(text.isEmpty ? _kZeroWidthSpace : text)
    ]);
  }
}
