// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/colors.dart';
import 'dart:async';
import 'editable_string.dart';

class EditableText extends Component {
  static final Style _style = new Style('''
    display: inline;'''
  );

  static final Style _cusorStyle = new Style('''
    display: inline-flex;
    width: 2px;
    height: 1.2em;
    vertical-align: top;
    background-color: ${Blue[500]};'''
  );

  static final Style _composingStyle = new Style('''
    display: inline;
    text-decoration: underline;'''
  );

  EditableString value;
  bool focused;
  Timer _cursorTimer;
  bool _showCursor = false;

  EditableText({Object key, this.value, this.focused})
      : super(key: key, stateful: true) {
    onDidUnmount(() {
      if (_cursorTimer != null)
        _stopCursorTimer();
    });
  }

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

  void _stopCursorTimer() {
    _cursorTimer.cancel();
    _cursorTimer = null;
    _showCursor = false;
  }

  UINode build() {
    if (focused && _cursorTimer == null)
      _startCursorTimer();
    else if (!focused && _cursorTimer != null)
      _stopCursorTimer();

    List<UINode> children = new List<UINode>();

    if (!value.composing.isValid) {
      children.add(new Text(value.text));
    } else {
      String beforeComposing = value.textBefore(value.composing);
      if (!beforeComposing.isEmpty)
        children.add(new Text(beforeComposing));

      String composing = value.textInside(value.composing);
      if (!composing.isEmpty) {
        children.add(new Container(
          key: 'composing',
          style: _composingStyle,
          children: [new Text(composing)]
        ));
      }

      String afterComposing = value.textAfter(value.composing);
      if (!afterComposing.isEmpty)
        children.add(new Text(afterComposing));
    }

    if (_showCursor)
      children.add(new Container(key: 'cursor', style: _cusorStyle));

    return new Container(
      style: _style,
      children: children
    );
  }
}
