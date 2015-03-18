// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/colors.dart';
import 'material.dart';
import 'popup_menu_item.dart';

class PopupMenu extends Component {
  static final Style _style = new Style('''
    border-radius: 2px;
    padding: 8px 0;
    background-color: ${Grey[50]};'''
  );

  List<List<Node>> items;
  int level;

  PopupMenu({ Object key, this.items, this.level }) : super(key: key);

  Node build() {
    List<Node> children = [];
    int i = 0;
    items.forEach((List<Node> item) {
      children.add(new PopupMenuItem(key: i++, children: item));
    });

    return new Material(
      style: _style,
      children: children,
      level: level
    );
  }
}
