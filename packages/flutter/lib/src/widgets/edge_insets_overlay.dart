// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'safe_area.dart';
import 'slotted_render_object_widget.dart';

/// The slots available for children managed by [EdgeInsetsGeometryOverlay]
/// (such as [EdgeInsetsOverlay] and [EdgeInsetsDirectionalOverlay]).
///
/// See also:
///
///  * [EdgeInsetsGeometryOverlay.paintOrder], which configures the order in which child
///    and edge overlay widgets are painted and hit-tested.
enum EdgeInsetsOverlaySlot {
  /// The main content widget built by [EdgeInsetsGeometryOverlay.builder] that spans the
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

/// Represents an alignment point along a 1D axis for an edge overlay in [EdgeInsetsGeometryOverlay].
///
/// For overlays on the top or bottom edge, this represents the horizontal position
/// along that edge. In [TextDirection.ltr] contexts, -1.0 represents the left edge
/// and 1.0 represents the right edge. In [TextDirection.rtl] contexts, these are
/// reversed: -1.0 represents the right edge (the start of the text direction)
/// and 1.0 represents the left edge (the end).
///
/// For overlays on the left or right edge, this represents the vertical position
/// along that edge (from top to bottom).
///
/// The distance is fractional:
///  * -1.0 represents the start of the edge (left for top/bottom in LTR, right in RTL; top for left/right).
///  * 0.0 represents the center of the edge.
///  * 1.0 represents the end of the edge (right for top/bottom in LTR, left in RTL; bottom for left/right).
///
/// See also:
///
///  * [Alignment], which represents a 2D point within a rectangle using physical coordinates.
///  * [AlignmentDirectional], which represents a 2D point within a rectangle using directional coordinates.
@immutable
class EdgeOverlayAlignment {
  /// Creates an edge overlay alignment.
  ///
  /// The [value] represents the fractional point along the edge:
  /// -1.0 is the start, 0.0 is the center, and 1.0 is the end.
  const EdgeOverlayAlignment(this.value);

  /// The fractional point along the edge.
  ///
  ///  * -1.0 is the start of the edge.
  ///  * 0.0 is the center of the edge.
  ///  * 1.0 is the end of the edge.
  final double value;

  /// The start position along the edge (start of reading direction for top/bottom, top for left/right).
  static const EdgeOverlayAlignment start = .new(-1.0);

  /// The center position along the edge.
  static const EdgeOverlayAlignment center = .new(0.0);

  /// The end position along the edge (end of reading direction for top/bottom, bottom for left/right).
  static const EdgeOverlayAlignment end = .new(1.0);

  /// Resolves this alignment according to the given [TextDirection].
  ///
  /// If [direction] is [TextDirection.rtl], the alignment is inverted so that
  /// [start] aligns with the right edge and [end] aligns with the left edge.
  /// If [direction] is null or [TextDirection.ltr], returns this alignment unchanged.
  EdgeOverlayAlignment resolve(TextDirection? direction) {
    if (direction == .rtl) {
      if (value == 0.0) {
        return center;
      }
      return EdgeOverlayAlignment(-value);
    }
    return this;
  }

