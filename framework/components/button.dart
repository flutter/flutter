// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/shadows.dart';
import 'material.dart';

class Button extends Component {
  static final Style _style = new Style('''
    display: inline-flex;
    transform: translateX(0);
    -webkit-user-select: none;
    justify-content: center;
    align-items: center;
    height: 36px;
    min-width: 64px;
    padding: 0 8px;
    margin: 4px;
    border-radius: 2px;'''
  );

  Node content;
  int level;

  Button({ Object key, this.content, this.level }) : super(key: key);

  Node build() {
    return new Material(
      styles: [_style],
      children: [content],
      level: level
    );
  }
}
