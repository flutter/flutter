// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'safe_area.dart';
import 'slotted_render_object_widget.dart';

/// The slots available for children managed by [EdgeInsetsOverlay].
///
/// See also:
///
///  * [EdgeInsetsOverlay.paintOrder], which configures the order in which child
///    and edge overlay widgets are painted and hit-tested.
enum EdgeInsetsOverlaySlot {
  /// The main content widget built by [EdgeInsetsOverlay.builder] that spans the
  /// full available area beneath overlays.
  child,

  /// The overlay widget docked along the left edge.
  left,

  /// The overlay widget docked along the top edge.
  top,

  /// The overlay widget docked along the right edge.
  right,

  /// The overlay widget docked along the bottom edge.
  bottom,
}

/// Represents an alignment point along a 1D axis for an edge overlay in [EdgeInsetsOverlay].
///
/// For overlays on the top or bottom edge, this represents the horizontal position
/// along that edge (from left to right).
///
/// For overlays on the left or right edge, this represents the vertical position
/// along that edge (from top to bottom).
///
/// The distance is fractional:
///  * -1.0 represents the start of the edge (left for top/bottom, top for left/right).
///  * 0.0 represents the center of the edge.
///  * 1.0 represents the end of the edge (right for top/bottom, bottom for left/right).
///
/// See also:
///
///  * [Alignment], which represents a 2D point within a rectangle.
@immutable
class EdgeOverlayAlignment {
  /// Creates an edge overlay alignment.
  ///
  /// The [value] represents the fractional point along the edge:
  /// -1.0 is the start, 0.0 is the center, and 1.0 is the end.
  const EdgeOverlayAlignment(this.value);

  /// The fractional point along the edge.
  ///
  ///  * -1.0 is the start of the edge (left for top/bottom, top for left/right).
  ///  * 0.0 is the center of the edge.
  ///  * 1.0 is the end of the edge (right for top/bottom, bottom for left/right).
  final double value;

  /// The start position along the edge (left for top/bottom, top for left/right).
  static const EdgeOverlayAlignment start = EdgeOverlayAlignment(-1.0);

  /// The center position along the edge.
  static const EdgeOverlayAlignment center = EdgeOverlayAlignment(0.0);

  /// The end position along the edge (right for top/bottom, bottom for left/right).
  static const EdgeOverlayAlignment end = EdgeOverlayAlignment(1.0);

  /// Returns the offset within [freeSpace] corresponding to this alignment.
  double alongOffset(double freeSpace) {
    return (freeSpace / 2.0) * (1.0 + value);
  }

  /// Linearly interpolate between two [EdgeOverlayAlignment]s.
  static EdgeOverlayAlignment? lerp(EdgeOverlayAlignment? a, EdgeOverlayAlignment? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return EdgeOverlayAlignment(ui.lerpDouble(0.0, b!.value, t)!);
    }
    if (b == null) {
      return EdgeOverlayAlignment(ui.lerpDouble(a.value, 0.0, t)!);
    }
    return EdgeOverlayAlignment(ui.lerpDouble(a.value, b.value, t)!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EdgeOverlayAlignment && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return switch (value) {
      -1.0 => 'EdgeOverlayAlignment.start',
      0.0 => 'EdgeOverlayAlignment.center',
      1.0 => 'EdgeOverlayAlignment.end',
      _ => 'EdgeOverlayAlignment($value)',
    };
  }
}

/// A configuration for an edge-docked overlay widget in [EdgeInsetsOverlay],
/// combining the [child] widget with its [alignment].
@immutable
class EdgeInsetsOverlaySide {
  /// Creates a configuration for an edge overlay in [EdgeInsetsOverlay].
  const EdgeInsetsOverlaySide({required this.child, this.alignment = EdgeOverlayAlignment.center});

  /// The widget displayed for this edge overlay.
  final Widget child;

