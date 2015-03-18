// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/view-configuration.dart';

class ActionBar extends Component {
  List<Node> children;

  static final Style _style = new Style('''
    display: flex;
    align-items: center;
    height: 56px;
    padding: 0 8px;
    background-color: ${Purple[500]};
    padding-top: ${kStatusBarHeight}px;
    box-shadow: ${Shadow[2]};'''
  );

  ActionBar({String key, this.children}) : super(key: key);

  Node build() {
    return new Container(
      style: _style,
      children: children
    );
  }
}
