// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'safe_area.dart';
import 'slotted_render_object_widget.dart';

// Examples can assume:
// typedef MySearchBar = Placeholder;
// typedef MyNavigationRail = Placeholder;
// typedef MainContent = Placeholder;

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

/// Parent data for use with [EdgeInsetsOverlay].
class EdgeInsetsOverlayParentData extends BoxParentData {
  /// How the edge overlay child should be positioned along its docked edge,
  /// represented as a fractional offset between -1.0 and 1.0.
  ///
  ///  * -1.0 is the start of the edge (left for top/bottom in LTR, right in RTL; top for left/right).
  ///  * 0.0 is the center of the edge.
  ///  * 1.0 is the end of the edge (right for top/bottom in LTR, left in RTL; bottom for left/right).
  double? alignment;

  @override
  String toString() => '${super.toString()}; alignment=$alignment';
}

/// Controls how an edge overlay child in an [EdgeInsetsOverlay] is positioned
/// along its docked edge.
///
/// An [EdgeInsetsOverlay] centers each edge child along its docked edge by default (alignment 0.0).
/// Wrapping an edge child in a [SidePositioned] allows customizing that alignment
/// using a fractional offset between -1.0 and 1.0 (such as [SidePositioned.start],
/// [SidePositioned.center], [SidePositioned.end], or [SidePositioned] with a custom alignment).
///
/// Overlays on the top and bottom edges use horizontal alignment to determine their
/// position along the X-axis (where -1.0 places the widget at the start edge according
/// to the ambient [Directionality], and 1.0 places it at the end edge).
///
/// Overlays on the left and right edges use vertical alignment to determine their
/// position along the Y-axis (where -1.0 places the widget at the top edge, and 1.0
/// places it at the bottom edge).
class SidePositioned extends ParentDataWidget<EdgeInsetsOverlayParentData> {
  /// Creates a widget that controls the alignment of an edge overlay child in [EdgeInsetsOverlay].
  ///
  /// The [alignment] value must be between -1.0 and 1.0. Defaults to 0.0 (centered).
  const SidePositioned({super.key, this.alignment = 0.0, required super.child})
    : assert(alignment >= -1.0 && alignment <= 1.0);

  /// Creates a widget that aligns the edge overlay at the start of its docked edge (-1.0).
  ///
  /// For top and bottom overlays, this aligns the child to the start of the reading
  /// direction. For left and right overlays, this aligns the child to the top edge.
  const SidePositioned.start({super.key, required super.child}) : alignment = -1.0;

  /// Creates a widget that centers the edge overlay along its docked edge (0.0).
  const SidePositioned.center({super.key, required super.child}) : alignment = 0.0;

  /// Creates a widget that aligns the edge overlay at the end of its docked edge (1.0).
  ///
  /// For top and bottom overlays, this aligns the child to the end of the reading
  /// direction. For left and right overlays, this aligns the child to the bottom edge.
  const SidePositioned.end({super.key, required super.child}) : alignment = 1.0;

  /// The alignment used to position the child along its docked edge, from -1.0 to 1.0.
  final double alignment;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is EdgeInsetsOverlayParentData);
    final parentData = renderObject.parentData! as EdgeInsetsOverlayParentData;
    if (parentData.alignment != alignment) {
      parentData.alignment = alignment;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => EdgeInsetsOverlay;

  @override
  String get debugTypicalAncestorWidgetDescription =>
      'EdgeInsetsOverlay or EdgeInsetsOverlayDirectional';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('alignment', alignment));
  }
}

/// Information about the measured dimensions and layout geometry of edge overlays
/// in an [EdgeInsetsOverlay].
///
/// Passed to [EdgeInsetsOverlayBuilder] to allow descendant widgets to adapt their
/// layout, padding, or custom painting to active edge overlays.
@immutable
class EdgeInsetsOverlayMetrics {
  /// Creates metrics describing the layout of edge overlays.
  ///
  /// This constructor is visible for testing purposes only. In application code,
  /// metrics instances are created and supplied automatically by the framework.
  @visibleForTesting
  const EdgeInsetsOverlayMetrics({
    this._sizes = const <EdgeInsetsOverlaySlot, Size>{},
    this._alignments = const <EdgeInsetsOverlaySlot, double>{},
    this.textDirection,
  });

  final Map<EdgeInsetsOverlaySlot, Size> _sizes;
  final Map<EdgeInsetsOverlaySlot, double> _alignments;