  /// The alignment used to position this edge overlay along its docked edge.
  final EdgeOverlayAlignment alignment;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EdgeInsetsOverlaySide && other.child == child && other.alignment == alignment;
  }

  @override
  int get hashCode => Object.hash(child, alignment);

  @override
  String toString() => 'EdgeInsetsOverlaySide(child: $child, alignment: $alignment)';
}

/// Information about the measured dimensions and layout geometry of edge overlays
/// in an [EdgeInsetsOverlay].
///
/// Passed to [EdgeInsetsOverlayMetricsWidgetBuilder] to allow descendant widgets
/// to adapt their layout, padding, or custom painting to active edge overlays.
@immutable
class EdgeInsetsOverlayMetrics {
  /// Creates metrics describing the layout of edge overlays.
  const EdgeInsetsOverlayMetrics({
    this.padding = .zero,
    this.sizes = const <EdgeInsetsOverlaySlot, Size>{},
    this.alignments = const <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{},
  });

  /// The interior padding occupied by edge overlays inside the content bounds.
  final EdgeInsets padding;

  /// The measured full dimensions ([Size]) of each active edge overlay.
  final Map<EdgeInsetsOverlaySlot, Size> sizes;

  /// The alignments associated with each active edge overlay.
  final Map<EdgeInsetsOverlaySlot, EdgeOverlayAlignment> alignments;

  /// The measured size of the left overlay, or null if absent.
  Size? get leftSize => sizes[EdgeInsetsOverlaySlot.left];

  /// The measured size of the top overlay, or null if absent.
  Size? get topSize => sizes[EdgeInsetsOverlaySlot.top];

  /// The measured size of the right overlay, or null if absent.
  Size? get rightSize => sizes[EdgeInsetsOverlaySlot.right];

  /// The measured size of the bottom overlay, or null if absent.
  Size? get bottomSize => sizes[EdgeInsetsOverlaySlot.bottom];

  /// The alignment of the left overlay, or null if absent.
  EdgeOverlayAlignment? get leftAlignment => alignments[EdgeInsetsOverlaySlot.left];

  /// The alignment of the top overlay, or null if absent.
  EdgeOverlayAlignment? get topAlignment => alignments[EdgeInsetsOverlaySlot.top];

  /// The alignment of the right overlay, or null if absent.
  EdgeOverlayAlignment? get rightAlignment => alignments[EdgeInsetsOverlaySlot.right];

  /// The alignment of the bottom overlay, or null if absent.
  EdgeOverlayAlignment? get bottomAlignment => alignments[EdgeInsetsOverlaySlot.bottom];

  /// Whether an overlay widget is present at [slot].
  bool hasSlot(EdgeInsetsOverlaySlot slot) => sizes.containsKey(slot);

  /// Whether an overlay widget is present at [EdgeInsetsOverlaySlot.left].
  bool get hasLeft => hasSlot(.left);

  /// Whether an overlay widget is present at [EdgeInsetsOverlaySlot.top].
  bool get hasTop => hasSlot(.top);

  /// Whether an overlay widget is present at [EdgeInsetsOverlaySlot.right].
  bool get hasRight => hasSlot(.right);

  /// Whether an overlay widget is present at [EdgeInsetsOverlaySlot.bottom].
  bool get hasBottom => hasSlot(.bottom);

  /// Computes the unobstructed interior [Rect] within the content bounds for the given [size], deflated by [padding].
  Rect innerBounds(Size size) => padding.deflateRect(Offset.zero & size);

