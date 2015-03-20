// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'action_bar.dart';
import 'drawer.dart';
import 'floating_action_button.dart';
import 'package:sky/framework/theme/typography.dart' as typography;

class Scaffold extends Component {
  static final Style _style = new Style('''
    ${typography.typeface};
    ${typography.black.body1};''');

  static final Style _mainStyle = new Style('''
    display: flex;
    flex-direction: column;
    height: -webkit-fill-available;''');

  static final Style _contentStyle = new Style('''
    flex: 1;''');

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

  ActionBar actionBar;
  Node content;
  FloatingActionButton fab;
  Drawer drawer;
  List<Node> overlays;

  Scaffold({
    Object key,
    this.actionBar,
    this.content,
    this.fab,
    this.drawer,
    this.overlays
  }) : super(key: key);

  Node build() {
    var children = [
      new Container(
        key: 'Main',
        style: _mainStyle,
        children: [
          actionBar,
          new StyleNode(content, _contentStyle)
        ]
      ),
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
