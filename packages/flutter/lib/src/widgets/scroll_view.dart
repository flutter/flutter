// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'framework.dart';
import 'basic.dart';
import 'scrollable.dart';
import 'sliver.dart';

AxisDirection _getDirection(BuildContext context, Axis scrollDirection) {
  // TODO(abarth): Consider reading direction.
  switch (scrollDirection) {
    case Axis.horizontal:
      return AxisDirection.right;
    case Axis.vertical:
      return AxisDirection.down;
  }
  return null;
}

class ScrollView extends StatelessWidget {
  ScrollView({
    Key key,
    this.padding,
    this.scrollDirection: Axis.vertical,
    this.initialScrollOffset: 0.0,
    this.itemExtent,
    this.children: const <Widget>[],
  }) : super(key: key);

  final EdgeInsets padding;

  final Axis scrollDirection;

  final double initialScrollOffset;

  final double itemExtent;

  final List<Widget> children;

  Widget _buildChildLayout() {
    final SliverChildListDelegate delegate = new SliverChildListDelegate(children);

    if (itemExtent != null) {
      return new SliverList(
        delegate: delegate,
        itemExtent: itemExtent,
      );
    }

    return new SliverBlock(delegate: delegate);
  }

  @override
  Widget build(BuildContext context) {
    Widget sliver = _buildChildLayout();

    if (padding != null)
      sliver = new SliverPadding(padding: padding, child: sliver);

    return new ScrollableViewport2(
      axisDirection: _getDirection(context, scrollDirection),
      initialScrollOffset: initialScrollOffset,
      slivers: <Widget>[ sliver ],
    );
  }
}

class ScrollGrid extends StatelessWidget {
  ScrollGrid({
    Key key,
    this.padding,
    this.scrollDirection: Axis.vertical,
    this.initialScrollOffset: 0.0,
    this.gridDelegate,
    this.children: const <Widget>[],
  }) : super(key: key);

  ScrollGrid.count({
    Key key,
    this.padding,
    this.scrollDirection: Axis.vertical,
    this.initialScrollOffset: 0.0,
    @required int crossAxisCount,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    this.children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  ), super(key: key);

  ScrollGrid.extent({
    Key key,
    this.padding,
    this.scrollDirection: Axis.vertical,
    this.initialScrollOffset: 0.0,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    this.children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxCrossAxisExtent,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  ), super(key: key);

  final EdgeInsets padding;

  final Axis scrollDirection;

  final double initialScrollOffset;

  final SliverGridDelegate gridDelegate;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final SliverChildListDelegate delegate = new SliverChildListDelegate(children);

    Widget sliver = new SliverGrid(
      delegate: delegate,
      gridDelegate: gridDelegate,
    );

    if (padding != null)
      sliver = new SliverPadding(padding: padding, child: sliver);

    return new ScrollableViewport2(
      axisDirection: _getDirection(context, scrollDirection),
      initialScrollOffset: initialScrollOffset,
      slivers: <Widget>[ sliver ],
    );
  }
}
