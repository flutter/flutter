// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/shadows.dart';
import '../theme/view-configuration.dart';

class ActionBar extends Component {
  static final Style _style = new Style('''
    display: flex;
    align-items: center;
    height: 56px;
    padding: 0 8px;
    transition: background-color 0.3s;
    padding-top: ${kStatusBarHeight}px;
    box-shadow: ${Shadow[2]};''');

  static Style _centerStyle = new Style('''
    padding-left: 24px;
    flex: 1;''');

  Node left;
  Node center;
  List<Node> right;

  ActionBar({
    String key,
    this.left,
    this.center,
    this.right
  }) : super(key: key);

  Node build() {
    List<Node> children = [left, new StyleNode(center, _centerStyle)];

    if (right != null)
      children.addAll(right);

    return new Container(style: _style, children: children);
  }
}
