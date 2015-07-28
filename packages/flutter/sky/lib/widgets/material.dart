// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/box_painter.dart';
import 'package:sky/theme/shadows.dart';
import 'package:sky/widgets/animated_container.dart';
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

class Material extends Component {
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

  Color get _backgroundColor {
    if (color != null)
      return color;
    switch (type) {
      case MaterialType.canvas:
        return Theme.of(this).canvasColor;
      case MaterialType.card:
        return Theme.of(this).cardColor;
      default:
        return null;
    }
  }

  Widget build() {
    return new AnimatedContainer(
      intentions: implicitlySyncFieldsIntention(const Duration(milliseconds: 200)),
      decoration: new BoxDecoration(
        backgroundColor: _backgroundColor,
        borderRadius: edges[type],
        boxShadow: level == 0 ? null : shadows[level],
        shape: type == MaterialType.circle ? Shape.circle : Shape.rectangle
      ),
      child: new DefaultTextStyle(
        style: Theme.of(this).text.body1,
        child: child
      )
    );
  }
}
