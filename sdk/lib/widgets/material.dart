// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../animation/animated_value.dart';
import '../animation/animation_performance.dart';
import '../painting/box_painter.dart';
import '../theme/shadows.dart';
import 'animated_component.dart';
import 'animated_container.dart';
import 'basic.dart';
import 'default_text_style.dart';
import 'theme.dart';

enum MaterialType { canvas, card, circle, button }

const Map<MaterialType, double> edges = const {
  MaterialType.canvas: null,
  MaterialType.card: 2.0,
  MaterialType.circle: null,
  MaterialType.button: 2.0,
};

const Duration _kAnimateShadowDuration = const Duration(milliseconds: 100);
const Duration _kAnimateColorDuration = const Duration(milliseconds: 100);

class Material extends AnimatedComponent {

  Material({
    String key,
    this.child,
    this.type: MaterialType.card,
    int level: 0,
    Color color: null
  }) : super(key: key) {
    if (level == null) level = 0;
    _container = new AnimatedContainer()
      ..shadow = new AnimatedType<double>(level.toDouble())
      ..backgroundColor = new AnimatedColor(_getBackgroundColor(color));
    watch(_container.createPerformance(
        _container.shadow, duration: _kAnimateShadowDuration).timeline);
    watch(_container.createPerformance(
        _container.backgroundColor, duration: _kAnimateColorDuration).timeline);
  }

  Widget child;
  MaterialType type;

  AnimatedContainer _container;

  void syncFields(Material source) {
    child = source.child;
    type = source.type;
    _container.syncFields(source._container);
    super.syncFields(source);
  }

  Color _getBackgroundColor(Color color) {
    if (color != null)
      return color;
    switch(type) {
      case MaterialType.canvas:
        return Theme.of(this).canvasColor;
      case MaterialType.card:
        return Theme.of(this).cardColor;
      default:
        return null;
    }
  }

  Widget build() {
    return _container.build(
      new Container(
        // TODO(mpcomplete): move the rest of this decoration into
        // AnimatedContainer as non-animated values.
        decoration: new BoxDecoration(
          borderRadius: edges[type],
          shape: type == MaterialType.circle ? Shape.circle : Shape.rectangle
        ),
        child: new DefaultTextStyle(style: Theme.of(this).text.body1, child: child)
    ));
  }

}
