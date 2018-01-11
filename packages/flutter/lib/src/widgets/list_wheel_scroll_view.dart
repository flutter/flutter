// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';
import 'scrollable.dart';

/// A controller for [ListWheelScrollView].
///
/// Similar to a standard [ScrollController] but with the added convenience
/// mechanisms to read and go to item indices rather than a raw pixel scroll
/// offset.
///
/// See also:
///
///  * [ListWheelScrollView], which is the widget this object controls.
///  * [FixedExtentMetrics], the `metrics` property exposed by
///    [ScrollNotification] from [ListWheelScrollView] which can be used
///    to listen to the current item index on a push basis rather than polling
///    the [ListWheelScrollController].
class ListWheelScrollController extends ScrollController {
  /// Creates a [ListWheelScrollController].
  ListWheelScrollController({
    this.initialItem: 0,
  }) : assert(initialItem != null);

  /// The page to show when first creating the [ListWheelScrollView].
  ///
  /// Defaults to 0 and must not be null.
  final int initialItem;

  /// The currently selected item index that's closest to the center of the viewport.
  ///
  /// There are circumstances that this [ListWheelScrollController] can't know
  /// the current item. Reading [selectedItem] will throw an [AssertionError] in
  /// the following cases:
  ///
  /// 1. No [ListWheelScrollView] is currently using this [ListWheelScrollController].
  /// 2. More than one [ListWheelScrollView] using the same [ListWheelScrollController].
  ///
  /// The [hasClients] property can be used to check if a [ListWheelScrollView] is
  /// attached prior to accessing [selectedItem].
  int get selectedItem {
    assert(
      positions.isNotEmpty,
      'ListWheelScrollController.selectedItem cannot be accessed before a '
      'ListWheelScrollView is built with it.',
    );
    assert(
      positions.length == 1,
      'Multiple ListWheelScrollViews cannot be attached to the same ListWheelScrollController.',
    );
    final _FixedExtentScrollPosition position = this.position;
    return position.itemIndex;
  }

  /// Animates the controlled [ListWheelScrollView] to the given item index.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  Future<Null> animateToItem(int itemIndex, {
    @required Duration duration,
    @required Curve curve,
  }) {
    final _FixedExtentScrollPosition position = this.position;
    return position.animateTo(
      itemIndex * position.itemExtent,
      duration: duration,
      curve: curve,
    );
  }

  /// Changes which item index is centered in the controlled [ListWheelScrollView].
  ///
  /// Jumps the item index position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToItem(int itemIndex) {
    final _FixedExtentScrollPosition position = this.position;
    position.jumpTo(itemIndex * position.itemExtent);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition oldPosition) {
    return new _FixedExtentScrollPosition(
      physics: physics,
      context: context,
      initialItem: initialItem,
      oldPosition: oldPosition,
    );
  }
}

/// Metrics for a [ListWheelScrollView].
///
/// The metrics are available on [ScrollNotification]s generated from
/// [ListWheelScrollView]s with a [ListWheelScrollController] and exposes the
/// current [itemIndex].
class FixedExtentMetrics extends FixedScrollMetrics {
  /// Creates page metrics that add the given information to the `parent`
  /// metrics.
  FixedExtentMetrics({
    ScrollMetrics parent,
    this.itemIndex,
  }) : super.clone(parent);

  /// The [ListWheelScrollView]'s currently selected item index.
  final int itemIndex;
}

/// A [ScrollPositionWithSingleContext] that can only be created based on
/// [_FixedExtentScrollable] and can access its `itemExtent` to derive [itemIndex].
class _FixedExtentScrollPosition extends ScrollPositionWithSingleContext {
  _FixedExtentScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    @required int initialItem,
    bool keepScrollOffset: true,
    ScrollPosition oldPosition,
    String debugLabel,
  }) : assert(
         context is _FixedExtentScrollableState,
         'ListWheelScrollController can only be used with ListWheelScrollViews'
       ),
       super(
         physics: physics,
         context: context,
         initialPixels: _getItemExtentFromScrollContext(context) * initialItem,
         keepScrollOffset: keepScrollOffset,
         oldPosition: oldPosition,
         debugLabel: debugLabel,
       );

  static double _getItemExtentFromScrollContext(ScrollContext context) {
    final _FixedExtentScrollableState scrollable = context;
    return scrollable.itemExtent;
  }

  double _clipToScrollableRange(double offset) {
    return math.min(math.max(pixels, minScrollExtent), maxScrollExtent);
  }

  double get itemExtent => _getItemExtentFromScrollContext(context);

  int get itemIndex => (_clipToScrollableRange(pixels) / itemExtent).round();

  @override
  FixedExtentMetrics cloneMetrics() {
    return new FixedExtentMetrics(
      parent: this,
      itemIndex: itemIndex,
    );
  }
}

