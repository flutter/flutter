// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../layout2.dart';
import 'drawer.dart';
import 'floating_action_button.dart';
import '../theme/typography.dart' as typography;

class Scaffold extends Component {
  static final Style _style = new Style('''
    ${typography.typeface};
    ${typography.black.body1};''');

  static final Style _mainStyle = new Style('''
    height: -webkit-fill-available;''');

  static final FlexBoxParentData _contentParentData = new FlexBoxParentData()..flex = 1;

  static final Style _fabStyle = new Style('''
    position: absolute;
    bottom: 16px;
    right: 16px;''');

  static final Style _drawerStyle = new Style('''
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;''');

  UINode header;
  UINode content;
  FloatingActionButton fab;
  Drawer drawer;
  List<UINode> overlays;

  Scaffold({
    Object key,
    this.header,
    this.content,
    this.fab,
    this.drawer,
    this.overlays
  }) : super(key: key);

  UINode build() {
    List<UINode> children = [
      new FlexContainer(
        key: 'Main',
        direction: FlexDirection.Column,
        style: _mainStyle,
        children: [header, new ParentDataNode(content, _contentParentData)])
    ];

    if (fab != null)
      children.add(new StyleNode(fab, _fabStyle));

    if (drawer != null)
      children.add(new StyleNode(drawer, _drawerStyle));

    if (overlays != null)
      children.addAll(overlays);

    return new Container(style: _style, children: children);
  }
}
