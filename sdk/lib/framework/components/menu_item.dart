// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library components_menu_item;

import '../fn.dart';
import '../layout.dart';
import 'button_base.dart';
import 'icon.dart';
import 'ink_well.dart';

class MenuItem extends ButtonBase {
  static final Style _style = new Style('''
    align-items: center;
    height: 48px;
    -webkit-user-select: none;'''
  );

  static final Style _highlightStyle = new Style('''
    align-items: center;
    height: 48px;
    background: rgba(153, 153, 153, 0.4);
    -webkit-user-select: none;'''
  );

  static final Style _iconStyle = new Style('''
    padding: 0px 16px;'''
  );

  static final Style _labelStyle = new Style('''
    padding: 0px 16px;'''
  );

  static final FlexBoxParentData _labelFlex = new FlexBoxParentData()..flex = 1;

  List<UINode> children;
  String icon;
  GestureEventListener onGestureTap;

  MenuItem({ Object key, this.icon, this.children, this.onGestureTap }) : super(key: key);

  UINode buildContent() {
    return new EventListenerNode(
      new StyleNode(
        new InkWell(
          children: [
            new StyleNode(
              new Icon(
                size: 24,
                type: "${icon}_grey600"
              ),
              _iconStyle
            ),
            new ParentDataNode(
              new FlexContainer(
                direction: FlexDirection.Row,
                style: _labelStyle,
                children: children
              ),
              _labelFlex
            )
          ]
        ),
        highlight ? _highlightStyle : _style
      ),
      onGestureTap: onGestureTap
    );
  }
}