  /// The text direction used to resolve alignments along horizontal edges, or null if unspecified.
  final TextDirection? textDirection;

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

  /// The measured size of the left overlay, or null if absent.
  Size? get leftSize => _sizes[EdgeInsetsOverlaySlot.left];

  /// The measured size of the top overlay, or null if absent.
  Size? get topSize => _sizes[EdgeInsetsOverlaySlot.top];

  /// The measured size of the right overlay, or null if absent.
  Size? get rightSize => _sizes[EdgeInsetsOverlaySlot.right];

  /// The measured size of the bottom overlay, or null if absent.
  Size? get bottomSize => _sizes[EdgeInsetsOverlaySlot.bottom];

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

  /// Whether an overlay widget is present at the left edge.
  bool get hasLeft => leftSize != null;

  /// Whether an overlay widget is present at the top edge.
  bool get hasTop => topSize != null;

  /// Whether an overlay widget is present at the right edge.
  bool get hasRight => rightSize != null;

  /// Whether an overlay widget is present at the bottom edge.
  bool get hasBottom => bottomSize != null;

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

  /// The alignment of the left overlay along its docked edge (-1.0 to 1.0), or null if absent.
  ///
  /// -1.0 corresponds to the top edge, 0.0 to the vertical center, and 1.0 to the bottom edge.
  double? get leftAlignment => _alignmentOf(EdgeInsetsOverlaySlot.left);

  /// The alignment of the top overlay along its docked edge (-1.0 to 1.0), or null if absent.
  ///
  /// -1.0 corresponds to the start edge according to [textDirection], 0.0 to the horizontal center,
  /// and 1.0 to the end edge.
  double? get topAlignment => _alignmentOf(EdgeInsetsOverlaySlot.top);

  /// The alignment of the right overlay along its docked edge (-1.0 to 1.0), or null if absent.
  ///
  /// -1.0 corresponds to the top edge, 0.0 to the vertical center, and 1.0 to the bottom edge.
  double? get rightAlignment => _alignmentOf(EdgeInsetsOverlaySlot.right);

  /// The alignment of the bottom overlay along its docked edge (-1.0 to 1.0), or null if absent.
  ///
  /// -1.0 corresponds to the start edge according to [textDirection], 0.0 to the horizontal center,
  /// and 1.0 to the end edge.
  double? get bottomAlignment => _alignmentOf(EdgeInsetsOverlaySlot.bottom);

  /// The alignment of the start overlay along its docked edge (-1.0 to 1.0) according to [textDirection],
  /// or null if absent.
  ///
  /// -1.0 corresponds to the top edge, 0.0 to the vertical center, and 1.0 to the bottom edge.
  double? get startAlignment => switch (textDirection) {
    .rtl => rightAlignment,
    .ltr || null => leftAlignment,
  };

  /// The alignment of the end overlay along its docked edge (-1.0 to 1.0) according to [textDirection],
  /// or null if absent.
  ///
  /// -1.0 corresponds to the top edge, 0.0 to the vertical center, and 1.0 to the bottom edge.
  double? get endAlignment => switch (textDirection) {
    .rtl => leftAlignment,
    .ltr || null => rightAlignment,
  };

  double? _alignmentOf(EdgeInsetsOverlaySlot slot) => _alignments[slot];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EdgeInsetsOverlayMetrics &&
        mapEquals(other._sizes, _sizes) &&
        mapEquals(other._alignments, _alignments) &&
        other.textDirection == textDirection;
  }

  @override
  int get hashCode => Object.hash(
    _sizes[EdgeInsetsOverlaySlot.left],
    _sizes[EdgeInsetsOverlaySlot.top],
    _sizes[EdgeInsetsOverlaySlot.right],
    _sizes[EdgeInsetsOverlaySlot.bottom],
    _alignments[EdgeInsetsOverlaySlot.left],
    _alignments[EdgeInsetsOverlaySlot.top],
    _alignments[EdgeInsetsOverlaySlot.right],
    _alignments[EdgeInsetsOverlaySlot.bottom],
    textDirection,
  );

  @override
  String toString() =>
      'EdgeInsetsOverlayMetrics(padding: $padding, directionalPadding: $directionalPadding, textDirection: $textDirection)';
}

/// Signature for building the main content of an [EdgeInsetsOverlay],
/// receiving the layout [constraints] and measured overlay [metrics].
typedef EdgeInsetsOverlayBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  EdgeInsetsOverlayMetrics metrics,
);

