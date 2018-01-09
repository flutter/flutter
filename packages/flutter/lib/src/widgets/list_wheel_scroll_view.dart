// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';

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
class ListWheelScrollView extends StatelessWidget {
  /// Creates a box in which children are scrolled on a wheel.
  const ListWheelScrollView({
    Key key,
    this.controller,
    this.physics,
    this.diameterRatio: 2.0,
    this.perspective: 0.003,
    @required this.itemExtent,
    this.clipToSize: true,
    this.renderChildrenOutsideViewport: false,
    @required this.children,
  }) : assert(diameterRatio != null && diameterRatio > 0.0),
       assert(
         perspective != null && perspective >= 0.0 && perspective < 0.01,
         'A perspective too high will be clipped in the z-axis and therefore '
         'not renderable. Value must be between 0 and 0.01.'
       ),
       assert(itemExtent != null && itemExtent > 0.0),
       assert(clipToSize != null),
       assert(renderChildrenOutsideViewport != null),
       assert(
         !renderChildrenOutsideViewport || !clipToSize,
         'Cannot renderChildrenOutsideViewport and clipToSize since children '
         'rendered outside will be clipped anyway.'
       ),
       super(key: key);

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// {@macro flutter.rendering.wheelList.diameterRatio}
  ///
  /// Defaults to an arbitrary but aesthetically reasonable number of 2.0.
  ///
  /// Must not be null and must be positive.
  final double diameterRatio;

  /// {@macro flutter.rendering.wheelList.perspective}
  ///
  /// Defaults to an arbitrary but aesthetically reasonable number of 0.003.
  /// A larger number brings the vanishing point closer and a smaller number
  /// pushes the vanishing point further.
  final double perspective;

  /// Size of all children in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;

  /// Whether to clip painted children to the inside of this scroll view.
  ///
  /// Defaults to [true]. Must not be null.
  ///
  /// If this is false and [renderChildrenOutsideViewport] is false, the
  /// first and last children may be painted partly outside of this scroll view.
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.diameterRatio}
  ///
  /// Defaults to [false]. Must not be null. Cannot be true if [clipToSize]
  /// is also true since children outside the viewport will be clipped, and
  /// therefore cannot render children outside the viewport.
  final bool renderChildrenOutsideViewport;

  /// List of children to scroll on top of the cylinder.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return new Scrollable(
      controller: controller,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return new ListWheelViewport(
          diameterRatio: diameterRatio,
          perspective: perspective,
          itemExtent: itemExtent,
          clipToSize: clipToSize,
          renderChildrenOutsideViewport: renderChildrenOutsideViewport,
          offset: offset,
          children: children,
        );
      },
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
    this.diameterRatio,
    this.perspective,
    this.itemExtent,
    this.clipToSize,
    this.renderChildrenOutsideViewport,
    this.offset,
    List<Widget> children,
  }) : super(key: key, children: children);

  /// {@macro flutter.rendering.wheelList.diameterRatio}
  final double diameterRatio;

  /// {@macro flutter.rendering.wheelList.perspective}
  final double perspective;

  /// {@macro flutter.rendering.wheelList.itemExtent}
  final double itemExtent;

  /// Whether to clip painted children to the inside of this viewport.
  final bool clipToSize;

  /// {@macro flutter.rendering.wheelList.diameterRatio}
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
