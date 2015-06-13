// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../rendering/flex.dart';
import '../theme2/shadows.dart';
import '../theme2/view_configuration.dart';
import 'basic.dart';

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
    List<UINode> children = new List<UINode>();
    if (left != null)
      children.add(left);

    if (center != null) {
      children.add(new FlexExpandingChild(
        new Padding(child: center, padding: new EdgeDims.only(left: 24.0))));
    }

    if (right != null)
      children.addAll(right);

    return new Container(
      child: new Flex(
        [new Container(child: new Flex(children), height: kToolBarHeight)],
        alignItems: FlexAlignItems.flexEnd
      ),
      padding: new EdgeDims.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(
        backgroundColor: backgroundColor,
        boxShadow: shadows[2]
      )
    );
  }

}
