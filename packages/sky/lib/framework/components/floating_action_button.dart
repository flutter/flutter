// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn.dart';
import '../theme/colors.dart';
import 'ink_well.dart';
import 'material.dart';

class FloatingActionButton extends Component {
  // TODO(abarth): We need a better way to become a container for absolutely
  // positioned elements.
  static final Style _style = new Style('''
    transform: translateX(0);
    width: 56px;
    height: 56px;
    background-color: ${Red[500]};
    border-radius: 28px;'''
  );
  static final Style _clipStyle = new Style('''
    transform: translateX(0);
    position: absolute;
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    -webkit-clip-path: circle(28px at center);''');

  UINode content;
  int level;

  FloatingActionButton({ Object key, this.content, this.level: 0 })
      : super(key: key);

  UINode build() {
    List<UINode> children = [];

    if (content != null)
      children.add(content);

    return new Material(
      content: new Container(
        style: _style,
        children: [new StyleNode(new InkWell(children: children), _clipStyle)]),
      level: level);
  }
}
