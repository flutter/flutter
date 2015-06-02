// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/node.dart';
import 'package:sky/framework/animation/animated_value.dart';
import 'package:sky/framework/animation/curves.dart';

const double _kInitialSize = 0.0;
const double _kTargetSize = 100.0;
const double _kSplashDuration = 500.0;
const int _kInitialOpacity = 0x80;

class InkSplash {
  final InkWell inkWell;
  final sky.Paint _paint = new sky.Paint();
  final sky.Point position;
  AnimatedValue radius;

  InkSplash({ this.position, this.inkWell }) {
    radius = new AnimatedValue(_kInitialSize, onChange: _handleRadiusChange);
    radius.animateTo(_kTargetSize, _kSplashDuration, curve: easeOut);
  }

  void _handleRadiusChange() {
    if (radius.value == _kTargetSize)
      inkWell._splashes.remove(this);
    inkWell.markNeedsPaint();
  }

  void paint(RenderNodeDisplayList canvas) {
    int opacity = (_kInitialOpacity * (1.0 - (radius.value / _kTargetSize))).floor();
    _paint.color = new sky.Color(opacity << 24);
    canvas.drawCircle(position.x, position.y, radius.value, _paint);
  }
}

class InkWell extends RenderBox {
  final List<InkSplash> _splashes = new List<InkSplash>();

  void handlePointer(sky.PointerEvent event) {
    switch (event.type) {
      case 'pointerdown':
        _splashes.add(new InkSplash(position: new sky.Point(event.x, event.y),
                                    inkWell: this));
        break;
    }
    markNeedsPaint();
  }

  void performLayout() {
    size = constraints.constrain(new sky.Size.infinite());
  }

  void paint(RenderNodeDisplayList canvas) {
    canvas.drawRect(new sky.Rect.fromLTRB(0.0, 0.0, size.width, size.height),
                    new sky.Paint()..color = const sky.Color(0xFFCCCCCC));
    for (InkSplash splash in _splashes)
      splash.paint(canvas);
  }
}

AppView app;

void main() {
  app = new AppView(new InkWell());
}
