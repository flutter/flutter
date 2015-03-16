// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'material.dart';
import '../theme/colors.dart';

class FloatingActionButton extends Component {
  static final Style _style = new Style('''
    position: absolute;
    bottom: 16px;
    right: 16px;
    transform: translateX(0);
    width: 56px;
    height: 56px;
    background-color: ${Red[500]};
    color: white;
    border-radius: 28px;'''
  );
  static final Style _clipStyle = new Style('''
    transform: translateX(0);
    position: absolute;
    display: flex;
    justify-content: center;
    align-items: center;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    -webkit-clip-path: circle(28px at center);''');

  Node content;
  int level;

  FloatingActionButton({ Object key, this.content, this.level: 0 })
      : super(key: key);

  Node build() {
    List<Node> children = [];

    if (content != null)
      children.add(content);

    return new Container(
      key: "Container",
      style: level > 0 ? _style.extend(Material.shadowStyle[level]) : _style,
      children: [
        new Material(
          key: "Clip",
          style: _clipStyle,
          children: children
        )
      ]
    );
  }
}
