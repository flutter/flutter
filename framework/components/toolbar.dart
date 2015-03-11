// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';

class Toolbar extends Component {
  List<Node> children;

  static final Style _style = new Style('''
    display: flex;
    align-items: center;
    height: 56px;
    z-index: 1;
    background-color: ${Purple[500]};
    color: white;
    box-shadow: ${Shadow[2]};'''
  );

  Toolbar({String key, this.children}) : super(key: key);

  Node build() {
    return new Container(
      styles: [_style],
      children: children
    );
  }
}