/// A widget that positions edge-docked side widgets and a main content widget
/// built by [builder], providing measured overlay dimensions and layout metrics.
///
/// The content built by [builder] expands to fill the entire available space,
/// extending across any provided [top], [bottom], [left], or [right] widgets.
/// The [EdgeInsetsOverlayMetrics] passed to [builder] represents the exact dimensions
/// and alignments of the active side overlay widgets.
///
/// Each edge overlay is positioned independently and will overlap at corners if
/// adjacent overlays are provided. The relative paint and hit-test order between
/// the main content and the edge widgets is configurable via [paintOrder].
///
/// By default, edge overlays are centered along their docked edge. To customize
/// the alignment of an edge overlay, wrap it in a [SidePositioned] widget:
///
/// {@tool snippet}
/// ```dart
/// EdgeInsetsOverlay(
///   top: const SidePositioned.end(child: MySearchBar()),
///   builder: (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) {
///     return Padding(
///       padding: metrics.padding,
///       child: const MainContent(),
///     );
///   },
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// For reading-direction-aware layouts (start and end), use [EdgeInsetsOverlayDirectional]:
///
/// ```dart
/// EdgeInsetsOverlayDirectional(
///   start: const SidePositioned.center(child: MyNavigationRail()),
///   builder: (BuildContext context, BoxConstraints constraints, EdgeInsetsOverlayMetrics metrics) {
///     return Padding(
///       padding: metrics.directionalPadding.resolve(Directionality.of(context)),
///       child: const MainContent(),
///     );
///   },
/// )
/// ```
/// {@end-tool}
///
/// ## Overlapping edge overlays and paint order
///
/// Similar to [Stack] with multiple edge-aligned [Positioned] widgets, edge
/// overlays are positioned independently along each edge across the full bounds
/// and are not partitioned sequentially. If multiple edge overlays intersect
/// (for example, a `top` bar and a `left` rail sharing the top-left corner),
/// they will overlap.
///
/// The relative painting and hit-testing order between the main content and the
/// edge overlays is configured using [paintOrder]. Widgets appearing later in
/// [paintOrder] are painted on top of earlier ones and receive pointer hit-test
/// events first.
///
/// ## Layout constraints and sizing
///
/// Side overlays are laid out using the incoming constraints loosened ([BoxConstraints.loosen]),
/// while the overall widget sizes itself to match the dimensions of the main content
/// built by [builder].
///
/// When [EdgeInsetsOverlay] receives unbounded or loose constraints (such as `maxWidth: 800`)
/// and the [builder] content sizes itself smaller than those bounds (such as `300`), an overlay
/// configured to expand along that axis (e.g. `width: double.infinity`) will be measured against
/// the parent's maximum width (`800`) and may visually extend past the final container bounds (`300`).
/// For edge-to-edge layouts, [EdgeInsetsOverlay] is typically placed within tight constraints
/// (such as full-screen views, expanded containers, or [SizedBox.expand]).
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
///  * [EdgeInsetsOverlayDirectional], for reading-direction-aware edge overlays.
///  * [SidePositioned], which configures alignment of an edge overlay in [EdgeInsetsOverlay].
///  * [EdgeInsetsOverlayMetrics], which provides full layout geometry to [builder].
///  * [EdgeInsets], which provides computed padding insets.
///  * [SafeArea], which insets its child to avoid operating system intrusions.
class EdgeInsetsOverlay extends _EdgeInsetsOverlayBase {
  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder] using physical edges ([left] and [right]).
  ///
  /// The [left], [top], [right], and [bottom] widgets are automatically centered
  /// along their docked edge by default, or aligned using [SidePositioned].
  ///
  /// The [builder] receives the measured layout [BoxConstraints] and [EdgeInsetsOverlayMetrics].
  const EdgeInsetsOverlay({
    super.key,
    this.left,
    super.top,
    this.right,
    super.bottom,
    super.paintOrder,
    super.textDirection,
    required super.builder,
  });

  /// The overlay widget to place at the left edge.
  final Widget? left;

  /// The overlay widget to place at the right edge.
  final Widget? right;

  @override
  _ResolvedSides _resolveSides(BuildContext context) {
    return (left, right, textDirection ?? Directionality.maybeOf(context));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget?>('left', left, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('right', right, defaultValue: null));
  }
}

