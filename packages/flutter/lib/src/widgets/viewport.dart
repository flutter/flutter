// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

export 'package:flutter/rendering.dart' show
  AxisDirection,
  GrowthDirection;

/// A widget that is bigger on the inside.
///
/// [Viewport] is the visual workhorse of the scrolling machinery. It displays a
/// subset of its children according to its own dimensions and the given
/// [offset]. As the offset varies, different children are visible through
/// the viewport.
///
/// [Viewport] hosts a bidirectional list of slivers, anchored on a [center]
/// sliver, which is placed at the zero scroll offset. The center widget is
/// displayed in the viewport according to the [anchor] property.
///
/// Slivers that are earlier in the child list than [center] are displayed in
/// reverse order in the reverse [axisDirection] starting from the [center]. For
/// example, if the [axisDirection] is [AxisDirection.down], the first sliver
/// before [center] is placed above the [center]. The slivers that are later in
/// the child list than [center] are placed in order in the [axisDirection]. For
/// example, in the preceeding scenario, the first sliver after [center] is
/// placed below the [center].
///
/// [Viewport] cannot contain box children directly. Instead, use a
/// [SliverList], [SliverFixedExtentList], [SliverGrid], or a
/// [SliverToBoxAdapter], for example.
///
/// See also:
///
///  * [ListView], [PageView], [GridView], and [CustomScrollView], which combine
///    [Scrollable] and [Viewport] into widgets that are easier to use.
///  * [SliverToBoxAdapter], which allows a box widget to be placed inside a
///    sliver context (the opposite of this widget).
///  * [ShrinkWrappingViewport], a variant of [Viewport] that shrink-wraps its
///    contents along the main axis.
class Viewport extends MultiChildRenderObjectWidget {
  /// Creates a widget that is bigger on the inside.
  ///
  /// The viewport listens to the [offset], which means you do not need to
  /// rebuild this widget when the [offset] changes.
  ///
  /// The [offset] argument must not be null.
  Viewport({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.anchor: 0.0,
    @required this.offset,
    this.center,
    List<Widget> slivers: const <Widget>[],
  }) : assert(offset != null),
       assert(slivers != null),
       assert(center == null || slivers.where((Widget child) => child.key == center).length == 1),
       super(key: key, children: slivers);

  /// The direction in which the [offset]'s [ViewportOffset.pixels] increases.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
  /// offset of zero is at the top of the viewport and increases towards the
  /// bottom of the viewport.
  final AxisDirection axisDirection;

  /// The relative position of the zero scroll offset.
  ///
  /// For example, if [anchor] is 0.5 and the [axisDirection] is
  /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
  /// vertically centered within the viewport. If the [anchor] is 1.0, and the
  /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
  /// on the left edge of the viewport.
  final double anchor;

  /// Which part of the content inside the viewport should be visible.
  ///
  /// The [ViewportOffset.pixels] value determines the scroll offset that the
  /// viewport uses to select which part of its content to display. As the user
  /// scrolls the viewport, this value changes, which changes the content that
  /// is displayed.
  ///
  /// Typically a [ScrollPosition].
  final ViewportOffset offset;

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// Children after [center] will be placed in the [axisDirection] relative to
  /// the [center]. Children before [center] will be placed in the opposite of
  /// the [axisDirection] relative to the [center].
  ///
  /// The [center] must be the key of a child of the viewport.
  final Key center;

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return new RenderViewport(
      axisDirection: axisDirection,
      anchor: anchor,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderViewport renderObject) {
    renderObject.axisDirection = axisDirection;
    renderObject.anchor = anchor;
    renderObject.offset = offset;
  }

  @override
  _ViewportElement createElement() => new _ViewportElement(this);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('anchor: $anchor');
    description.add('offset: $offset');
    if (center != null) {
      description.add('center: $center');
    } else if (children.isNotEmpty && children.first.key != null) {
      description.add('center: ${children.first.key} (implicit)');
    }
  }
}

class _ViewportElement extends MultiChildRenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  _ViewportElement(Viewport widget) : super(widget);

  @override
  Viewport get widget => super.widget;

  @override
  RenderViewport get renderObject => super.renderObject;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _updateCenter();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _updateCenter();
  }

  void _updateCenter() {
    // TODO(ianh): cache the keys to make this faster
    if (widget.center != null) {
      renderObject.center = children.singleWhere(
        (Element element) => element.widget.key == widget.center
      ).renderObject;
    } else if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject;
    } else {
      renderObject.center = null;
    }
  }
}

/// A widget that is bigger on the inside and shrink wraps its children in the
/// main axis.
///
/// [ShrinkWrappingViewport] displays a subset of its children according to its
/// own dimensions and the given [offset]. As the offset varies, different
/// children are visible through the viewport.
///
/// [ShrinkWrappingViewport] differs from [Viewport] in that [Viewport] expands
/// to fill the main axis whereas [ShrinkWrappingViewport] sizes itself to match
/// its children in the main axis. This shrink wrapping behavior is expensive
/// because the children, and hence the viewport, could potentially change size
/// whenever the [offset] changes (e.g., because of a collapsing header).
///
/// [ShrinkWrappingViewport] cannot contain box children directly. Instead, use
/// a [SliverList], [SliverFixedExtentList], [SliverGrid], or a
/// [SliverToBoxAdapter], for example.
///
/// See also:
///
///  * [ListView], [PageView], [GridView], and [CustomScrollView], which combine
///    [Scrollable] and [ShrinkWrappingViewport] into widgets that are easier to
///    use.
///  * [SliverToBoxAdapter], which allows a box widget to be placed inside a
///    sliver context (the opposite of this widget).
///  * [Viewport], a viewport that does not shrink-wrap its contents
class ShrinkWrappingViewport extends MultiChildRenderObjectWidget {
  /// Creates a widget that is bigger on the inside and shrink wraps its
  /// children in the main axis.
  ///
  /// The viewport listens to the [offset], which means you do not need to
  /// rebuild this widget when the [offset] changes.
  ///
  /// The [offset] argument must not be null.
  ShrinkWrappingViewport({
    Key key,
    this.axisDirection: AxisDirection.down,
    @required this.offset,
    List<Widget> slivers: const <Widget>[],
  }) : assert(offset != null),
       super(key: key, children: slivers);

  /// The direction in which the [offset]'s [ViewportOffset.pixels] increases.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
  /// offset of zero is at the top of the viewport and increases towards the
  /// bottom of the viewport.
  final AxisDirection axisDirection;

  /// Which part of the content inside the viewport should be visible.
  ///
  /// The [ViewportOffset.pixels] value determines the scroll offset that the
  /// viewport uses to select which part of its content to display. As the user
  /// scrolls the viewport, this value changes, which changes the content that
  /// is displayed.
  ///
  /// Typically a [ScrollPosition].
  final ViewportOffset offset;

  @override
  RenderShrinkWrappingViewport createRenderObject(BuildContext context) {
    return new RenderShrinkWrappingViewport(
      axisDirection: axisDirection,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderShrinkWrappingViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..offset = offset;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$axisDirection');
    description.add('offset: $offset');
  }
}