  /// Returns the offset within [freeSpace] corresponding to this alignment.
  ///
  /// If [textDirection] is [TextDirection.rtl], the alignment is resolved such
  /// that [start] corresponds to the right side of [freeSpace] and [end]
  /// corresponds to the left side.
  double alongOffset(double freeSpace, {TextDirection? textDirection}) {
    final double effectiveValue = resolve(textDirection).value;
    return (freeSpace / 2.0) * (1.0 + effectiveValue);
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

/// A configuration for an edge-docked overlay widget in [EdgeInsetsGeometryOverlay],
/// combining the [child] widget with its [alignment].
@immutable
class EdgeInsetsOverlaySide {
  /// Creates a configuration for an edge overlay in [EdgeInsetsGeometryOverlay].
  const EdgeInsetsOverlaySide({required this.child, this.alignment = .center});

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
/// in an [EdgeInsetsGeometryOverlay].
///
/// Passed to [EdgeInsetsOverlayMetricsWidgetBuilder] to allow descendant widgets
/// to adapt their layout, padding, or custom painting to active edge overlays.
@immutable
class EdgeInsetsOverlayMetrics {
  /// Creates metrics describing the layout of edge overlays.
  const EdgeInsetsOverlayMetrics({
    this.sizes = const <EdgeInsetsOverlaySlot, Size>{},
    this.alignments = const <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{},
    this.textDirection,
  });

  /// The interior padding occupied by edge overlays inside the content bounds.
  EdgeInsets get padding => .fromLTRB(
    leftSize?.width ?? 0.0,
    topSize?.height ?? 0.0,
    rightSize?.width ?? 0.0,
    bottomSize?.height ?? 0.0,
  );

  /// The interior padding occupied by edge overlays inside the content bounds,
  /// expressed as an [EdgeInsetsDirectional].
  EdgeInsetsDirectional get directionalPadding => .fromSTEB(
    startSize?.width ?? 0.0,
    topSize?.height ?? 0.0,
    endSize?.width ?? 0.0,
    bottomSize?.height ?? 0.0,
  );

  /// The measured full dimensions ([Size]) of each active edge overlay.
  final Map<EdgeInsetsOverlaySlot, Size> sizes;

  /// The alignments associated with each active edge overlay.
  final Map<EdgeInsetsOverlaySlot, EdgeOverlayAlignment> alignments;

  /// The text direction used to resolve alignments along horizontal edges, or null if unspecified.
  final TextDirection? textDirection;

  /// The measured size of the left overlay, or null if absent.
  Size? get leftSize => sizes[EdgeInsetsOverlaySlot.left];

  /// The measured size of the top overlay, or null if absent.
  Size? get topSize => sizes[EdgeInsetsOverlaySlot.top];

  /// The measured size of the right overlay, or null if absent.
  Size? get rightSize => sizes[EdgeInsetsOverlaySlot.right];

  /// The measured size of the bottom overlay, or null if absent.
  Size? get bottomSize => sizes[EdgeInsetsOverlaySlot.bottom];

  /// The measured size of the start overlay according to [textDirection], or null if absent.
  Size? get startSize => switch (textDirection) {
    .rtl => rightSize,
    .ltr || null => leftSize,
  };

  /// The measured size of the end overlay according to [textDirection], or null if absent.
  Size? get endSize => switch (textDirection) {
    .rtl => leftSize,
    .ltr || null => rightSize,
  };

  /// The alignment of the left overlay, or null if absent.
  EdgeOverlayAlignment? get leftAlignment => alignments[EdgeInsetsOverlaySlot.left];

  /// The alignment of the top overlay, or null if absent.
  EdgeOverlayAlignment? get topAlignment => alignments[EdgeInsetsOverlaySlot.top];

  /// The alignment of the right overlay, or null if absent.
  EdgeOverlayAlignment? get rightAlignment => alignments[EdgeInsetsOverlaySlot.right];

  /// The alignment of the bottom overlay, or null if absent.
  EdgeOverlayAlignment? get bottomAlignment => alignments[EdgeInsetsOverlaySlot.bottom];

  /// The alignment of the start overlay according to [textDirection], or null if absent.
  EdgeOverlayAlignment? get startAlignment => switch (textDirection) {
    .rtl => rightAlignment,
    .ltr || null => leftAlignment,
  };

  /// The alignment of the end overlay according to [textDirection], or null if absent.
  EdgeOverlayAlignment? get endAlignment => switch (textDirection) {
    .rtl => leftAlignment,
    .ltr || null => rightAlignment,
  };

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

  /// Whether an overlay widget is present at the start edge according to [textDirection].
  bool get hasStart => switch (textDirection) {
    .rtl => hasRight,
    .ltr || null => hasLeft,
  };

  /// Whether an overlay widget is present at the end edge according to [textDirection].
  bool get hasEnd => switch (textDirection) {
    .rtl => hasLeft,
    .ltr || null => hasRight,
  };

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
        alignment.alongOffset(contentSize.width - sideSize.width, textDirection: textDirection),
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
        alignment.alongOffset(contentSize.width - sideSize.width, textDirection: textDirection),
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

  /// Computes the bounding [Rect] of the start overlay for the given [contentSize]
  /// according to [textDirection], or null if absent.
  Rect? startRect(Size contentSize) => switch (textDirection) {
    .rtl => rightRect(contentSize),
    .ltr || null => leftRect(contentSize),
  };

  /// Computes the bounding [Rect] of the end overlay for the given [contentSize]
  /// according to [textDirection], or null if absent.
  Rect? endRect(Size contentSize) => switch (textDirection) {
    .rtl => leftRect(contentSize),
    .ltr || null => rightRect(contentSize),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EdgeInsetsOverlayMetrics &&
        mapEquals(other.sizes, sizes) &&
        mapEquals(other.alignments, alignments) &&
        other.textDirection == textDirection;
  }

  @override
  int get hashCode => Object.hash(
    sizes[EdgeInsetsOverlaySlot.left],
    sizes[EdgeInsetsOverlaySlot.top],
    sizes[EdgeInsetsOverlaySlot.right],
    sizes[EdgeInsetsOverlaySlot.bottom],
    alignments[EdgeInsetsOverlaySlot.left],
    alignments[EdgeInsetsOverlaySlot.top],
    alignments[EdgeInsetsOverlaySlot.right],
    alignments[EdgeInsetsOverlaySlot.bottom],
    textDirection,
  );

  @override
  String toString() =>
      'EdgeInsetsOverlayMetrics(padding: $padding, sizes: $sizes, alignments: $alignments, textDirection: $textDirection)';
}

/// Signature for building the main content of an [EdgeInsetsOverlay],
/// receiving the layout [constraints] and measured [overlayPadding] of active edge widgets.
typedef EdgeInsetsOverlayWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  EdgeInsets overlayPadding,
);

/// Signature for building the main content of an [EdgeInsetsDirectionalOverlay],
/// receiving the layout [constraints] and measured [overlayPadding] of active edge widgets.
typedef EdgeInsetsDirectionalOverlayWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  EdgeInsetsDirectional overlayPadding,
);

/// Signature for building the main content of an [EdgeInsetsGeometryOverlay.metrics]
/// (such as [EdgeInsetsOverlay.metrics] or [EdgeInsetsDirectionalOverlay.metrics]),
/// receiving the layout [constraints] and computed overlay [metrics].
typedef EdgeInsetsOverlayMetricsWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  EdgeInsetsOverlayMetrics metrics,
);

/// Abstract base class for widgets that position edge-docked overlays around a
/// main content widget, providing measured overlay dimensions to a builder callback.
///
/// Subclasses include:
///
///  * [EdgeInsetsOverlay], which positions overlays along physical edges ([EdgeInsetsOverlay.left],
///    [EdgeInsetsOverlay.right], [top], and [bottom]) and provides the measured overlay dimensions
///    as an [EdgeInsets].
///  * [EdgeInsetsDirectionalOverlay], which positions overlays along reading-direction-aware
///    edges ([EdgeInsetsDirectionalOverlay.start], [EdgeInsetsDirectionalOverlay.end], [top],
///    and [bottom]) and provides the measured overlay dimensions as an [EdgeInsetsDirectional].
///
/// Both widgets allow the content child built by [builder] to expand across the full
/// available area beneath the edge overlays. The measured dimensions of the active
/// edge overlays are then provided to the [builder] callback, allowing descendant
/// widgets (such as scroll views, map viewports, or custom painters) to adapt their
/// interior padding or layout accordingly without clipping.
///
/// ## Overlapping edge overlays and paint order
///
/// Similar to [Stack] with multiple edge-aligned [Positioned] widgets, edge
/// overlays are positioned independently along each edge across the full bounds
/// and are not partitioned sequentially. If multiple edge overlays intersect
/// (for example, a [top] bar and a [left] rail sharing the top-left corner),
/// they will overlap.
///
/// The relative painting and hit-testing order between the main content and the
/// edge overlays is configured using [paintOrder]. Widgets appearing later in
/// [paintOrder] are painted on top of earlier ones and receive pointer hit-test
/// events first.
///
/// ## Intrinsic dimensions and dry layout
///
/// Because [builder] is evaluated inside a [LayoutBuilder] to receive layout-time
/// overlay metrics, intrinsic dimensions cannot be calculated ahead of layout.
/// Querying intrinsic dimensions or computing dry layout on this widget delegates
/// to the underlying [LayoutBuilder], which will throw an exception in accordance
/// with [LayoutBuilder]'s standard contract.
///
/// See also:
///
///  * [EdgeInsetsOverlay], for physical edge positioning (left and right).
///  * [EdgeInsetsDirectionalOverlay], for directional edge positioning (start and end).
///  * [EdgeInsetsOverlaySide], which pairs an overlay widget with its alignment.
///  * [EdgeInsetsOverlayMetrics], which provides full layout geometry to [builder].
///  * [EdgeInsetsGeometry], the base class for insets representing the dimensions
///    calculated by these overlay widgets.
abstract class EdgeInsetsGeometryOverlay extends StatelessWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const EdgeInsetsGeometryOverlay({
    super.key,
    this.top,
    this.bottom,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
    this.textDirection,
    required this.builder,
  });