/// A [Scrollable] which must be given its viewport children's item extent
/// size so it can pass it on ultimately to the [ListWheelScrollController].
class _FixedExtentScrollable extends Scrollable {
  const _FixedExtentScrollable({
    Key key,
    AxisDirection axisDirection: AxisDirection.down,
    ScrollController controller,
    ScrollPhysics physics,
    @required this.itemExtent,
    @required ViewportBuilder viewportBuilder,
  }) : super (
    key: key,
    axisDirection: axisDirection,
    controller: controller,
    physics: physics,
    viewportBuilder: viewportBuilder,
  );

  final double itemExtent;

  @override
  _FixedExtentScrollableState createState() => new _FixedExtentScrollableState();
}

/// This [ScrollContext] is used by [_FixedExtentScrollPosition] to read the
/// prescribed [itemExtent].
class _FixedExtentScrollableState extends ScrollableState {
  double get itemExtent {
    // Downcast because only _FixedExtentScrollable can make _FixedExtentScrollableState.
    final _FixedExtentScrollable actualWidget = widget;
    return actualWidget.itemExtent;
  }
}

/// A box in which children on a wheel can be scrolled.
///
/// This widget is similar to a [ListView] but with the restriction that all
/// children must be the same size along the scrolling axis.
///
/// When the list is at the zero scroll offset, the first child is aligned with
/// the middle of the viewport. When the list is at the final scroll offset,
/// the last child is aligned with the middle of the viewport
///
/// The children are rendered as if rotating on a wheel instead of scrolling on
/// a plane.
class ListWheelScrollView extends StatefulWidget {
  /// Creates a box in which children are scrolled on a wheel.
  ListWheelScrollView({
    Key key,
    ScrollController controller,
    this.physics,
    this.diameterRatio: RenderListWheelViewport.defaultDiameterRatio,
    this.perspective: RenderListWheelViewport.defaultPerspective,
    @required this.itemExtent,
    this.onSelectedItemChanged,
    this.clipToSize: true,
    this.renderChildrenOutsideViewport: false,
    @required this.children,
  }) : assert(diameterRatio != null),
       assert(diameterRatio > 0.0, RenderListWheelViewport.diameterRatioZeroMessage),
       assert(perspective != null),
       assert(perspective > 0),
       assert(perspective <= 0.01, RenderListWheelViewport.perspectiveTooHighMessage),
       assert(itemExtent != null),
       assert(itemExtent > 0),
       assert(clipToSize != null),
       assert(renderChildrenOutsideViewport != null),
       assert(
         !renderChildrenOutsideViewport || !clipToSize,
         RenderListWheelViewport.clipToSizeAndRenderChildrenOutsideViewportConflict,
       ),
       controller = controller ?? new ListWheelScrollController(),
       super(key: key);

  /// Typically a [ListWheelScrollController] used to control the current item.
  ///
  /// A [ListWheelScrollController] can be used to read the currently
  /// selected/centered child item and can be used to change the current item.
  ///
  /// If none is provided, a new [ListWheelScrollController] is implicitly
  /// created.
  ///
  /// If a [ScrollController] is used instead of [ListWheelScrollController],
  /// [ScrollNotification.metrics] will no longer provide [FixedExtentMetrics]
  /// to indicate the current item index and [onSelectedItemChanged] will not
  /// work.
  ///
  /// To read the current selected item only when the value changes, use
  /// [onSelectedItemChanged].
  final ScrollController controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// {@macro flutter.rendering.wheelList.diameterRatio}
  final double diameterRatio;

  /// {@macro flutter.rendering.wheelList.perspective}
  final double perspective;

  /// Size of each child in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;

  /// On optional listener that's called when the centered item changes.
  final ValueChanged<int> onSelectedItemChanged;