  /// Computes the bounding [Rect] of the overlay at [slot] for the given [contentSize],
  /// expressed in the content child's local coordinate system (origin at top-left).
  ///
  /// Returns null if no overlay is present at [slot].
  Rect? rectOf(EdgeInsetsOverlaySlot slot, Size contentSize) {
    if (slot == .child) {
      return Offset.zero & contentSize;
    }
    final Size? sideSize = sizes[slot];
    final EdgeOverlayAlignment? alignment = alignments[slot];
    if (sideSize == null || alignment == null) {
      return null;
    }
    return switch (slot) {
      .left => Rect.fromLTWH(
        0.0,
        alignment.alongOffset(contentSize.height - sideSize.height),
        sideSize.width,
        sideSize.height,
      ),
      .top => Rect.fromLTWH(
        alignment.alongOffset(contentSize.width - sideSize.width),
        0.0,
        sideSize.width,
        sideSize.height,
      ),
      .right => Rect.fromLTWH(
        contentSize.width - sideSize.width,
        alignment.alongOffset(contentSize.height - sideSize.height),
        sideSize.width,
        sideSize.height,
      ),
      .bottom => Rect.fromLTWH(
        alignment.alongOffset(contentSize.width - sideSize.width),
        contentSize.height - sideSize.height,
        sideSize.width,
        sideSize.height,
      ),
      .child => Offset.zero & contentSize,
    };
  }

  /// Computes the bounding [Rect] of the left overlay for the given [contentSize], or null if absent.
  Rect? leftRect(Size contentSize) => rectOf(.left, contentSize);

  /// Computes the bounding [Rect] of the top overlay for the given [contentSize], or null if absent.
  Rect? topRect(Size contentSize) => rectOf(.top, contentSize);

  /// Computes the bounding [Rect] of the right overlay for the given [contentSize], or null if absent.
  Rect? rightRect(Size contentSize) => rectOf(.right, contentSize);

  /// Computes the bounding [Rect] of the bottom overlay for the given [contentSize], or null if absent.
  Rect? bottomRect(Size contentSize) => rectOf(.bottom, contentSize);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EdgeInsetsOverlayMetrics &&
        other.padding == padding &&
        mapEquals(other.sizes, sizes) &&
        mapEquals(other.alignments, alignments);
  }

  @override
  int get hashCode => Object.hash(
    padding,
    sizes[EdgeInsetsOverlaySlot.child],
    sizes[EdgeInsetsOverlaySlot.left],
    sizes[EdgeInsetsOverlaySlot.top],
    sizes[EdgeInsetsOverlaySlot.right],
    sizes[EdgeInsetsOverlaySlot.bottom],
    alignments[EdgeInsetsOverlaySlot.child],
    alignments[EdgeInsetsOverlaySlot.left],
    alignments[EdgeInsetsOverlaySlot.top],
    alignments[EdgeInsetsOverlaySlot.right],
    alignments[EdgeInsetsOverlaySlot.bottom],
  );

  @override
  String toString() =>
      'EdgeInsetsOverlayMetrics(padding: $padding, sizes: $sizes, alignments: $alignments)';
}

/// Signature for building the main content of an [EdgeInsetsOverlay],
/// receiving the layout [constraints] and measured [overlayPadding] of active edge widgets.
typedef EdgeInsetsOverlayWidgetBuilder =
    Widget Function(BuildContext context, BoxConstraints constraints, EdgeInsets overlayPadding);

/// Signature for building the main content of an [EdgeInsetsOverlay.metrics],
/// receiving the layout [constraints] and computed overlay [metrics].
typedef EdgeInsetsOverlayMetricsWidgetBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      EdgeInsetsOverlayMetrics metrics,
    );

