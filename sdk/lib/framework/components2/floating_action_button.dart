// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../rendering/box.dart';
import '../theme2/colors.dart';
import 'dart:sky' as sky;
import 'ink_well.dart';
import 'material.dart';

const double _kSize = 56.0;

class FloatingActionButton extends Component {
  UINode content;
  int level;

  FloatingActionButton({ Object key, this.content, this.level: 0 })
      : super(key: key);

  UINode build() {
    List<UINode> children = [];

    if (content != null)
      children.add(content);

    return new Material(
      content: new CustomPaint(
        callback: (sky.Canvas canvas) {
          const double radius = _kSize / 2.0;
          canvas.drawCircle(radius, radius, radius, new sky.Paint()..color = Red[500]);
        },
        child: new Container(
          desiredSize: const sky.Size(_kSize, _kSize),
          child: new InkWell(children: children))),
      level: level);
  }
}
