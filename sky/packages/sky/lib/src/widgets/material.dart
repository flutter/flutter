// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting.dart';
import 'package:sky/material.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/theme.dart';

enum MaterialType { canvas, card, circle, button }

const Map<MaterialType, double> edges = const {
  MaterialType.canvas: null,
  MaterialType.card: 2.0,
  MaterialType.circle: null,
  MaterialType.button: 2.0,
};

class Material extends StatelessComponent {
  Material({
    Key key,
    this.child,
    this.type: MaterialType.card,
    this.level: 0,
    this.color
  }) : super(key: key) {
    assert(level != null);
  }

  final Widget child;
  final MaterialType type;
  final int level;
  final Color color;

  Color getBackgroundColor(BuildContext context) {
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
        style: Theme.of(context).text.body1,
        child: contents
      );
      if (edges[type] != null) {
        contents = new ClipRRect(
          xRadius: edges[type],
          yRadius: edges[type],
          child: contents
        );
      }
    }
    // TODO(abarth): This should use AnimatedContainer.
    return new DefaultTextStyle(
      style: Theme.of(context).text.body1,
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: getBackgroundColor(context),
          borderRadius: edges[type],
          boxShadow: level == 0 ? null : shadows[level],
          shape: type == MaterialType.circle ? Shape.circle : Shape.rectangle
        ),
        child: contents
      )
    );
  }
}
