// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/animation_performance.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/widgets/animated_component.dart';
import 'package:sky/widgets/animation_builder.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/theme.dart';

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
    this.level: 0,
    this.color
  }) : super(key: key) {
    assert(level != null);
  }

  Widget child;
  MaterialType type;
  int level;
  Color color;

  AnimationBuilder _builder;

  void initState() {
    _builder = new AnimationBuilder()
      ..shadow = new AnimatedType<double>(level.toDouble())
      ..backgroundColor = _getBackgroundColor(type, color)
      ..borderRadius = edges[type]
      ..shape = type == MaterialType.circle ? Shape.circle : Shape.rectangle;
    watchPerformance(_builder.createPerformance(
        [_builder.shadow], duration: _kAnimateShadowDuration));
    watchPerformance(_builder.createPerformance(
        [_builder.backgroundColor], duration: _kAnimateColorDuration));
    super.initState();
  }

  void syncFields(Material source) {
    child = source.child;
    type = source.type;
    level = source.level;
    color = source.color;
    _builder.updateFields(
      shadow: new AnimatedType<double>(level.toDouble()),
      backgroundColor: _getBackgroundColor(type, color),
      borderRadius: edges[type],
      shape: type == MaterialType.circle ? Shape.circle : Shape.rectangle
    );
    super.syncFields(source);
  }

  AnimatedColor _getBackgroundColor(MaterialType type, Color color) {
    if (color == null) {
      switch (type) {
        case MaterialType.canvas:
          color = Theme.of(this).canvasColor;
          break;
        case MaterialType.card:
          color = Theme.of(this).cardColor;
          break;
        default:
          break;
      }
    }
    return color == null ? null : new AnimatedColor(color);
  }

  Widget build() {
    return _builder.build(
        new DefaultTextStyle(style: Theme.of(this).text.body1, child: child)
    );
  }

}
