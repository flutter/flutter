// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:mojo_services/keyboard/keyboard.mojom.dart';
import 'package:sky/painting.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/framework.dart';

const _kCursorBlinkPeriod = 500; // milliseconds
const _kCursorGap = 1.0;
const _kCursorHeightOffset = 2.0;
const _kCursorWidth = 1.0;

typedef void StringUpdated();

class TextRange {
  final int start;
  final int end;

  TextRange({this.start, this.end});
  TextRange.collapsed(int position)
      : start = position,
        end = position;
  const TextRange.empty()
      : start = -1,
        end = -1;

  bool get isValid => start >= 0 && end >= 0;
  bool get isCollapsed => start == end;
}

class EditableString implements KeyboardClient {
  String text;
  TextRange composing = const TextRange.empty();
  TextRange selection = const TextRange.empty();

  final StringUpdated onUpdated;

  KeyboardClientStub stub;

  EditableString({this.text: '', this.onUpdated}) {
    stub = new KeyboardClientStub.unbound()..impl = this;
  }

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
    TextRange afterRange =
        new TextRange(start: selection.end, end: selection.end + afterLength);
    _delete(afterRange);
    _delete(beforeRange);
    selection = new TextRange(
        start: selection.start - beforeLength,
        end: selection.end - beforeLength);
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
}

class EditableText extends StatefulComponent {
  EditableText({
    Key key,
    this.value,
    this.focused: false,
    this.style,
    this.cursorColor}) : super(key: key);

  final EditableString value;
  final bool focused;
  final TextStyle style;
  final Color cursorColor;

  EditableTextState createState() => new EditableTextState();
}

class EditableTextState extends State<EditableText> {
  Timer _cursorTimer;
  bool _showCursor = false;

  /// Whether the blinking cursor is visible (exposed for testing).
  bool get test_showCursor => _showCursor;

  /// The cursor blink interval (exposed for testing).
  Duration get test_cursorBlinkPeriod =>
      new Duration(milliseconds: _kCursorBlinkPeriod);

  void _cursorTick(Timer timer) {
    setState(() {
      _showCursor = !_showCursor;
    });
  }

  void _startCursorTimer() {
    _showCursor = true;
    _cursorTimer = new Timer.periodic(
      new Duration(milliseconds: _kCursorBlinkPeriod), _cursorTick);
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

  void _paintCursor(sky.Canvas canvas, Size size) {
    if (!_showCursor)
      return;

    double cursorHeight = config.style.fontSize + 2.0 * _kCursorHeightOffset;
    Rect cursorRect =  new Rect.fromLTWH(
      _kCursorGap,
      (size.height - cursorHeight) / 2.0,
      _kCursorWidth,
      cursorHeight
    );
    canvas.drawRect(cursorRect, new Paint()..color = config.cursorColor);
  }

  Widget build(BuildContext context) {
    assert(config.style != null);
    assert(config.focused != null);
    assert(config.cursorColor != null);

    if (config.focused && _cursorTimer == null)
      _startCursorTimer();
    else if (!config.focused && _cursorTimer != null)
      _stopCursorTimer();

    final EditableString value = config.value;
    final TextStyle style = config.style;

    Widget text;
    if (value.composing.isValid) {
      TextStyle composingStyle = style.merge(const TextStyle(decoration: underline));
      text = new StyledText(elements: [
        style,
        value.textBefore(value.composing),
        [composingStyle, value.textInside(value.composing)],
        value.textAfter(value.composing)
      ]);
    } else {
      // TODO(eseidel): This is the wrong height if empty!
      text = new Text(value.text, style: style);
    }

    Widget cursor = new Container(
      height: style.fontSize * style.height,
      width: _kCursorGap + _kCursorWidth,
      child: new CustomPaint(callback: _paintCursor, token: _showCursor)
    );

    return new Row([text, cursor]);
  }
}