/// A widget that positions edge-docked side widgets and a main content widget
/// built by [builder], providing the measured overlay dimensions as [EdgeInsets].
///
/// The content built by [builder] expands to fill the entire available space,
/// extending across any provided [top], [bottom], [left], or [right] widgets.
/// The [EdgeInsets] passed to [builder] represents the exact dimensions of the
/// active side overlay widgets.
///
/// The relative paint and hit-test order between the main content and the edge
/// widgets is configurable via [paintOrder].
///
/// This allows descendants to explicitly adapt their padding or layout (e.g. for
/// map viewports, lists, or custom painters).
///
/// See also:
///
///  * [SafeArea], which insets its child to avoid operating system intrusions.
class EdgeInsetsOverlay extends StatelessWidget {
  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder].
  EdgeInsetsOverlay({
    Key? key,
    Widget? left,
    Widget? top,
    Widget? right,
    Widget? bottom,
    List<EdgeInsetsOverlaySlot> paintOrder = EdgeInsetsOverlaySlot.values,
    required EdgeInsetsOverlayWidgetBuilder builder,
  }) : this.metrics(
         key: key,
         left: left != null ? .new(child: left) : null,
         top: top != null ? .new(child: top) : null,
         right: right != null ? .new(child: right) : null,
         bottom: bottom != null ? .new(child: bottom) : null,
         paintOrder: paintOrder,
         builder:
             (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) {
               return builder(context, constraints, metrics.padding);
             },
       );

  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder] using explicit [EdgeInsetsOverlaySide] configurations.
  const EdgeInsetsOverlay.metrics({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
    required this.builder,
  });

  /// The overlay configuration to place at the left edge.
  final EdgeInsetsOverlaySide? left;

  /// The overlay configuration to place at the top edge.
  final EdgeInsetsOverlaySide? top;

  /// The overlay configuration to place at the right edge.
  final EdgeInsetsOverlaySide? right;

  /// The overlay configuration to place at the bottom edge.
  final EdgeInsetsOverlaySide? bottom;

  /// The order in which the child and edge overlay widgets are painted and hit-tested.
  ///
  /// The widgets are painted from first to last in this list. Later widgets in the
  /// list paint on top of earlier ones and receive hit test events first.
  ///
  /// Defaults to [EdgeInsetsOverlaySlot.values].
  final List<EdgeInsetsOverlaySlot> paintOrder;

  /// Called to build the main content for [EdgeInsetsOverlaySlot.child],
  /// receiving the layout [constraints] and computed [metrics] of active edge widgets.
  final EdgeInsetsOverlayMetricsWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final Widget finalChild = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(
          constraints is _EdgeInsetsOverlayBoxConstraints,
          'EdgeInsetsOverlay builder received unexpected BoxConstraints. '
          'Expected _EdgeInsetsOverlayBoxConstraints containing EdgeInsetsOverlayMetrics.',
        );
        if (constraints is! _EdgeInsetsOverlayBoxConstraints) {
          return const SizedBox.shrink();
        }

        return builder(context, constraints, constraints.metrics);
      },
    );

    return _EdgeInsetsOverlay(
      left: left?.child,
      top: top?.child,
      right: right?.child,
      bottom: bottom?.child,
      leftAlignment: left?.alignment ?? EdgeOverlayAlignment.center,
      topAlignment: top?.alignment ?? EdgeOverlayAlignment.center,
      rightAlignment: right?.alignment ?? EdgeOverlayAlignment.center,
      bottomAlignment: bottom?.alignment ?? EdgeOverlayAlignment.center,
      paintOrder: paintOrder,
      child: finalChild,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('left', left, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('top', top, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('right', right, defaultValue: null));
    properties.add(
      DiagnosticsProperty<EdgeInsetsOverlaySide?>('bottom', bottom, defaultValue: null),
    );
    properties.add(
      IterableProperty<EdgeInsetsOverlaySlot>(
        'paintOrder',
        paintOrder,
        defaultValue: EdgeInsetsOverlaySlot.values,
      ),
    );
    properties.add(
      ObjectFlagProperty<EdgeInsetsOverlayMetricsWidgetBuilder>.has('builder', builder),
    );
  }
}

