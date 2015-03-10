// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/fn.dart';
import '../../framework/shell.dart' as shell;
import 'dart:async';
import 'dart:math';
import 'editable_string.dart';
import 'package:sky/services/keyboard/keyboard.mojom.dart';

class EditableText extends Component {
  static Style _style = new Style('''
    display: paragraph;
    white-space: pre-wrap;
    padding: 10px;
    height: 200px;
    background-color: lightblue;'''
  );

  static Style _cusorStyle = new Style('''
    display: inline-block;
    width: 2px;
    height: 1.2em;
    vertical-align: top;
    background-color: blue;'''
  );

  static Style _composingStyle = new Style('''
    display: inline;
    text-decoration: underline;'''
  );

  KeyboardServiceProxy _service;

  EditableString _string;
  Timer _cursorTimer;
  bool _showCursor = false;

  EditableText({Object key}) : super(key: key, stateful: true) {
    _string = new EditableString(text: '', onChanged: _handleTextChanged);
    events.listen('click', _handleClick);
    events.listen('focus', _handleFocus);
    events.listen('blur', _handleBlur);
  }

  void _handleTextChanged(EditableString string) {
    setState(() {
      _string = string;
      _showCursor = true;
      _restartCursorTimer();
    });
  }

  void _handleClick(_) {
    if (_service != null)
      return;
    _service = new KeyboardServiceProxy.unbound();
    shell.requestService(_service);
    _service.ptr.show(_string.stub);
    _restartCursorTimer();
    setState(() {
      _showCursor = true;
    });
  }

  void _handleFocus(_) {
    print("_handleFocus");
  }

  void _handleBlur(_) {
    print("_handleBlur");
  }

  void _cursorTick(Timer timer) {
    setState(() {
      _showCursor = !_showCursor;
    });
  }

  void _restartCursorTimer() {
    if (_cursorTimer != null)
      _cursorTimer.cancel();
    _cursorTimer = new Timer.periodic(
        new Duration(milliseconds: 500), _cursorTick);
  }

  void didUnmount() {
    _cursorTimer.cancel();
  }

  Node build() {
    List<Node> children = new List<Node>();

    if (!_string.composing.isValid) {
      children.add(new Text(_string.text));
    } else {
      String beforeComposing = _string.textBefore(_string.composing);
      if (!beforeComposing.isEmpty)
        children.add(new Text(beforeComposing));

      String composing = _string.textInside(_string.composing);
      if (!composing.isEmpty) {
        children.add(new Container(
          key: 'composing', 
          style: _composingStyle,
          children: [new Text(composing)]
        ));
      }

      String afterComposing = _string.textAfter(_string.composing);
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
