// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'shadows.dart';
import 'theme.dart';

enum MaterialType { canvas, card, circle, button }

const Map<MaterialType, double> _kEdges = const <MaterialType, double>{
  MaterialType.canvas: null,
  MaterialType.card: 2.0,
  MaterialType.circle: null,
  MaterialType.button: 2.0,
};

class Material extends StatelessComponent {
  Material({
    Key key,
    this.child,
    this.type: MaterialType.canvas,
    this.elevation: 0,
    this.color,
    this.textStyle
  }) : super(key: key) {
    assert(elevation != null);
  }

  final Widget child;
  final MaterialType type;
  final int elevation;
  final Color color;
  final TextStyle textStyle;

  Color _getBackgroundColor(BuildContext context) {
    if (color != null)
      return color;
    switch (type) {
      case MaterialType.canvas:
        return Theme.of(context).canvasColor;
      case MaterialType.card:
        return Theme.of(context).cardColor;
      default:
        return null;
    }
  }

  Widget build(BuildContext context) {
    Widget contents = child;
    if (child != null) {
      contents = new DefaultTextStyle(
        style: textStyle ?? Theme.of(context).text.body1,
        child: contents
      );
      if (_kEdges[type] != null) {
        contents = new ClipRRect(
          xRadius: _kEdges[type],
          yRadius: _kEdges[type],
          child: contents
        );
      }
    }
    return new DefaultTextStyle(
      style: Theme.of(context).text.body1,
      child: new AnimatedContainer(
        curve: Curves.ease,
        duration: kThemeChangeDuration,
        decoration: new BoxDecoration(
          backgroundColor: _getBackgroundColor(context),
          borderRadius: _kEdges[type],
          boxShadow: elevation == 0 ? null : elevationToShadow[elevation],
          shape: type == MaterialType.circle ? Shape.circle : Shape.rectangle
        ),
        child: contents
      )
    );
  }
}