/// A widget that positions edge-docked side widgets and a main content widget
/// built by [builder], providing measured overlay dimensions and layout metrics
/// along reading-direction-aware edges ([start] and [end]).
///
/// The ambient [Directionality] (or explicit [textDirection]) determines whether
/// [start] corresponds to the left or right edge, and whether [end] corresponds
/// to the right or left edge.
///
/// The content built by [builder] expands to fill the entire available space,
/// extending across any provided [top], [bottom], [start], or [end] widgets.
/// The [EdgeInsetsOverlayMetrics] passed to [builder] represents the exact dimensions
/// and alignments of the active side overlay widgets.
///
/// See also:
///
///  * [EdgeInsetsOverlay], which positions overlays along physical edges ([left] and [right]).
///  * [SidePositioned], which configures alignment of an edge overlay.
///  * [EdgeInsetsOverlayMetrics], which provides full layout geometry to [builder].
class EdgeInsetsOverlayDirectional extends _EdgeInsetsOverlayBase {
  /// Creates a widget that positions edge-docked side widgets and a content widget
  /// built by [builder] using reading-direction-aware edges ([start] and [end]).
  ///
  /// The ambient [Directionality] (or explicit [textDirection]) determines whether
  /// [start] corresponds to the left or right edge, and whether [end] corresponds
  /// to the right or left edge.
  ///
  /// The [start], [top], [end], and [bottom] widgets are automatically centered
  /// along their docked edge by default, or aligned using [SidePositioned].
  ///
  /// The [builder] receives the measured layout [BoxConstraints] and [EdgeInsetsOverlayMetrics].
  const EdgeInsetsOverlayDirectional({
    super.key,
    this.start,
    super.top,
    this.end,
    super.bottom,
    super.paintOrder,
    super.textDirection,
    required super.builder,
  });

  /// The overlay widget to place at the start edge.
  final Widget? start;

  /// The overlay widget to place at the end edge.
  final Widget? end;

  @override
  _ResolvedSides _resolveSides(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    final TextDirection effectiveTextDirection =
        textDirection ?? Directionality.maybeOf(context) ?? .ltr;
    final (Widget? resolvedLeft, Widget? resolvedRight) = switch (effectiveTextDirection) {
      .ltr => (start, end),
      .rtl => (end, start),
    };
    return (resolvedLeft, resolvedRight, effectiveTextDirection);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget?>('start', start, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('end', end, defaultValue: null));
  }
}

typedef _ResolvedSides = (Widget? left, Widget? right, TextDirection? textDirection);

/// Shared layout and rendering base class for [EdgeInsetsOverlay] and [EdgeInsetsOverlayDirectional].
abstract class _EdgeInsetsOverlayBase extends StatelessWidget {
  const _EdgeInsetsOverlayBase({
    super.key,
    this.top,
    this.bottom,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
    this.textDirection,
    required this.builder,
  });

  /// The overlay widget to place at the top edge.
  final Widget? top;

  /// The overlay widget to place at the bottom edge.
  final Widget? bottom;

  /// The order in which the child and edge overlay widgets are painted and hit-tested.
  final List<EdgeInsetsOverlaySlot> paintOrder;

  /// The text direction with which to resolve directional alignments along horizontal edges.
  final TextDirection? textDirection;

  /// Called to build the main content for [EdgeInsetsOverlaySlot.child].
  final EdgeInsetsOverlayBuilder builder;

