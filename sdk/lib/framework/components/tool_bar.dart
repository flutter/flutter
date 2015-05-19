// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../layout.dart';
import '../theme/view_configuration.dart';
import 'material.dart';

class ToolBar extends Component {
  static final Style _style = new Style('''
    align-items: center;
    height: 56px;
    padding: 0 8px;
    transition: background-color 0.3s;
    padding-top: ${kStatusBarHeight}px;''');

  static Style _centerStyle = new Style('''
    padding-left: 24px;''');

  static FlexBoxParentData _centerLayoutSettings = new FlexBoxParentData()..flex = 1;

  UINode left;
  UINode center;
  List<UINode> right;

  ToolBar({
    String key,
    this.left,
    this.center,
    this.right
  }) : super(key: key);

  UINode build() {
    List<UINode> children = [left, new StyleNode(new ParentDataNode(center, _centerLayoutSettings), _centerStyle)];

    if (right != null)
      children.addAll(right);

    return new Material(
      content: new FlexContainer(
        style: _style,
        children: children,
        direction: FlexDirection.Row),
      level: 2);
  }
}