  /// The overlay configuration to place at the top edge.
  final EdgeInsetsOverlaySide? top;

  /// The overlay configuration to place at the bottom edge.
  final EdgeInsetsOverlaySide? bottom;

  /// The order in which the child and edge overlay widgets are painted and hit-tested.
  ///
  /// Similar to children of a [Stack], edge overlays positioned along intersecting
  /// edges (such as a top bar and a left rail) will overlap at their corner intersection.
  /// The widgets are painted from first to last in this list: later widgets in the
  /// list paint on top of earlier ones and receive hit test events first.
  ///
  /// Defaults to [EdgeInsetsOverlaySlot.values], painting in order: [EdgeInsetsOverlaySlot.child],
  /// [EdgeInsetsOverlaySlot.left], [EdgeInsetsOverlaySlot.top], [EdgeInsetsOverlaySlot.right],
  /// and [EdgeInsetsOverlaySlot.bottom].
  final List<EdgeInsetsOverlaySlot> paintOrder;

  /// The text direction with which to resolve directional alignments along horizontal edges.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// Called to build the main content for [EdgeInsetsOverlaySlot.child],
  /// receiving the layout [constraints] and computed [metrics] of active edge widgets.
  final EdgeInsetsOverlayMetricsWidgetBuilder builder;

  /// Builds the content child wrapped in a [LayoutBuilder] that unpacks
  /// the overlay metrics from [_EdgeInsetsOverlayBoxConstraints].
  ///
  /// Intrinsic dimensions and dry layout are not supported because they are
  /// delegated to the underlying [LayoutBuilder].
  @protected
  Widget buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(
          constraints is _EdgeInsetsOverlayBoxConstraints,
          '$runtimeType builder received unexpected BoxConstraints. '
          'Expected _EdgeInsetsOverlayBoxConstraints containing EdgeInsetsOverlayMetrics.',
        );
        if (constraints is! _EdgeInsetsOverlayBoxConstraints) {
          return const SizedBox.shrink();
        }