  /// Resolves the horizontal edge overlays and effective [TextDirection] for layout.
  _ResolvedSides _resolveSides(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final (Widget? resolvedLeft, Widget? resolvedRight, TextDirection? effectiveTextDirection) =
        _resolveSides(context);

    return _SlottedEdgeInsetsOverlay(
      left: resolvedLeft,
      top: top,
      right: resolvedRight,
      bottom: bottom,
      paintOrder: paintOrder,
      textDirection: effectiveTextDirection,
      child: LayoutBuilder(
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
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget?>('top', top, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('bottom', bottom, defaultValue: null));
    properties.add(
      IterableProperty<EdgeInsetsOverlaySlot>(
        'paintOrder',
        paintOrder,
        defaultValue: EdgeInsetsOverlaySlot.values,
      ),
    );
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(ObjectFlagProperty<EdgeInsetsOverlayBuilder>.has('builder', builder));
  }
}

class _SlottedEdgeInsetsOverlay
    extends SlottedMultiChildRenderObjectWidget<EdgeInsetsOverlaySlot, RenderBox> {
  const _SlottedEdgeInsetsOverlay({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.child,
    this.paintOrder = EdgeInsetsOverlaySlot.values,
    this.textDirection,
  });

  final Widget? left;
  final Widget? top;
  final Widget? right;
  final Widget? bottom;
  final Widget child;
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
    return _RenderEdgeInsetsOverlay(paintOrder: paintOrder, textDirection: textDirection);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderEdgeInsetsOverlay renderObject) {
    renderObject
      ..paintOrder = paintOrder
      ..textDirection = textDirection;
  }
}

class _RenderEdgeInsetsOverlay extends RenderBox
    with SlottedContainerRenderObjectMixin<EdgeInsetsOverlaySlot, RenderBox> {
  _RenderEdgeInsetsOverlay({
    List<EdgeInsetsOverlaySlot> paintOrder = EdgeInsetsOverlaySlot.values,
    this._textDirection,
  }) : _paintOrder = paintOrder,
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
  void setupParentData(RenderObject child) {
    if (child.parentData is! EdgeInsetsOverlayParentData) {
      child.parentData = EdgeInsetsOverlayParentData();
    }
  }

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
    final alignments = <EdgeInsetsOverlaySlot, double>{};

    if (leftChild != null) {
      leftChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.left] = leftChild.size;
      final parentData = leftChild.parentData! as EdgeInsetsOverlayParentData;
      alignments[.left] = parentData.alignment ?? 0.0;
    }

    if (topChild != null) {
      topChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.top] = topChild.size;
      final parentData = topChild.parentData! as EdgeInsetsOverlayParentData;
      alignments[.top] = parentData.alignment ?? 0.0;
    }

    if (rightChild != null) {
      rightChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.right] = rightChild.size;
      final parentData = rightChild.parentData! as EdgeInsetsOverlayParentData;
      alignments[.right] = parentData.alignment ?? 0.0;
    }

    if (bottomChild != null) {
      bottomChild.layout(constraints.loosen(), parentUsesSize: true);
      sizes[.bottom] = bottomChild.size;
      final parentData = bottomChild.parentData! as EdgeInsetsOverlayParentData;
      alignments[.bottom] = parentData.alignment ?? 0.0;
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
      final parentData = leftChild.parentData! as EdgeInsetsOverlayParentData;
      parentData.offset = _offsetForSlot(
        EdgeInsetsOverlaySlot.left,
        childSize: leftChild.size,
        alignment: parentData.alignment ?? 0.0,
        contentSize: size,
      );
    }

    if (topChild != null) {
      final parentData = topChild.parentData! as EdgeInsetsOverlayParentData;
      parentData.offset = _offsetForSlot(
        EdgeInsetsOverlaySlot.top,
        childSize: topChild.size,
        alignment: parentData.alignment ?? 0.0,
        contentSize: size,
      );
    }

    if (rightChild != null) {
      final parentData = rightChild.parentData! as EdgeInsetsOverlayParentData;
      parentData.offset = _offsetForSlot(
        EdgeInsetsOverlaySlot.right,
        childSize: rightChild.size,
        alignment: parentData.alignment ?? 0.0,
        contentSize: size,
      );
    }

    if (bottomChild != null) {
      final parentData = bottomChild.parentData! as EdgeInsetsOverlayParentData;
      parentData.offset = _offsetForSlot(
        EdgeInsetsOverlaySlot.bottom,
        childSize: bottomChild.size,
        alignment: parentData.alignment ?? 0.0,
        contentSize: size,
      );
    }
  }

  Offset _offsetForSlot(
    EdgeInsetsOverlaySlot slot, {
    required Size childSize,
    required double alignment,
    required Size contentSize,
  }) {
    final double effectiveAlignment = switch (slot) {
      .top || .bottom => (textDirection == TextDirection.rtl) ? -alignment : alignment,
      .left || .right || .child => alignment,
    };
    return switch (slot) {
      .left => Offset(
        0.0,
        ((contentSize.height - childSize.height) / 2.0) * (1.0 + effectiveAlignment),
      ),
      .top => Offset(
        ((contentSize.width - childSize.width) / 2.0) * (1.0 + effectiveAlignment),
        0.0,
      ),
      .right => Offset(
        contentSize.width - childSize.width,
        ((contentSize.height - childSize.height) / 2.0) * (1.0 + effectiveAlignment),
      ),
      .bottom => Offset(
        ((contentSize.width - childSize.width) / 2.0) * (1.0 + effectiveAlignment),
        contentSize.height - childSize.height,
      ),
      .child => Offset.zero,
    };
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
