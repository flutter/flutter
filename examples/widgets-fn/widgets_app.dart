// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/fn.dart';
import '../../framework/components/button.dart';
import '../../framework/components/popup_menu.dart';
import '../../framework/components/popup_menu_item.dart';

class WidgetsApp extends App {
  static final Style _menuStyle = new Style('''
    position: absolute;
    top: 200px;
    left: 200px;''');

  Node build() {
    return new Container(
      children: [
        new Button(key: 'Go', content: new Text('Go'), level: 1),
        new Button(key: 'Back', content: new Text('Back'), level: 3),
        new Container(
          style: _menuStyle,
          children: [
            new PopupMenu(
              children: [
                  new PopupMenuItem(key: '1', children: [new Text('People & options')]),
                  new PopupMenuItem(key: '2', children: [new Text('New group conversation')]),
                  new PopupMenuItem(key: '3', children: [new Text('Turn history off')]),
                  new PopupMenuItem(key: '4', children: [new Text('Archive')]),
                  new PopupMenuItem(key: '5', children: [new Text('Delete')]),
                  new PopupMenuItem(key: '6', children: [new Text('Un-merge SMS')]),
                  new PopupMenuItem(key: '7', children: [new Text('Help & feeback')]),
              ],
              level: 4),
            ]
          )
        ]
      );
  }
}
