// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../theme2/colors.dart';
import '../theme2/view_configuration.dart';

class DrawerHeader extends Component {

  DrawerHeader({ Object key, this.children }) : super(key: key);

  List<UINode> children;

  UINode build() {
    return new Container(
      key: 'drawer-header-outside',
      height: kStatusBarHeight + kMaterialDrawerHeight,
      decoration: new BoxDecoration(
        backgroundColor: BlueGrey[50],
        border: const Border(
          bottom: const BorderSide(
            color: const Color(0xFFD1D9E1),
            width: 1.0
          )
        )
      ),
      padding: const EdgeDims.only(bottom: 7.0),
      margin: const EdgeDims.only(bottom: 8.0),
      child: new FlexContainer(
        key: 'drawer-header-inside',
        direction: FlexDirection.vertical,
        children: [
          new FlexExpandingChild(new Container(key: 'drawer-header-spacer')),
          new Container(
            key: 'drawer-header-label',
            padding: const EdgeDims.symmetric(horizontal: 16.0),
            child: new FlexContainer(
              direction: FlexDirection.horizontal,
              children: children
            )
          )
        ]
      )
    );
  }

}
