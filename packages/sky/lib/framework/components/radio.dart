// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'button_base.dart';
import 'ink_well.dart';
import 'material.dart';

typedef void ValueChanged(value);

class Radio extends ButtonBase {
  Object value;
  Object groupValue;
  ValueChanged onChanged;

  static final Style _style = new Style('''
    transform: translateX(0);
    display: inline-block;
    -webkit-user-select: none;
    width: 14px;
    height: 14px;
    border-radius: 7px;
    border: 1px solid blue;
    margin: 0 5px;'''
  );

  static final Style _highlightStyle = new Style('''
    transform: translateX(0);
    display: inline-block;
    -webkit-user-select: none;
    width: 14px;
    height: 14px;
    border-radius: 7px;
    border: 1px solid blue;
    margin: 0 5px;
    background-color: orange;'''
  );

  static final Style _dotStyle = new Style('''
    -webkit-user-select: none;
    width: 10px;
    height: 10px;
    border-radius: 5px;
    background-color: black;
    margin: 2px;'''
  );

  Radio({
    Object key,
    this.onChanged,
    this.value,
    this.groupValue
  }) : super(key: key);

  Node buildContent() {
    return new EventTarget(
      new InkWell(
        style: highlight ? _highlightStyle : _style,
        children: value == groupValue ? [new Container(style: _dotStyle )] : []
      ),
      onGestureTap: _handleClick
    );
  }

  void _handleClick(_) {
    onChanged(value);
  }
}
