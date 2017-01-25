// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'scrollable.dart';

class ScrollView extends StatelessWidget {
  ScrollView({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.anchor: 0.0,
    this.initialScrollOffset: 0.0,
    this.scrollBehavior,
    this.center,
    this.children,
  }) : super(key: key);

  final AxisDirection axisDirection;

  final double anchor;

  final double initialScrollOffset;

  final ScrollBehavior2 scrollBehavior;

  final Key center;

  /// The widgets below this widget in the tree.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return new Scrollable2(
      axisDirection: axisDirection,
      anchor: anchor,
      initialScrollOffset: initialScrollOffset,
      scrollBehavior: scrollBehavior,
      center: center,
      children: SliverToBoxAdapter.wrapAll(children),
    );
  }
}
