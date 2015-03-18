// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../framework/fn.dart';
import '../../framework/components/button.dart';
import '../../framework/components/popup_menu.dart';

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
              items: [
                [new Text('People & options')],
                [new Text('New group conversation')],
                [new Text('Turn history off')],
                [new Text('Archive')],
                [new Text('Delete')],
                [new Text('Un-merge SMS')],
                [new Text('Help & feeback')],
              ],
              level: 4),
            ]
          )
        ]
      );
  }
}
