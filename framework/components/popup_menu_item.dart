// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'animated_component.dart';
import '../animation/animated_value.dart';
import '../fn.dart';
import 'ink_well.dart';

class PopupMenuItem extends Component {
  static final Style _style = new Style('''
    min-width: 112px;
    padding: 16px;''');

  List<Node> children;
  double opacity;

  PopupMenuItem({ Object key, this.children, this.opacity}) : super(key: key);

  Node build() {
    return new StyleNode(
      new InkWell(
        inlineStyle: opacity == null ? null : 'opacity: ${opacity}',
        children: children
      ),
      _style);
  }
}
