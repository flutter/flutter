// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:mojo_services/keyboard/keyboard.mojom.dart';
import 'package:sky/painting.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';

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

  EditableString value;
  bool focused;
  TextStyle style;
  Color cursorColor;

  void syncConstructorArguments(EditableText source) {
    value = source.value;
    focused = source.focused;
    style = source.style;
    cursorColor = source.cursorColor;
  }

  Timer _cursorTimer;
  bool _showCursor = false;

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

  void didUnmount() {
    if (_cursorTimer != null)
      _stopCursorTimer();
    super.didUnmount();
  }

  void _stopCursorTimer() {
    _cursorTimer.cancel();
    _cursorTimer = null;
    _showCursor = false;
  }

  void _paintCursor(sky.Canvas canvas, Size size) {
    if (!_showCursor)
      return;

    Rect cursorRect =  new Rect.fromLTWH(
      _kCursorGap,
      -_kCursorHeightOffset,
      _kCursorWidth,
      style.fontSize + 2 * _kCursorHeightOffset
    );
    canvas.drawRect(cursorRect, new Paint()..color = cursorColor);
  }

  Widget build() {
    assert(style != null);
    assert(focused != null);
    assert(cursorColor != null);

    if (focused && _cursorTimer == null)
      _startCursorTimer();
    else if (!focused && _cursorTimer != null)
      _stopCursorTimer();

    if (!value.composing.isValid) {
      // TODO(eseidel): This is the wrong height if empty!
      return new Row([new Text(value.text, style: style)]);
    }

    TextStyle composingStyle = style.merge(const TextStyle(decoration: underline));
    StyledText text = new StyledText(elements: [
      style,
      value.textBefore(value.composing),
      [composingStyle, value.textInside(value.composing)],
      value.textAfter(value.composing)
    ]);

    Widget cursor = new Container(
      height: style.fontSize,
      width: _kCursorGap + _kCursorWidth,
      child: new CustomPaint(callback: _paintCursor, token: _showCursor)
    );

    return new Row([text, cursor]);
  }
}
