// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../theme/colors.dart';
import '../theme/view_configuration.dart';

class DrawerHeader extends Component {
  static final Style _style = new Style('''
    height: ${140 + kStatusBarHeight}px;
    background-color: ${BlueGrey[50]};
    border-bottom: 1px solid #D1D9E1;
    padding-bottom: 7px;
    margin-bottom: 8px;'''
  );

  static final FlexBoxParentData _spacerParentData = new FlexBoxParentData()..flex = 1;

  static final Style _labelStyle = new Style('''
    padding: 0 16px;'''
  );

  List<UINode> children;

  DrawerHeader({ Object key, this.children }) : super(key: key);

  UINode build() {
    return new FlexContainer(
      direction: FlexDirection.vertical,
      style: _style,
      children: [
        new ParentDataNode(
          new Container(key: 'Spacer'),
          _spacerParentData
        ),
        new Container(
          key: 'Label',
          style: _labelStyle,
          children: children
        )
      ]
    );
  }
}
