// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../rendering/flex.dart';
import '../theme2/view_configuration.dart';
import '../theme2/shadows.dart';

class ToolBar extends Component {

  ToolBar({
    String key,
    this.left,
    this.center,
    this.right,
    this.backgroundColor
  }) : super(key: key);

  final UINode left;
  final UINode center;
  final List<UINode> right;
  final Color backgroundColor;

  UINode build() {
    List<UINode> children = [
      left,
      new FlexExpandingChild(
        new Padding(
          child: center,
          padding: new EdgeDims.only(left: 24.0)
        ))
    ];

    if (right != null)
      children.addAll(right);

    // TODO(hansmuller): use align-items:flex-end when Flex supports it.
    UINode bottomJustifiedChild = new Flex([
        new Container(child: new Flex(children), height: kToolBarHeight)
      ],
      direction: FlexDirection.vertical,
      justifyContent: FlexJustifyContent.flexEnd);

    return new Container(
      child: bottomJustifiedChild,
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(
        backgroundColor: backgroundColor,
        boxShadow: Shadow[2]
      )
    );
  }

}
