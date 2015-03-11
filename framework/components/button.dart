// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'button_base.dart';
import 'material.dart';

class Button extends ButtonBase {
  static final Style _style = new Style('''
    transform: translateX(0);
    display: inline-flex;
    border-radius: 4px;
    justify-content: center;
    align-items: center;
    border: 1px solid blue;
    -webkit-user-select: none;
    margin: 5px;'''
  );

  static final Style _highlightStyle = new Style('''
    transform: translateX(0);
    display: inline-flex;
    border-radius: 4px;
    justify-content: center;
    align-items: center;
    border: 1px solid blue;
    -webkit-user-select: none;
    margin: 5px;
    background-color: orange;'''
  );

  Node content;

  Button({ Object key, this.content }) : super(key: key);

  Node build() {
    return new Material(
      style: highlight ? _highlightStyle : _style,
      children: [content]
    );
  }
}