class _EdgeInsetsOverlay
    extends SlottedMultiChildRenderObjectWidget<EdgeInsetsOverlaySlot, RenderBox> {
  const _EdgeInsetsOverlay({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.child,
    this.leftAlignment = EdgeOverlayAlignment.center,
    this.topAlignment = EdgeOverlayAlignment.center,
    this.rightAlignment = EdgeOverlayAlignment.center,
    this.bottomAlignment = EdgeOverlayAlignment.center,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
  });

  final Widget? left;
  final Widget? top;
  final Widget? right;
  final Widget? bottom;
  final Widget child;
  final EdgeOverlayAlignment leftAlignment;
  final EdgeOverlayAlignment topAlignment;
  final EdgeOverlayAlignment rightAlignment;
  final EdgeOverlayAlignment bottomAlignment;
  final List<EdgeInsetsOverlaySlot> paintOrder;

  @override
  Iterable<EdgeInsetsOverlaySlot> get slots => EdgeInsetsOverlaySlot.values;

  @override
  Widget? childForSlot(EdgeInsetsOverlaySlot slot) {
    return switch (slot) {
      .left => left,
      .top => top,
      .right => right,
      .bottom => bottom,
      .child => child,
    };
  }

  @override
  _RenderEdgeInsetsOverlay createRenderObject(BuildContext context) {
    return _RenderEdgeInsetsOverlay(
      leftAlignment: leftAlignment,
      topAlignment: topAlignment,
      rightAlignment: rightAlignment,
      bottomAlignment: bottomAlignment,
      paintOrder: paintOrder,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderEdgeInsetsOverlay renderObject) {
    renderObject
      ..leftAlignment = leftAlignment
      ..topAlignment = topAlignment
      ..rightAlignment = rightAlignment
      ..bottomAlignment = bottomAlignment
      ..paintOrder = paintOrder;
  }
}

class _RenderEdgeInsetsOverlay extends RenderBox
    with SlottedContainerRenderObjectMixin<EdgeInsetsOverlaySlot, RenderBox> {
  _RenderEdgeInsetsOverlay({
    EdgeOverlayAlignment leftAlignment = EdgeOverlayAlignment.center,
    EdgeOverlayAlignment topAlignment = EdgeOverlayAlignment.center,
    EdgeOverlayAlignment rightAlignment = EdgeOverlayAlignment.center,
    EdgeOverlayAlignment bottomAlignment = EdgeOverlayAlignment.center,
    List<EdgeInsetsOverlaySlot> paintOrder = EdgeInsetsOverlaySlot.values,
  }) : _leftAlignment = leftAlignment,
       _topAlignment = topAlignment,
       _rightAlignment = rightAlignment,
       _bottomAlignment = bottomAlignment,
       _paintOrder = paintOrder,
       _resolvedPaintOrder = <EdgeInsetsOverlaySlot>{
         ...paintOrder,
         ...EdgeInsetsOverlaySlot.values,
       }.toList();

  /// The overlay child at the left edge.
  RenderBox? get leftChild => childForSlot(.left);

  /// The overlay child at the top edge.
  RenderBox? get topChild => childForSlot(.top);

  /// The overlay child at the right edge.
  RenderBox? get rightChild => childForSlot(.right);

  /// The overlay child at the bottom edge.
  RenderBox? get bottomChild => childForSlot(.bottom);

  /// The content child spanning the full area beneath overlays.
  RenderBox? get contentChild => childForSlot(.child);

  @override
  Iterable<RenderBox> get children => _resolvedPaintOrder.map(childForSlot).nonNulls;

  /// The alignment configuration for the left edge overlay.
  EdgeOverlayAlignment get leftAlignment => _leftAlignment;
  EdgeOverlayAlignment _leftAlignment;
  set leftAlignment(EdgeOverlayAlignment value) {
    if (_leftAlignment == value) {
      return;
    }
    _leftAlignment = value;
    markNeedsLayout();
  }

  /// The alignment configuration for the top edge overlay.
  EdgeOverlayAlignment get topAlignment => _topAlignment;
  EdgeOverlayAlignment _topAlignment;
  set topAlignment(EdgeOverlayAlignment value) {
    if (_topAlignment == value) {
      return;
    }
    _topAlignment = value;
    markNeedsLayout();
  }

  /// The alignment configuration for the right edge overlay.
  EdgeOverlayAlignment get rightAlignment => _rightAlignment;
  EdgeOverlayAlignment _rightAlignment;
  set rightAlignment(EdgeOverlayAlignment value) {
    if (_rightAlignment == value) {
      return;
    }
    _rightAlignment = value;
    markNeedsLayout();
  }

  /// The alignment configuration for the bottom edge overlay.
  EdgeOverlayAlignment get bottomAlignment => _bottomAlignment;
  EdgeOverlayAlignment _bottomAlignment;
  set bottomAlignment(EdgeOverlayAlignment value) {
    if (_bottomAlignment == value) {
      return;
    }
    _bottomAlignment = value;
    markNeedsLayout();
  }

  /// The order in which the child and edge overlay widgets are painted and hit-tested.
  List<EdgeInsetsOverlaySlot> get paintOrder => _paintOrder;
  List<EdgeInsetsOverlaySlot> _paintOrder;
  set paintOrder(List<EdgeInsetsOverlaySlot> value) {
    if (listEquals(_paintOrder, value)) {
      return;
    }
    _paintOrder = value;
    _resolvedPaintOrder = <EdgeInsetsOverlaySlot>{
      ...value,
      ...EdgeInsetsOverlaySlot.values,
    }.toList();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  List<EdgeInsetsOverlaySlot> _resolvedPaintOrder;

  /// The latest computed metrics for the active overlays.
  EdgeInsetsOverlayMetrics get metrics => _metrics;
  EdgeInsetsOverlayMetrics _metrics = const .new();

  @override
  double computeMinIntrinsicWidth(double height) {
    final RenderBox? contentChild = this.contentChild;
    if (contentChild != null) {
      return contentChild.getMinIntrinsicWidth(height);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final RenderBox? contentChild = this.contentChild;
    if (contentChild != null) {
      return contentChild.getMaxIntrinsicWidth(height);
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final RenderBox? contentChild = this.contentChild;
    if (contentChild != null) {
      return contentChild.getMinIntrinsicHeight(width);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final RenderBox? contentChild = this.contentChild;
    if (contentChild != null) {
      return contentChild.getMaxIntrinsicHeight(width);
    }
    return 0.0;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final RenderBox? contentChild = this.contentChild;
    if (contentChild != null) {
      return constraints.constrain(contentChild.getDryLayout(constraints));
    }
    return constraints.smallest;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    final RenderBox? leftChild = this.leftChild;
    final RenderBox? topChild = this.topChild;
    final RenderBox? rightChild = this.rightChild;
    final RenderBox? bottomChild = this.bottomChild;
    final RenderBox? contentChild = this.contentChild;

    Size leftSize = .zero;
    Size topSize = .zero;
    Size rightSize = .zero;
    Size bottomSize = .zero;

    final sizes = <EdgeInsetsOverlaySlot, Size>{};
    final alignments = <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{};

    if (leftChild != null) {
      leftChild.layout(constraints.loosen(), parentUsesSize: true);
      leftSize = leftChild.size;
      sizes[.left] = leftSize;
      alignments[.left] = leftAlignment;
    }

    if (topChild != null) {
      topChild.layout(constraints.loosen(), parentUsesSize: true);
      topSize = topChild.size;
      sizes[.top] = topSize;
      alignments[.top] = topAlignment;
    }

    if (rightChild != null) {
      rightChild.layout(constraints.loosen(), parentUsesSize: true);
      rightSize = rightChild.size;
      sizes[.right] = rightSize;
      alignments[.right] = rightAlignment;
    }

    if (bottomChild != null) {
      bottomChild.layout(constraints.loosen(), parentUsesSize: true);
      bottomSize = bottomChild.size;
      sizes[.bottom] = bottomSize;
      alignments[.bottom] = bottomAlignment;
    }

    final EdgeInsets padding = .fromLTRB(
      leftSize.width,
      topSize.height,
      rightSize.width,
      bottomSize.height,
    );

    _metrics = .new(padding: padding, sizes: sizes, alignments: alignments);

    if (contentChild != null) {
      contentChild.layout(
        _EdgeInsetsOverlayBoxConstraints(constraints: constraints, metrics: metrics),
        parentUsesSize: true,
      );
      size = constraints.constrain(contentChild.size);
      final parentData = contentChild.parentData! as BoxParentData;
      parentData.offset = .zero;
    } else {
      size = constraints.smallest;
    }

    if (leftChild != null) {
      final parentData = leftChild.parentData! as BoxParentData;
      parentData.offset = metrics.leftRect(size)!.topLeft;
    }

    if (topChild != null) {
      final parentData = topChild.parentData! as BoxParentData;
      parentData.offset = metrics.topRect(size)!.topLeft;
    }

    if (rightChild != null) {
      final parentData = rightChild.parentData! as BoxParentData;
      parentData.offset = metrics.rightRect(size)!.topLeft;
    }

    if (bottomChild != null) {
      final parentData = bottomChild.parentData! as BoxParentData;
      parentData.offset = metrics.bottomRect(size)!.topLeft;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final RenderBox child in children) {
      final parentData = child.parentData! as BoxParentData;
      context.paintChild(child, parentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (int i = _resolvedPaintOrder.length - 1; i >= 0; i--) {
      final RenderBox? child = childForSlot(_resolvedPaintOrder[i]);
      if (child == null) {
        continue;
      }
      final parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<EdgeOverlayAlignment>(
        'leftAlignment',
        leftAlignment,
        defaultValue: EdgeOverlayAlignment.center,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeOverlayAlignment>(
        'topAlignment',
        topAlignment,
        defaultValue: EdgeOverlayAlignment.center,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeOverlayAlignment>(
        'rightAlignment',
        rightAlignment,
        defaultValue: EdgeOverlayAlignment.center,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeOverlayAlignment>(
        'bottomAlignment',
        bottomAlignment,
        defaultValue: EdgeOverlayAlignment.center,
      ),
    );
    properties.add(
      IterableProperty<EdgeInsetsOverlaySlot>(
        'paintOrder',
        paintOrder,
        defaultValue: EdgeInsetsOverlaySlot.values,
      ),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsOverlayMetrics>('metrics', metrics));
  }
}

/// Custom [BoxConstraints] subclass used to pass the computed overlay metrics
/// down to the [LayoutBuilder] wrapping the child widget.
///
/// Because [RenderObject.layout] short-circuits execution if incoming constraints
/// compare equal (`==`), embedding [metrics] directly inside these
/// constraints ensures that changes to overlay dimensions or positions will reliably
/// trigger a relayout and rebuild of the [builder] inside [LayoutBuilder], even when
/// the total outer dimensions remain unchanged.
class _EdgeInsetsOverlayBoxConstraints extends BoxConstraints {
  /// Creates box constraints that also convey layout [metrics] to the child layout.
  _EdgeInsetsOverlayBoxConstraints({required BoxConstraints constraints, required this.metrics})
    : super(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
        minHeight: constraints.minHeight,
        maxHeight: constraints.maxHeight,
      );

  /// The metrics representing the measured dimensions and layout geometry of the overlays.
  final EdgeInsetsOverlayMetrics metrics;

  @override
  bool operator ==(Object other) {
    assert(debugAssertIsValid());
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    assert(other is _EdgeInsetsOverlayBoxConstraints && other.debugAssertIsValid());
    return other is _EdgeInsetsOverlayBoxConstraints &&
        other.metrics == metrics &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode {
    assert(debugAssertIsValid());
    return Object.hash(metrics, minWidth, maxWidth, minHeight, maxHeight);
  }
}
