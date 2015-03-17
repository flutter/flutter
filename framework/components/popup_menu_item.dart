// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'material.dart';

class PopupMenuItem extends Component {
  static final Style _style = new Style('''
    min-width: 112px;
    padding: 16px;''');

  List<Node> children;

  PopupMenuItem({ Object key, this.children }) : super(key: key);

  Node build() {
    return new Material(
      style: _style,
      children: children
    );
  }
}
