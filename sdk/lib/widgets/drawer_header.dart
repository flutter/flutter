// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme2/colors.dart';
import '../theme2/view_configuration.dart';
import 'basic.dart';

class DrawerHeader extends Component {

  DrawerHeader({ String key, this.children }) : super(key: key);

  final List<Widget> children;

  Widget build() {
    return new Container(
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
      child: new Flex([
        new Flexible(child: new Container(key: 'drawer-header-spacer')),
        new Container(
          key: 'drawer-header-label',
          padding: const EdgeDims.symmetric(horizontal: 16.0),
          child: new Flex(children, direction: FlexDirection.horizontal)
        )],
        direction: FlexDirection.vertical
      )
    );
  }

}
