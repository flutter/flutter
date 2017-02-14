// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_controller.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_view.dart';
import 'sliver.dart';

class PageController extends ScrollController {
  PageController({
    this.initialPage: 0,
  }) {
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
    );
  }
}

class _PagePosition extends ScrollPosition {
  _PagePosition({
    ScrollPhysics physics,
    AbstractScrollState state,
    this.initialPage: 0,
    ScrollPosition oldPosition,
  }) : super(
    physics: physics,
    state: state,
    initialPixels: null,
    oldPosition: oldPosition,
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
    final double page = oldPixels == null ? initialPage.toDouble() : oldPixels / oldViewportDimensions;
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
class PageView extends BoxScrollView {
  PageView({
    Key key,
    Axis scrollDirection: Axis.horizontal,
    bool reverse: false,
    PageController controller,
    ScrollPhysics physics: const PageScrollPhysics(),
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.onPageChanged,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller ?? _defaultPageController,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  PageView.builder({
    Key key,
    Axis scrollDirection: Axis.horizontal,
    bool reverse: false,
    PageController controller,
    ScrollPhysics physics: const PageScrollPhysics(),
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.onPageChanged,
    IndexedWidgetBuilder itemBuilder,
    int itemCount,
  }) : childrenDelegate = new SliverChildBuilderDelegate(itemBuilder, childCount: itemCount), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller ?? _defaultPageController,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  PageView.custom({
    Key key,
    Axis scrollDirection: Axis.horizontal,
    bool reverse: false,
    PageController controller,
    ScrollPhysics physics: const PageScrollPhysics(),
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.onPageChanged,
    @required this.childrenDelegate,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller ?? _defaultPageController,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(childrenDelegate != null);
  }

  final ValueChanged<int> onPageChanged;

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return new SliverFill(delegate: childrenDelegate);
  }

  @override
  Widget build(BuildContext context) {
    final Widget scrollable = super.build(context);
    return new NotificationListener<ScrollNotification2>(
      onNotification: (ScrollNotification2 notification) {
        if (notification.depth == 1 && onPageChanged != null && notification is ScrollEndNotification) {
          final ScrollMetrics metrics = notification.metrics;
          onPageChanged(metrics.extentBefore ~/ metrics.viewportDimension);
        }
        return false;
      },
      child: scrollable,
    );
  }
}
