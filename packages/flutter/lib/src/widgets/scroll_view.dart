// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'basic.dart';
import 'scrollable.dart';
import 'sliver.dart';

class ScrollView extends StatelessWidget {
  ScrollView({
    Key key,
    this.padding,
    this.scrollDirection: Axis.vertical,
    this.anchor: 0.0,
    this.initialScrollOffset: 0.0,
    this.itemExtent,
    this.center,
    this.children,
  }) : super(key: key);

  final EdgeInsets padding;

  final Axis scrollDirection;

  final double anchor;

  final double initialScrollOffset;

  final double itemExtent;

  final Key center;

  final List<Widget> children;

  AxisDirection _getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (scrollDirection) {
      case Axis.horizontal:
        return AxisDirection.right;
      case Axis.vertical:
        return AxisDirection.down;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SliverChildListDelegate delegate = new SliverChildListDelegate(children);

    Widget sliver;

    if (itemExtent == null) {
      sliver = new SliverBlock(delegate: delegate);
    } else {
      sliver = new SliverList(
        delegate: delegate,
        itemExtent: itemExtent,
      );
    }

    if (padding != null)
      sliver = new SliverPadding(padding: padding, child: sliver);

    return new ScrollableViewport2(
      axisDirection: _getDirection(context),
      anchor: anchor,
      initialScrollOffset: initialScrollOffset,
      center: center,
      slivers: <Widget>[ sliver ],
    );
  }
}
