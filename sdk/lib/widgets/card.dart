// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../theme/colors.dart' as colors;
import '../theme/edges.dart';
import 'basic.dart';
import 'material.dart';
import "theme.dart";

class Card extends Component {
  Card({ String key, this.child, this.color }) : super(key: key);

  final Widget child;
  final Color color;

  Color get materialColor {
    if (color != null)
      return color;
    switch (Theme.of(this).brightness) {
      case ThemeBrightness.light:
        return colors.White;
      case ThemeBrightness.dark:
        return colors.Grey[800];
    }
  }

  Widget build() {
    return new Container(
      margin: const EdgeDims(8.0, 8.0, 0.0, 8.0),
      child: new Material(
        color: materialColor,
        edge: MaterialEdge.card,
        level: 2,
        child: new ClipRRect(
          xRadius: edges[MaterialEdge.card],
          yRadius: edges[MaterialEdge.card],
          child: child
        )
      )
    );
  }
}
