// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/colors.dart';
import 'material.dart';

class PopupMenu extends Component {
  static final Style _style = new Style('''
    border-radius: 2px;
    background-color: ${Grey[50]};'''
  );

  List<Node> children;
  int level;

  PopupMenu({ Object key, this.children, this.level }) : super(key: key);

  Node build() {
    return new Material(
      style: _style,
      children: children,
      level: level
    );
  }
}
