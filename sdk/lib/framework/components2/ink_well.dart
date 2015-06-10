// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../animation/curves.dart';
import '../fn2.dart';
import '../rendering/box.dart';
import '../rendering/flex.dart';
import '../rendering/object.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:sky' as sky;

const int _kSplashInitialOpacity = 0x80;
const double _kSplashInitialDelay = 0.0; // we could delay initially in case the user scrolls
const double _kSplashInitialSize = 0.0;
const double _kSplashConfirmedVelocity = 0.3;
const double _kSplashUnconfirmedVelocity = 0.1;

double _getSplashTargetSize(Size bounds, Point position) {
  return math.max(math.max(position.x, bounds.width - position.x),
                  math.max(position.y, bounds.height - position.y));
}

class InkSplash {
  InkSplash(this.pointer, this.position, this.well) {
    _targetRadius = _getSplashTargetSize(well.size, position);
    double duration = _targetRadius / _kSplashUnconfirmedVelocity;
    _radius = new AnimatedValue(_kSplashInitialSize, onChange: _handleRadiusChange);
    _radius.animateTo(_targetRadius, duration, curve: easeOut,
                      initialDelay: _kSplashInitialDelay);
  }

  final int pointer;
  final Point position;
  final RenderInkWell well;

  double _targetRadius;
  AnimatedValue _radius;

  void confirm() {
    double duration = (_targetRadius - _radius.value) / _kSplashConfirmedVelocity;
    if (duration <= 0.0)
      return;
    _radius.animateTo(_targetRadius, duration, curve: easeOut);
  }

  void _handleRadiusChange() {
    if (_radius.value == _targetRadius)
      well._splashes.remove(this);
    well.markNeedsPaint();
  }

  void paint(RenderObjectDisplayList canvas) {
    int opacity = (_kSplashInitialOpacity * (1.0 - (_radius.value / _targetRadius))).floor();
    sky.Paint paint = new sky.Paint()..color = new sky.Color(opacity << 24);
    canvas.drawCircle(position.x, position.y, _radius.value, paint);
  }
}

class RenderInkWell extends RenderProxyBox {
  RenderInkWell({ RenderBox child }) : super(child);

  final List<InkSplash> _splashes = new List<InkSplash>();

  void handleEvent(sky.Event event, BoxHitTestEntry entry) {
    switch (event.type) {
      case 'gesturetapdown':
        // TODO(abarth): We should position the splash at the location of the tap.
        _startSplash(event.primaryPointer, entry.localPosition);
        break;
      case 'gesturetap':
        _confirmSplash(event.primaryPointer);
        break;
    }
  }

  void _startSplash(int pointer, Point position) {
    _splashes.add(new InkSplash(pointer, position, this));
    markNeedsPaint();
  }

  void _confirmSplash(int pointer) {
    _splashes.where((splash) => splash.pointer == pointer)
             .forEach((splash) { splash.confirm(); });
    markNeedsPaint();
  }

  void paint(RenderObjectDisplayList canvas) {
    if (!_splashes.isEmpty) {
      canvas.save();
      canvas.clipRect(new Rect.fromSize(size));
      for (InkSplash splash in _splashes)
        splash.paint(canvas);
      canvas.restore();
    }
    super.paint(canvas);
  }
}

class InkWellWrapper extends OneChildRenderObjectWrapper {
  InkWellWrapper({ UINode child, Object key })
    : super(child: child, key: key);

  RenderInkWell get root { RenderInkWell result = super.root; return result; }

  RenderInkWell createNode() => new RenderInkWell();
}

class InkWell extends Component {
  InkWell({ Object key, this.children }) : super(key: key);

  final List<UINode> children;

  UINode build() {
    return new InkWellWrapper(
      child: new Flex(
        children,
        direction: FlexDirection.horizontal,
        justifyContent: FlexJustifyContent.center
      )
    );
  }
}
