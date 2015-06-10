// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../fn2.dart';
import '../rendering/box.dart';
import '../painting/shadows.dart';
import '../theme2/colors.dart';
import 'dart:sky' as sky;
import 'ink_well.dart';
import 'material.dart';

const double _kSize = 56.0;

class FloatingActionButton extends Component {

  FloatingActionButton({ Object key, this.content, this.level: 0 })
      : super(key: key);

  final UINode content;
  final int level;

  UINode build() {
    List<UINode> children = [];

    if (content != null)
      children.add(content);

    return new Material(
      content: new CustomPaint(
        callback: (sky.Canvas canvas) {
          const double radius = _kSize / 2.0;
          sky.Paint paint = new sky.Paint()..color = Red[500];
          var builder = new ShadowDrawLooperBuilder()
            ..addShadow(const sky.Size(0.0, 5.0),
                        const sky.Color(0x77000000),
                        5.0);
          paint.setDrawLooper(builder.build());
          canvas.drawCircle(radius, radius, radius, paint);
        },
        child: new Container(
          width: _kSize,
          height: _kSize,
          child: new InkWell(children: children))),
      level: level);
  }

}
