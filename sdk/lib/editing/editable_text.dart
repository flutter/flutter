// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import '../painting/text_style.dart';
import '../rendering/object.dart';
import '../widgets/basic.dart';
import 'editable_string.dart';

const _kCursorBlinkPeriod = 500; // milliseconds
const _kCursorGap = 1.0;
const _kCursorHeightOffset = 2.0;
const _kCursorWidth = 1.0;

class EditableText extends StatefulComponent {

  EditableText({
    String key,
    this.value,
    this.focused: false,
    this.style,
    this.cursorColor}) : super(key: key);

  EditableString value;
  bool focused;
  TextStyle style;
  Color cursorColor;

  void syncFields(EditableText source) {
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
      return new Text(value.text, style: style);
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

    return new Flex([text, cursor]);
  }
}
