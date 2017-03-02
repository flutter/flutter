// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_controller.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_view.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'viewport.dart';

class PageController extends ScrollController {
  PageController({
    this.initialPage: 0,
    ScrollLeader leader,
  }) : super(leader: leader) {
    assert(initialPage != null);
  }

  final int initialPage;

  double get page {
    final _PagePosition position = this.position;
    return position.page;
  }

  Future<Null> animateToPage(int page, {
    @required Duration duration,
    @required Curve curve,
  }) {
    final ScrollPosition position = this.position;
    return position.animateTo(page * position.viewportDimension, duration: duration, curve: curve);
  }

  void jumpToPage(int page) {
    final ScrollPosition position = this.position;
    position.jumpTo(page * position.viewportDimension);
  }

  void nextPage({ @required Duration duration, @required Curve curve }) {
    animateToPage(page.round() + 1, duration: duration, curve: curve);
  }

  void previousPage({ @required Duration duration, @required Curve curve }) {
    animateToPage(page.round() - 1, duration: duration, curve: curve);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, AbstractScrollState state, ScrollPosition oldPosition) {
    return new _PagePosition(
      physics: physics,
      state: state,
      initialPage: initialPage,
      oldPosition: oldPosition,
      leader: leader,
    );
  }
}

class _PagePosition extends ScrollPosition {
  _PagePosition({
    ScrollPhysics physics,
    AbstractScrollState state,
    this.initialPage: 0,
    ScrollPosition oldPosition,
    ScrollLeader leader,
  }) : super(
    physics: physics,
    state: state,
    initialPixels: null,
    oldPosition: oldPosition,
    leader: leader,
  ) {
    assert(initialPage != null);
  }

  final int initialPage;

  double get page => pixels / viewportDimension;

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double oldViewportDimensions = this.viewportDimension;
    final bool result = super.applyViewportDimension(viewportDimension);
    final double oldPixels = pixels;
    final double page = (oldPixels == null || oldViewportDimensions == 0.0) ? initialPage.toDouble() : oldPixels / oldViewportDimensions;
    final double newPixels = page * viewportDimension;
    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }
}

// Having this global (mutable) page controller is a bit of a hack. We need it
// to plumb in the factory for _PagePosition, but it will end up accumulating
// a large list of scroll positions. As long as you don't try to actually
// control the scroll positions, everything should be fine.
final PageController _defaultPageController = new PageController();

/// A scrollable list that works page by page.
// TODO(ianh): More documentation here.
///
/// See also:
///
/// * [SingleChildScrollView], when you need to make a single child scrollable.
/// * [ListView], for a scrollable list of boxes.
/// * [GridView], for a scrollable grid of boxes.
class PageView extends StatefulWidget {
  PageView({
    Key key,
    this.scrollDirection: Axis.horizontal,
    this.reverse: false,
    PageController controller,
    this.physics: const PageScrollPhysics(),
    this.onPageChanged,
    List<Widget> children: const <Widget>[],
  }) : controller = controller ?? _defaultPageController,
       childrenDelegate = new SliverChildListDelegate(children),
       super(key: key);

  PageView.builder({
    Key key,
    this.scrollDirection: Axis.horizontal,
    this.reverse: false,
    PageController controller,
    this.physics: const PageScrollPhysics(),
    this.onPageChanged,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
  }) : controller = controller ?? _defaultPageController,
       childrenDelegate = new SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
       super(key: key);

  PageView.custom({
    Key key,
    this.scrollDirection: Axis.horizontal,
    this.reverse: false,
    PageController controller,
    this.physics: const PageScrollPhysics(),
    this.onPageChanged,
    @required this.childrenDelegate,
  }) : controller = controller ?? _defaultPageController, super(key: key) {
    assert(childrenDelegate != null);
  }

  final Axis scrollDirection;

  final bool reverse;

  final PageController controller;

  final ScrollPhysics physics;

  final ValueChanged<int> onPageChanged;

  final SliverChildDelegate childrenDelegate;

  @override
  _PageViewState createState() => new _PageViewState();
}

class _PageViewState extends State<PageView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = config.controller.initialPage;
  }

  AxisDirection _getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (config.scrollDirection) {
      case Axis.horizontal:
        return config.reverse ? AxisDirection.left : AxisDirection.right;
      case Axis.vertical:
        return config.reverse ? AxisDirection.up : AxisDirection.down;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    AxisDirection axisDirection = _getDirection(context);
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 && config.onPageChanged != null && notification is ScrollUpdateNotification) {
          final ScrollMetrics metrics = notification.metrics;
          final int currentPage = (metrics.extentBefore / metrics.viewportDimension).round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            config.onPageChanged(currentPage);
          }
        }
        return false;
      },
      child: new Scrollable(
        axisDirection: axisDirection,
        controller: config.controller,
        physics: config.physics,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return new Viewport(
            axisDirection: axisDirection,
            offset: offset,
            slivers: <Widget>[
              new SliverFill(delegate: config.childrenDelegate),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${config.scrollDirection}');
    if (config.reverse)
      description.add('reversed');
    description.add('${config.controller}');
    description.add('${config.physics}');
  }
}
