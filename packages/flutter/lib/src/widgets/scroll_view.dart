// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'framework.dart';
import 'basic.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'viewport.dart';

abstract class ScrollView extends StatelessWidget {
  ScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.physics,
    this.shrinkWrap: false,
  }) : super(key: key) {
    assert(reverse != null);
    assert(shrinkWrap != null);
  }

  final Axis scrollDirection;

  final bool reverse;

  final ScrollPhysics physics;

  final bool shrinkWrap;

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
  List<Widget> buildSlivers(BuildContext context);

  @override
  Widget build(BuildContext context) {
    List<Widget> slivers = buildSlivers(context);
    AxisDirection axisDirection = getDirection(context);
    return new Scrollable2(
      axisDirection: axisDirection,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        if (shrinkWrap) {
          return new ShrinkWrappingViewport(
            axisDirection: axisDirection,
            offset: offset,
            slivers: slivers,
          );
        } else {
          return new Viewport2(
            axisDirection: axisDirection,
            offset: offset,
            slivers: slivers,
          );
        }
      }
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$scrollDirection');
    if (shrinkWrap)
      description.add('shrink-wrapping');
  }
}

class CustomScrollView extends ScrollView {
  CustomScrollView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    this.slivers: const <Widget>[],
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
  );

  final List<Widget> slivers;

  @override
  List<Widget> buildSlivers(BuildContext context) => slivers;
}

abstract class BoxScrollView extends ScrollView {
  BoxScrollView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    this.padding,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
  );

  final EdgeInsets padding;

  @override
  List<Widget> buildSlivers(BuildContext context) {
    Widget sliver = buildChildLayout(context);
    if (padding != null)
      sliver = new SliverPadding(padding: padding, child: sliver);
    return <Widget>[ sliver ];
  }

  @protected
  Widget buildChildLayout(BuildContext context);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (padding != null)
      description.add('padding: $padding');
  }
}

/// A scrollable list of boxes.
// TODO(ianh): More documentation here.
///
/// See also:
///
/// * [SingleChildScrollView], when you need to make a single child scrollable.
/// * [GridView], for a scrollable grid of boxes.
/// * [PageView], for a scrollable that works page by page.
class ListView extends BoxScrollView {
  ListView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.itemExtent,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  ListView.builder({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.itemExtent,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
  }) : childrenDelegate = new SliverChildBuilderDelegate(itemBuilder, childCount: itemCount), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  ListView.custom({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.itemExtent,
    @required this.childrenDelegate,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(childrenDelegate != null);
  }

  final double itemExtent;

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return new SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: itemExtent,
      );
    }
    return new SliverList(delegate: childrenDelegate);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (itemExtent != null)
      description.add('itemExtent: $itemExtent');
  }
}

/// A scrollable grid of boxes.
// TODO(ianh): More documentation here.
///
/// See also:
///
/// * [SingleChildScrollView], when you need to make a single child scrollable.
/// * [ListView], for a scrollable list of boxes.
/// * [PageView], for a scrollable that works page by page.
class GridView extends BoxScrollView {
  GridView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required this.gridDelegate,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(gridDelegate != null);
  }

  GridView.custom({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required this.gridDelegate,
    @required this.childrenDelegate,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(gridDelegate != null);
    assert(childrenDelegate != null);
  }

  GridView.count({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
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
       ),
       childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  GridView.extent({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
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
       ),
       childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  final SliverGridDelegate gridDelegate;

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return new SliverGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
    );
  }
}

/// A scrollable list that works page by page.
// TODO(ianh): More documentation here.
///
/// See also:
///
/// * [SingleChildScrollView], when you need to make a single child scrollable.
/// * [ListView], for a scrollable list of boxes.
/// * [GridView], for a scrollable grid of boxes.
class PageView extends BoxScrollView {
  PageView({
    Key key,
    Axis scrollDirection: Axis.horizontal,
    bool reverse: false,
    ScrollPhysics physics: const PageScrollPhysics(),
    bool shrinkWrap: false,
    EdgeInsets padding,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  PageView.custom({
    Key key,
    Axis scrollDirection: Axis.horizontal,
    bool reverse: false,
    ScrollPhysics physics: const PageScrollPhysics(),
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required this.childrenDelegate,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(childrenDelegate != null);
  }

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return new SliverFill(delegate: childrenDelegate);
  }
}
