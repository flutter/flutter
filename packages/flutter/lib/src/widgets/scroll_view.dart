// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'framework.dart';
import 'basic.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'viewport.dart';

/// A convenience widget that combines common scrolling-related widgets.
class ScrollView extends StatelessWidget {
  ScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.padding,
    this.initialScrollOffset: 0.0,
    this.itemExtent,
    this.shrinkWrap: false,
    this.children: const <Widget>[],
  }) : super(key: key) {
    assert(reverse != null);
    assert(initialScrollOffset != null);
    assert(shrinkWrap != null);
  }

  final Axis scrollDirection;

  final bool reverse;

  final EdgeInsets padding;

  final double initialScrollOffset;

  final double itemExtent;

  final bool shrinkWrap;

  final List<Widget> children;

  SliverChildListDelegate get childrenDelegate => new SliverChildListDelegate(children);

  @protected
  AxisDirection getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (scrollDirection) {
      case Axis.horizontal:
        return reverse ? AxisDirection.left : AxisDirection.right;
      case Axis.vertical:
        return reverse ? AxisDirection.up : AxisDirection.down;
    }
    return null;
  }

  @protected
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return new SliverList(
        delegate: childrenDelegate,
        itemExtent: itemExtent,
      );
    }
    return new SliverBlock(delegate: childrenDelegate);
  }

  @override
  Widget build(BuildContext context) {
    Widget sliver = buildChildLayout(context);
    if (padding != null)
      sliver = new SliverPadding(padding: padding, child: sliver);
    AxisDirection axisDirection = getDirection(context);
    return new Scrollable2(
      axisDirection: axisDirection,
      initialScrollOffset: initialScrollOffset,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        if (shrinkWrap) {
          return new ShrinkWrappingViewport(
            axisDirection: axisDirection,
            offset: offset,
            slivers: <Widget>[ sliver ],
          );
        } else {
          return new Viewport2(
            axisDirection: axisDirection,
            offset: offset,
            slivers: <Widget>[ sliver ],
          );
        }
      }
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$scrollDirection');
    if (padding != null)
      description.add('padding: $padding');
    if (initialScrollOffset != 0.0)
      description.add('initialScrollOffset: ${initialScrollOffset.toStringAsFixed(1)}');
    if (itemExtent != null)
      description.add('itemExtent: $itemExtent');
    if (shrinkWrap)
      description.add('shrink-wrapping');
  }
}

class ScrollGrid extends ScrollView {
  ScrollGrid({
    Key key,
    Axis scrollDirection: Axis.vertical,
    EdgeInsets padding,
    double initialScrollOffset: 0.0,
    bool shrinkWrap: false,
    this.gridDelegate,
    List<Widget> children: const <Widget>[],
  }) : super(key: key, scrollDirection: scrollDirection, padding: padding, shrinkWrap: shrinkWrap, children: children);

  ScrollGrid.count({
    Key key,
    Axis scrollDirection: Axis.vertical,
    EdgeInsets padding,
    double initialScrollOffset: 0.0,
    bool shrinkWrap: false,
    @required int crossAxisCount,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    List<Widget> children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  ), super(key: key, scrollDirection: scrollDirection, padding: padding, shrinkWrap: shrinkWrap, children: children);

  ScrollGrid.extent({
    Key key,
    Axis scrollDirection: Axis.vertical,
    EdgeInsets padding,
    double initialScrollOffset: 0.0,
    bool shrinkWrap: false,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    List<Widget> children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxCrossAxisExtent,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  ), super(key: key, scrollDirection: scrollDirection, padding: padding, shrinkWrap: shrinkWrap, children: children);

  final SliverGridDelegate gridDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return new SliverGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
    );
  }
}
