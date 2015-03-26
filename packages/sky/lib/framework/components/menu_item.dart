// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'button_base.dart';
import 'icon.dart';
import 'ink_well.dart';

class MenuItem extends ButtonBase {
  static final Style _style = new Style('''
    transform: translateX(0);
    display: flex;
    align-items: center;
    height: 48px;
    -webkit-user-select: none;'''
  );

  static final Style _highlightStyle = new Style('''
    transform: translateX(0);
    display: flex;
    align-items: center;
    height: 48px;
    background: rgba(153, 153, 153, 0.4);
    -webkit-user-select: none;'''
  );

  static final Style _iconStyle = new Style('''
    padding: 0px 16px;'''
  );

  static final Style _labelStyle = new Style('''
    padding: 0px 16px;
    flex: 1;'''
  );

  List<Node> children;
  String icon;

  MenuItem({ Object key, this.icon, this.children }) : super(key: key);

  Node buildContent() {
    return new StyleNode(
      new InkWell(
        children: [
          new StyleNode(
            new Icon(
              size: 24,
              type: "${icon}_grey600"
            ),
            _iconStyle
          ),
          new Container(
            style: _labelStyle,
            children: children
          )
        ]
      ),
      highlight ? _highlightStyle : _style
    );
  }
}
