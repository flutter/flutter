// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'ink_well.dart';
import 'material.dart';
import 'wrappers.dart';

class Button extends Component {

  Button({ Object key, this.content, this.level }) : super(key: key);

  static final Style _style = new Style('''
    -webkit-user-select: none;
    height: 36px;
    min-width: 64px;
    padding: 0 8px;
    margin: 4px;
    border-radius: 2px;'''
  );

  final UINode content;
  final int level;

  UINode build() {
    return new StyleNode(
      new Material(
        content: new InkWell(children: [content]),
        level: level),
      _style);
  }

}