  /// {@macro flutter.rendering.wheelList.clipToSize}
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.renderChildrenOutsideViewport}
  final bool renderChildrenOutsideViewport;

  /// List of children to scroll on top of the cylinder.
  final List<Widget> children;

  @override
  _ListWheelScrollViewState createState() => new _ListWheelScrollViewState();
}

class _ListWheelScrollViewState extends State<ListWheelScrollView> {
  int _lastReportedItemIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.controller is ListWheelScrollController) {
      final ListWheelScrollController controller = widget.controller;
      _lastReportedItemIndex = controller.initialItem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0
            && widget.onSelectedItemChanged != null
            && notification is ScrollUpdateNotification
            && notification.metrics is FixedExtentMetrics) {
          final FixedExtentMetrics metrics = notification.metrics;
          final int currentItemIndex = metrics.itemIndex;
          if (currentItemIndex != _lastReportedItemIndex) {
            _lastReportedItemIndex = currentItemIndex;
            widget.onSelectedItemChanged(currentItemIndex);
          }
        }
        return false;
      },
      child: new _FixedExtentScrollable(
        controller: widget.controller,
        physics: widget.physics,
        itemExtent: widget.itemExtent,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return new ListWheelViewport(
            diameterRatio: widget.diameterRatio,
            perspective: widget.perspective,
            itemExtent: widget.itemExtent,
            clipToSize: widget.clipToSize,
            renderChildrenOutsideViewport: widget.renderChildrenOutsideViewport,
            offset: offset,
            children: widget.children,
          );
        },
      ),
    );
  }
}

/// A viewport showing a subset of children on a wheel.
///
/// Typically used with [ListWheelScrollView], this viewport is similar to
/// [Viewport] in that it shows a subset of children in a scrollable based
/// on the scrolling offset and the childrens' dimensions. But uses
/// [RenderListWheelViewport] to display the children on a wheel.
///
/// See also:
///
///  * [ListWheelScrollView], widget that combines this viewport with a scrollable.
///  * [RenderListWheelViewport], the render object that renders the children
///    on a wheel.
class ListWheelViewport extends MultiChildRenderObjectWidget {
  ListWheelViewport({
    Key key,
    this.diameterRatio: RenderListWheelViewport.defaultDiameterRatio,
    this.perspective: RenderListWheelViewport.defaultPerspective,
    @required this.itemExtent,
    this.clipToSize: true,
    this.renderChildrenOutsideViewport: false,
    @required this.offset,
    List<Widget> children,
  }) : assert(offset != null),
       assert(diameterRatio != null),
       assert(diameterRatio > 0, RenderListWheelViewport.diameterRatioZeroMessage),
       assert(perspective != null),
       assert(perspective > 0),
       assert(perspective <= 0.01, RenderListWheelViewport.perspectiveTooHighMessage),
       assert(itemExtent != null),
       assert(itemExtent > 0),
       assert(clipToSize != null),
       assert(renderChildrenOutsideViewport != null),
       assert(
         !renderChildrenOutsideViewport || !clipToSize,
         RenderListWheelViewport.clipToSizeAndRenderChildrenOutsideViewportConflict,
       ),
       super(key: key, children: children);

  /// {@macro flutter.rendering.wheelList.diameterRatio}
  final double diameterRatio;

  /// {@macro flutter.rendering.wheelList.perspective}
  final double perspective;

  /// {@macro flutter.rendering.wheelList.itemExtent}
  final double itemExtent;

  /// {@macro flutter.rendering.wheelList.clipToSize}
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.renderChildrenOutsideViewport}
  final bool renderChildrenOutsideViewport;

  /// [ViewportOffset] object describing the content that should be visible
  /// in the viewport.
  final ViewportOffset offset;

  @override
  RenderListWheelViewport createRenderObject(BuildContext context) {
    return new RenderListWheelViewport(
      diameterRatio: diameterRatio,
      perspective: perspective,
      itemExtent: itemExtent,
      clipToSize: clipToSize,
      renderChildrenOutsideViewport: renderChildrenOutsideViewport,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderListWheelViewport renderObject) {
    renderObject
      ..diameterRatio = diameterRatio
      ..perspective = perspective
      ..itemExtent = itemExtent
      ..clipToSize = clipToSize
      ..renderChildrenOutsideViewport = renderChildrenOutsideViewport
      ..offset = offset;
  }
}
