// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../painting/text_style.dart';
import '../widgets/basic.dart';
import 'editable_string.dart';

class EditableText extends Component {

  EditableText({String key, this.value, this.focused})
      : super(key: key, stateful: true);

  // static final Style _cursorStyle = new Style('''
  //   width: 2px;
  //   height: 1.2em;
  //   vertical-align: top;
  //   background-color: ${Blue[500]};'''
  // );

  EditableString value;
  bool focused;

  void syncFields(EditableText source) {
    value = source.value;
    focused = source.focused;
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
        new Duration(milliseconds: 500), _cursorTick);
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

  Widget build() {
    if (focused && _cursorTimer == null)
      _startCursorTimer();
    else if (!focused && _cursorTimer != null)
      _stopCursorTimer();

    if (!value.composing.isValid) {
      return new Text(value.text);
    }

    return new StyledText(elements: [
      const TextStyle(),
      value.textBefore(value.composing),
      [const TextStyle(decoration: underline), value.textInside(value.composing)],
      value.textAfter(value.composing)
    ]);
  }
}
