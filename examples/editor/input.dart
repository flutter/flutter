// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/fn.dart';
import '../../framework/shell.dart' as shell;
import 'package:sky/services/keyboard/keyboard.mojom.dart';
import 'dart:math';

class Input extends Component implements KeyboardClient{
  static Style _style = new Style('''
    display: paragraph;
    padding: 10px;
    height: 200px;
    background-color: lightblue;'''
  );

  static Style _composingStyle = new Style('''
    display: inline;
    text-decoration: underline;'''
  );

  KeyboardServiceProxy _service;
  KeyboardClientStub _stub;

  String _text = "";
  int _composingStart = -1;
  int _composingEnd = -1;

  Input({Object key}) : super(key: key, stateful: true) {
    events.listen('click', _handleClick);
    _stub = new KeyboardClientStub.unbound()..impl = this;
  }

  bool get _hasComposingRegion => _composingStart != -1 && _composingEnd != -1;

  void _handleClick(_) {
    if (_service != null)
      return;
    _service = new KeyboardServiceProxy.unbound();
    shell.requestService(_service);
    _service.ptr.show(_stub);
  }

  void _replaceComposing(String text) {
    if (!_hasComposingRegion) {
      _composingStart = _text.length;
      _composingEnd = _composingStart + text.length;
      _text += text;
      return;
    }

    _text = _text.substring(0, _composingStart)
        + text + _text.substring(_composingEnd);
    _composingEnd = _composingStart + text.length;
  }

  void _clearComposingRegion() {
    _composingStart = -1;
    _composingEnd = -1;
  }

  void commitText(String text, int newCursorPosition) {
    setState(() {
      _replaceComposing(text);
      _clearComposingRegion();
    });
  }

  void setComposingText(String text, int newCursorPosition) {
    setState(() {
      _replaceComposing(text);
    });
  }

  void setComposingRegion(int start, int end) {
    setState(() {
      _composingStart = start;
      _composingEnd = end;
    });
  }

  Node build() {
    List<Node> children = new List<Node>();

    if (!_hasComposingRegion) {
      children.add(new Text(_text));
    } else {
      String run = _text.substring(0, _composingStart);
      if (!run.isEmpty)
        children.add(new Text(run));

      run = _text.substring(_composingStart, _composingEnd);
      if (!run.isEmpty) {
        children.add(new Container(
          style: _composingStyle,
          children: [new Text(_text.substring(_composingStart, _composingEnd))]
        ));
      }

      run = _text.substring(_composingEnd);
      if (!run.isEmpty)
        children.add(new Text(_text.substring(_composingEnd)));
    }

    return new Container(
      style: _style,
      children: children
    );
  }
}
