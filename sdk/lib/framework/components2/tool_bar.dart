// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../theme/view_configuration.dart';
import '../theme2/shadows.dart';

class ToolBar extends Component {

  ToolBar({
    String key,
    this.left,
    this.center,
    this.right,
    this.backgroundColor
  }) : super(key: key);

  UINode left;
  UINode center;
  List<UINode> right;
  Color backgroundColor;

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

    return new Container(
      child: new FlexContainer(
        children: children,
        direction: FlexDirection.horizontal
      ),
      height: 56.0,
      padding: new EdgeDims(kStatusBarHeight.toDouble(), 8.0, 0.0, 8.0),
      decoration: new BoxDecoration(
        backgroundColor: backgroundColor,
        boxShadow: Shadow[2]
      )
    );
  }

}
