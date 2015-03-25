// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/shadows.dart';
import 'ink_well.dart';

class Material extends Component {
  static final List<Style> shadowStyle = [
    null,
    new Style('box-shadow: ${Shadow[1]}'),
    new Style('box-shadow: ${Shadow[2]}'),
    new Style('box-shadow: ${Shadow[3]}'),
    new Style('box-shadow: ${Shadow[4]}'),
    new Style('box-shadow: ${Shadow[5]}'),
  ];

  String inlineStyle;
  List<Node> children;
  int level;

  Material({
    Object key,
    this.inlineStyle,
    this.children,
    this.level: 0
  }) : super(key: key);

  Node build() {
    return new StyleNode(
      new InkWell(inlineStyle: inlineStyle, children: children),
      shadowStyle[level]);
  }
}
