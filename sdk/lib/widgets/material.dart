// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../painting/box_painter.dart';
import '../theme/colors.dart';
import '../theme/edges.dart';
import '../theme/shadows.dart';
import 'basic.dart';

class Material extends Component {

  Material({
    String key,
    this.child,
    this.edge: MaterialEdge.card,
    this.level: 0,
    this.color
  }) : super(key: key);

  final Widget child;
  final int level;
  final MaterialEdge edge;
  final Color color;

  // TODO(ianh): we should make this animate level changes and color changes

  Widget build() {
    return new Container(
      decoration: new BoxDecoration(
        boxShadow: shadows[level],
        borderRadius: edges[edge],
        backgroundColor: color == null ? Grey[50] : color,
        shape: edge == MaterialEdge.circle ? Shape.circle : Shape.rectangle
      ),
      child: child
    );
  }

}