        return builder(context, constraints, constraints.metrics);
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('top', top, defaultValue: null));
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
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(
      ObjectFlagProperty<EdgeInsetsOverlayMetricsWidgetBuilder>.has('builder', builder),
    );
  }
}

/// A widget that positions edge-docked side widgets and a main content widget
/// built by [builder], providing the measured overlay dimensions as [EdgeInsets].
///
/// The content built by [builder] expands to fill the entire available space,
/// extending across any provided [top], [bottom], [left], or [right] widgets.
/// The [EdgeInsets] passed to [builder] represents the exact dimensions of the
/// active side overlay widgets.
///
/// Similar to [Stack], edge overlays are positioned independently and will overlap
/// at corners if adjacent overlays are provided. The relative paint and hit-test
/// order between the main content and the edge widgets is configurable via [paintOrder].
///
/// This allows descendants to explicitly adapt their padding or layout (e.g. for
/// map viewports, lists, or custom painters).
///
/// See also:
///
///  * [EdgeInsetsDirectionalOverlay], which positions overlays along reading-direction-aware
///    edges ([EdgeInsetsDirectionalOverlay.start] and [EdgeInsetsDirectionalOverlay.end]).
///  * [EdgeInsetsGeometryOverlay], the abstract base class for overlay widgets.
///  * [EdgeInsetsOverlaySide], which configures an edge overlay along with its alignment.
///  * [EdgeInsetsOverlayMetrics], which provides full layout geometry to [EdgeInsetsOverlay.metrics].
///  * [SafeArea], which insets its child to avoid operating system intrusions.
class EdgeInsetsOverlay extends EdgeInsetsGeometryOverlay {
  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder].
  ///
  /// The [left], [top], [right], and [bottom] widgets are automatically wrapped in
  /// an [EdgeInsetsOverlaySide] with default centered alignment.
  ///
  /// The [builder] receives the measured [EdgeInsets] representing the thickness of
  /// each active edge overlay.
  EdgeInsetsOverlay({
    Key? key,
    Widget? left,
    Widget? top,
    Widget? right,
    Widget? bottom,
    List<EdgeInsetsOverlaySlot> paintOrder = EdgeInsetsOverlaySlot.values,
    TextDirection? textDirection,
    required EdgeInsetsOverlayWidgetBuilder builder,
  }) : this.metrics(
         key: key,
         left: left != null ? .new(child: left) : null,
         top: top != null ? .new(child: top) : null,
         right: right != null ? .new(child: right) : null,
         bottom: bottom != null ? .new(child: bottom) : null,
         paintOrder: paintOrder,
         textDirection: textDirection,
         builder:
             (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) {
               return builder(context, constraints, metrics.padding);
             },
       );

  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder] using explicit [EdgeInsetsOverlaySide] configurations.
  ///
  /// The [builder] receives full [EdgeInsetsOverlayMetrics], providing detailed size,
  /// alignment, and bounding rectangle information for every edge overlay.
  const EdgeInsetsOverlay.metrics({
    super.key,
    this.left,
    super.top,
    this.right,
    super.bottom,
    super.paintOrder = EdgeInsetsOverlaySlot.values,
    super.textDirection,
    required super.builder,
  });

  /// The overlay configuration to place at the left edge.
  final EdgeInsetsOverlaySide? left;

  /// The overlay configuration to place at the right edge.
  final EdgeInsetsOverlaySide? right;

  @override
  Widget build(BuildContext context) {
    final TextDirection? effectiveTextDirection = textDirection ?? Directionality.maybeOf(context);

    return _EdgeInsetsOverlay(
      left: left?.child,
      top: top?.child,
      right: right?.child,
      bottom: bottom?.child,
      leftAlignment: left?.alignment ?? .center,
      topAlignment: top?.alignment ?? .center,
      rightAlignment: right?.alignment ?? .center,
      bottomAlignment: bottom?.alignment ?? .center,
      paintOrder: paintOrder,
      textDirection: effectiveTextDirection,
      child: buildContent(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('left', left, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('right', right, defaultValue: null));
  }
}

/// A widget that positions edge-docked side widgets using reading-direction-aware
/// edges ([start] and [end]) and a main content widget built by [builder],
/// providing the measured overlay dimensions as [EdgeInsetsDirectional].
///
/// The ambient [Directionality] (or explicit [textDirection]) determines whether
/// [start] corresponds to the left or right edge, and whether [end] corresponds
/// to the right or left edge.
///
/// The content built by [builder] expands to fill the entire available space,
/// extending across any provided [top], [bottom], [start], or [end] widgets.
/// The [EdgeInsetsDirectional] passed to [builder] represents the exact dimensions
/// of the active side overlay widgets.
///
/// Similar to [Stack], edge overlays are positioned independently and will overlap
/// at corners if adjacent overlays are provided. The relative paint and hit-test
/// order between the main content and the edge widgets is configurable via [paintOrder].
///
/// This allows descendants to explicitly adapt their padding or layout (e.g. for
/// map viewports, lists, or custom painters) while respecting internationalization
/// and reading direction.
///
/// See also:
///
///  * [EdgeInsetsOverlay], which positions overlays along physical edges ([EdgeInsetsOverlay.left] and [EdgeInsetsOverlay.right]).
///  * [EdgeInsetsGeometryOverlay], the abstract base class for overlay widgets.
///  * [EdgeInsetsOverlaySide], which configures an edge overlay along with its alignment.
///  * [EdgeInsetsOverlayMetrics], which provides full layout geometry to [EdgeInsetsDirectionalOverlay.metrics].
///  * [Directionality], which provides ambient text direction.
///  * [SafeArea], which insets its child to avoid operating system intrusions.
class EdgeInsetsDirectionalOverlay extends EdgeInsetsGeometryOverlay {
  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder] using reading-direction-aware edges.
  ///
  /// The [start], [top], [end], and [bottom] widgets are automatically wrapped in
  /// an [EdgeInsetsOverlaySide] with default centered alignment.
  ///
  /// The [builder] receives the measured [EdgeInsetsDirectional] representing the
  /// thickness of each active edge overlay.
  EdgeInsetsDirectionalOverlay({
    Key? key,
    Widget? start,
    Widget? top,
    Widget? end,
    Widget? bottom,
    List<EdgeInsetsOverlaySlot> paintOrder = EdgeInsetsOverlaySlot.values,
    TextDirection? textDirection,
    required EdgeInsetsDirectionalOverlayWidgetBuilder builder,
  }) : this.metrics(
         key: key,
         start: start != null ? .new(child: start) : null,
         top: top != null ? .new(child: top) : null,
         end: end != null ? .new(child: end) : null,
         bottom: bottom != null ? .new(child: bottom) : null,
         paintOrder: paintOrder,
         textDirection: textDirection,
         builder:
             (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) {
               return builder(context, constraints, metrics.directionalPadding);
             },
       );

  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder] using explicit [EdgeInsetsOverlaySide] configurations.
  ///
  /// The [builder] receives full [EdgeInsetsOverlayMetrics], providing detailed size,
  /// alignment, and bounding rectangle information for every edge overlay.
  const EdgeInsetsDirectionalOverlay.metrics({
    super.key,
    this.start,
    super.top,
    this.end,
    super.bottom,
    super.paintOrder = EdgeInsetsOverlaySlot.values,
    super.textDirection,
    required super.builder,
  });

  /// The overlay configuration to place at the start edge.
  final EdgeInsetsOverlaySide? start;

  /// The overlay configuration to place at the end edge.
  final EdgeInsetsOverlaySide? end;

  @override
  Widget build(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    final TextDirection effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? TextDirection.ltr;

    final Widget? left;
    final Widget? right;
    final EdgeOverlayAlignment? leftAlignment;
    final EdgeOverlayAlignment? rightAlignment;

    switch (effectiveTextDirection) {
      case .ltr:
        left = start?.child;
        right = end?.child;
        leftAlignment = start?.alignment;
        rightAlignment = end?.alignment;
      case .rtl:
        left = end?.child;
        right = start?.child;
        leftAlignment = end?.alignment;
        rightAlignment = start?.alignment;
    }

    return _EdgeInsetsOverlay(
      left: left,
      top: top?.child,
      right: right,
      bottom: bottom?.child,
      leftAlignment: leftAlignment ?? .center,
      topAlignment: top?.alignment ?? .center,
      rightAlignment: rightAlignment ?? .center,
      bottomAlignment: bottom?.alignment ?? .center,
      paintOrder: paintOrder,
      textDirection: effectiveTextDirection,
      child: buildContent(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('start', start, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsOverlaySide?>('end', end, defaultValue: null));
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
    this.leftAlignment = .center,
    this.topAlignment = .center,
    this.rightAlignment = .center,
    this.bottomAlignment = .center,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
    this.textDirection,
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
  final TextDirection? textDirection;

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
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderEdgeInsetsOverlay renderObject) {
    renderObject
      ..leftAlignment = leftAlignment
      ..topAlignment = topAlignment
      ..rightAlignment = rightAlignment
      ..bottomAlignment = bottomAlignment
      ..paintOrder = paintOrder
      ..textDirection = textDirection;
  }
}

class _RenderEdgeInsetsOverlay extends RenderBox
    with SlottedContainerRenderObjectMixin<EdgeInsetsOverlaySlot, RenderBox> {
  _RenderEdgeInsetsOverlay({
    this._leftAlignment = .center,
    this._topAlignment = .center,
    this._rightAlignment = .center,
    this._bottomAlignment = .center,
    this._paintOrder = EdgeInsetsOverlaySlot.values,
    this._textDirection,
  }) : _resolvedPaintOrder = <EdgeInsetsOverlaySlot>{
         ..._paintOrder,
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

  // The following uses sync* because the list of children must be generated
  // lazily in the order specified by _resolvedPaintOrder preventing massive
  // memory overhead from creating a full list of children at once.
  @override
  Iterable<RenderBox> get children sync* {
    for (final EdgeInsetsOverlaySlot slot in _resolvedPaintOrder) {
      final RenderBox? child = childForSlot(slot);
      if (child != null) {
        yield child;
      }
    }
  }

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

  /// The text direction used to resolve alignments along horizontal edges.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
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

  // Intrinsic dimensions and dry layout are intentionally delegated to [contentChild]
  // (which is backed by [LayoutBuilder]). In accordance with [LayoutBuilder]'s contract,
  // attempting to compute intrinsic dimensions or dry layout will throw.

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

    final sizes = <EdgeInsetsOverlaySlot, Size>{};
    final alignments = <EdgeInsetsOverlaySlot, EdgeOverlayAlignment>{};

    if (leftChild != null) {
      leftChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.left] = leftChild.size;
      alignments[.left] = leftAlignment;
    }

    if (topChild != null) {
      topChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.top] = topChild.size;
      alignments[.top] = topAlignment;
    }

    if (rightChild != null) {
      rightChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.right] = rightChild.size;
      alignments[.right] = rightAlignment;
    }

    if (bottomChild != null) {
      bottomChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.bottom] = bottomChild.size;
      alignments[.bottom] = bottomAlignment;
    }

    _metrics = .new(sizes: sizes, alignments: alignments, textDirection: textDirection);

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
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
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
