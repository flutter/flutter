// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import 'material.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';

class FloatingActionButton extends Material {
  static final Style _style = new Style('''
    position: absolute;
    bottom: 16px;
    right: 16px;
    z-index: 5;
    transform: translateX(0);
    width: 56px;
    height: 56px;
    background-color: ${Red[500]};
    color: white;
    box-shadow: ${Shadow[3]};
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

  FloatingActionButton({ Object key, this.content }) : super(key: key);

  Node build() {
    List<Node> children = [super.build()];

    if (content != null)
      children.add(content);

    return new Container(
      key: "Container",
      style: _style,
      children: [
        new Container(
          key: "Clip",
          style: _clipStyle,
          children: children
        )
      ]
    );
  }
}
