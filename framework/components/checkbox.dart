// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'button_base.dart';
import 'dart:sky' as sky;

typedef void ValueChanged(value);

class Checkbox extends ButtonBase {
  static final Style _style = new Style('''
    transform: translateX(0);
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    -webkit-user-select: none;
    cursor: pointer;
    width: 30px;
    height: 30px;'''
  );

  static final Style _containerStyle = new Style('''
    border: solid 2px;
    border-color: rgba(90, 90, 90, 0.25);
    width: 10px;
    height: 10px;'''
  );

  static final Style _containerHighlightStyle = new Style('''
    border: solid 2px;
    border-color: rgba(90, 90, 90, 0.25);
    width: 10px;
    height: 10px;
    border-radius: 10px;
    background-color: orange;
    border-color: orange;'''
  );

  static final Style _uncheckedStyle = new Style('''
    top: 0px;
    left: 0px;'''
  );

  static final Style _checkedStyle = new Style('''
    top: 0px;
    left: 0px;
    transform: translate(2px, -15px) rotate(45deg);
    width: 10px;
    height: 20px;
    border-style: solid;
    border-top: none;
    border-left: none;
    border-right-width: 2px;
    border-bottom-width: 2px;
    border-color: #0f9d58;'''
  );

  bool checked;
  ValueChanged onChanged;

  Checkbox({ Object key, this.onChanged, this.checked }) : super(key: key);

  void _handleClick(sky.Event e) {
    onChanged(!checked);
  }

  UINode buildContent() {
    return new EventListenerNode(
      new Container(
        style: _style,
        children: [
          new Container(
            style: highlight ? _containerHighlightStyle : _containerStyle,
            children: [
              new Container(
                style: checked ? _checkedStyle : _uncheckedStyle
              )
            ]
          )
        ]
      ),
      onGestureTap: _handleClick
    );
  }
}
