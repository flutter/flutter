// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// A sliver that clips its child using a rectangle.
///
/// By default, it clips the child to its bounds. It can also clip based on a
/// custom [clipper].
///
/// This widget is particularly useful when used in a [CustomScrollView] with
/// pinned slivers (like [SliverAppBar] with [SliverAppBar.pinned] set to true).
/// When [clipOverlap] is true (the default), it automatically clips the portion
/// of the child that is overlapped by the pinned sliver, preventing the child
/// from being visible underneath a semi-transparent or translucent pinned header.
///
/// {@tool snippet}
///
/// This example shows a [CustomScrollView] with a pinned [SliverAppBar] and a
/// [SliverClipRect] wrapping a list. As the list scrolls up, the items are
/// clipped so they don't appear behind the semi-transparent app bar.
///
/// ```dart
/// CustomScrollView(
///   slivers: <Widget>[
///     SliverAppBar(
///       pinned: true,
///       expandedHeight: 200.0,
///       backgroundColor: Colors.blue.withAlpha(128), // Semi-transparent
///       flexibleSpace: const FlexibleSpaceBar(
///         title: Text('SliverClipRect'),
///       ),
///     ),
///     SliverClipRect(
///       sliver: SliverList(
///         delegate: SliverChildBuilderDelegate(
///           (BuildContext context, int index) {
///             return Container(
///               height: 100.0,
///               color: index.isEven ? Colors.grey[200] : Colors.grey[300],
///               child: Center(child: Text('Item $index')),
///             );
///           },
///           childCount: 20,
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverClipRRect], which clips a sliver with a rounded rectangle.
///  * [ClipRect], which clips a box widget.
///  * [CustomClipper], for creating custom clips.
class SliverClipRect extends SingleChildRenderObjectWidget {
  /// Creates a sliver that clips its child.
  const SliverClipRect({
    super.key,
    required Widget sliver,
    this.clipper,
    this.clipBehavior = Clip.hardEdge,
    this.clipOverlap = true,
  }) : super(child: sliver);

  /// If non-null, determines which clip rectangle to use.
  final CustomClipper<Rect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  final Clip clipBehavior;

  /// Whether to automatically clip the portion of the child that is overlapped
  /// by preceding pinned slivers.
  ///
  /// If true, the clip rect will be adjusted to exclude the area defined by
  /// [SliverConstraints.overlap]. This is useful to ensure content passing
  /// underneath a semi-transparent pinned header is not visible.
  ///
  /// Defaults to true.
  final bool clipOverlap;

  @override
  RenderSliverClipRect createRenderObject(BuildContext context) {
    return RenderSliverClipRect(
      clipper: clipper,
      clipBehavior: clipBehavior,
      clipOverlap: clipOverlap,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverClipRect renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..clipOverlap = clipOverlap;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper, defaultValue: null),
    );
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
    properties.add(DiagnosticsProperty<bool>('clipOverlap', clipOverlap, defaultValue: true));
  }
}

/// A sliver render object that clips its child.
class RenderSliverClipRect extends _RenderSliverCustomClip<Rect> {
  /// Creates a sliver render object for clipping.
  RenderSliverClipRect({
    super.clipper,
    super.clipBehavior = Clip.hardEdge,
    super.clipOverlap = true,
  });

  @override
  Rect buildClip() {
    final Rect maxPaintRect = getMaxPaintRect();
    Rect newClip = clipper?.getClip(maxPaintRect.size) ?? maxPaintRect;

    final double clipExtent = switch (constraints.axis) {
      Axis.horizontal => newClip.width,
      Axis.vertical => newClip.height,
    };

    if (clipOverlap && constraints.overlap > 0) {
      final double clipOrigin = getClipOriginForOverlap(clipExtent);
      newClip = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => newClip.copyWith(top: clipOrigin),
        AxisDirection.up => newClip.copyWith(bottom: geometry!.paintExtent - clipOrigin),
        AxisDirection.right => newClip.copyWith(left: clipOrigin),
        AxisDirection.left => newClip.copyWith(right: geometry!.paintExtent - clipOrigin),
      };
    }
    return newClip;
  }

  @override
  bool clipContains(Offset offset, Rect clip) => clip.contains(offset);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !child!.geometry!.visible) {
      layer = null;
      return;
    }

    final Rect? clipRect = getClip();
    if (clipRect != null) {
      if (!clipRect.isEmpty) {
        layer = context.pushClipRect(
          needsCompositing,
          offset,
          clipRect,
          (PaintingContext context, Offset offset) {
            context.paintChild(child!, offset);
          },
          clipBehavior: clipBehavior,
          oldLayer: layer as ClipRectLayer?,
        );
      } else {
        layer = null;
      }
    } else {
      context.paintChild(child!, offset);
    }
  }
}

extension on Rect {
  Rect copyWith({double? left, double? top, double? right, double? bottom}) =>
      Rect.fromLTRB(left ?? this.left, top ?? this.top, right ?? this.right, bottom ?? this.bottom);
}

/// A sliver that clips its child using a rounded rectangle.
///
/// By default, it clips the child to its bounds with the given [borderRadius].
/// It can also clip based on a custom [clipper].
///
/// This widget is particularly useful when used in a [CustomScrollView] with
/// pinned slivers (like [SliverAppBar] with [SliverAppBar.pinned] set to true).
/// When [clipOverlap] is true (the default), it automatically clips the portion
/// of the child that is overlapped by the pinned sliver, preventing the child
/// from being visible underneath a semi-transparent or translucent pinned header.
///
/// See also:
///
///  * [SliverClipRect], which clips a sliver with a rectangle.
///  * [ClipRRect], which clips a box widget with a rounded rectangle.
///  * [CustomClipper], for creating custom clips.
class SliverClipRRect extends SingleChildRenderObjectWidget {
  /// Creates a sliver that clips its child using a rounded rectangle.
  SliverClipRRect({
    super.key,
    required Widget sliver,
    this.borderRadius = BorderRadius.zero,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    this.clipOverlap = true,
  }) : super(
         child: SliverClipRect(
           clipOverlap: clipOverlap,
           clipBehavior: clipOverlap ? clipBehavior : Clip.none,
           sliver: sliver,
         ),
       );

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  final BorderRadiusGeometry borderRadius;

  /// If non-null, determines which clip to use.
  final CustomClipper<RRect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  final Clip clipBehavior;

  /// Whether to automatically clip the portion of the child that is overlapped
  /// by preceding pinned slivers.
  ///
  /// If true, the clip rect will be adjusted to exclude the area defined by
  /// [SliverConstraints.overlap].
  final bool clipOverlap;

  @override
  RenderSliverClipRRect createRenderObject(BuildContext context) {
    return RenderSliverClipRRect(
      borderRadius: borderRadius,
      clipper: clipper,
      clipBehavior: clipBehavior,
      clipOverlap: clipOverlap,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverClipRRect renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..clipOverlap = clipOverlap
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>('borderRadius', borderRadius, defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<CustomClipper<RRect>>('clipper', clipper, defaultValue: null),
    );
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.antiAlias));
    properties.add(DiagnosticsProperty<bool>('clipOverlap', clipOverlap, defaultValue: true));
  }
}

/// A sliver render object that clips its child using a rounded rectangle.
///
/// By default, [RenderSliverClipRRect] uses its own bounds as the base
/// rectangle for the clip, but the size and location of the clip can be
/// customized using a custom [clipper].
class RenderSliverClipRRect extends _RenderSliverCustomClip<RRect> {
  /// Creates a sliver render object for clipping with a rounded rectangle.
  RenderSliverClipRRect({
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
    super.clipper,
    super.clipBehavior = Clip.antiAlias,
    super.clipOverlap = true,
    TextDirection? textDirection,
  }) : _borderRadius = borderRadius,
       _textDirection = textDirection;

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  BorderRadiusGeometry get borderRadius => _borderRadius;
  BorderRadiusGeometry _borderRadius;
  set borderRadius(BorderRadiusGeometry value) {
    if (_borderRadius == value) {
      return;
    }
    _borderRadius = value;
    markNeedsPaint();
  }

  /// The text direction with which to resolve [borderRadius].
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
  }

  @override
  RRect buildClip() {
    final Rect maxPaintRect = getMaxPaintRect();

    RRect newClip =
        clipper?.getClip(maxPaintRect.size) ??
        borderRadius.resolve(textDirection).toRRect(maxPaintRect);

    if (clipOverlap && constraints.overlap > 0) {
      final double insideClipExtent = switch (constraints.axis) {
        Axis.horizontal => newClip.middleRect.width,
        Axis.vertical => newClip.middleRect.height,
      };
      final double clipOrigin = getClipOriginForOverlap(insideClipExtent);

      newClip = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => newClip.copyWith(top: clipOrigin),
        AxisDirection.up => newClip.copyWith(bottom: geometry!.paintExtent - clipOrigin),
        AxisDirection.right => newClip.copyWith(left: clipOrigin),
        AxisDirection.left => newClip.copyWith(right: geometry!.paintExtent - clipOrigin),
      };
    }

    return newClip;
  }

  @override
  bool clipContains(Offset offset, RRect clip) => clip.contains(offset);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !child!.geometry!.visible) {
      layer = null;
      return;
    }

    final RRect? clip = getClip();
    if (clip != null) {
      if (!clip.isEmpty) {
        layer = context.pushClipRRect(
          needsCompositing,
          offset,
          clip.outerRect,
          clip,
          (PaintingContext context, offset) => context.paintChild(child!, offset),
          clipBehavior: clipBehavior,
          oldLayer: layer as ClipRRectLayer?,
        );
      } else {
        layer = null;
      }
    } else {
      context.paintChild(child!, offset);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>('borderRadius', borderRadius, defaultValue: null),
    );
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

extension on RRect {
  RRect copyWith({double? left, double? top, double? right, double? bottom}) =>
      RRect.fromLTRBAndCorners(
        left ?? this.left,
        top ?? this.top,
        right ?? this.right,
        bottom ?? this.bottom,
        topLeft: tlRadius,
        topRight: trRadius,
        bottomLeft: blRadius,
        bottomRight: brRadius,
      );
}

abstract class _RenderSliverCustomClip<T> extends RenderProxySliver {
  _RenderSliverCustomClip({
    RenderSliver? sliver,
    CustomClipper<T>? clipper,
    Clip clipBehavior = Clip.antiAlias,
    bool clipOverlap = true,
  }) : _clipper = clipper,
       _clipBehavior = clipBehavior,
       _clipOverlap = clipOverlap,
       super(sliver);

  /// If non-null, determines which clip to use on the child.
  CustomClipper<T>? get clipper => _clipper;
  CustomClipper<T>? _clipper;
  set clipper(CustomClipper<T>? newClipper) {
    if (_clipper == newClipper) {
      return;
    }
    final CustomClipper<T>? oldClipper = _clipper;
    _clipper = newClipper;
    assert(newClipper != null || oldClipper != null);
    if (newClipper == null ||
        oldClipper == null ||
        newClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }
    if (attached) {
      oldClipper?.removeListener(_markNeedsClip);
      newClipper?.addListener(_markNeedsClip);
    }
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  /// Whether to clip starting from the overlap area.
  bool get clipOverlap => _clipOverlap;
  bool _clipOverlap;
  set clipOverlap(bool value) {
    if (_clipOverlap != value) {
      _clipOverlap = value;
      markNeedsPaint();
    }
  }

  T? _clip;
  @protected
  T buildClip();

  @protected
  T? getClip() {
    if (clipBehavior == Clip.none) {
      _clip = null;
    } else {
      _clip ??= buildClip();
    }

    return _clip;
  }

  bool clipContains(Offset offset, T clip);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper?.addListener(_markNeedsClip);
  }

  @override
  void detach() {
    _clipper?.removeListener(_markNeedsClip);
    super.detach();
  }

  void _markNeedsClip() {
    _clip = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    final SliverGeometry? oldGeometry = geometry;
    super.performLayout();
    if (oldGeometry != geometry) {
      _clip = null;
    }
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (clipOverlap && constraints.overlap > 0 && mainAxisPosition < constraints.overlap) {
      return false;
    }

    if (clipBehavior != Clip.none) {
      final Offset hitOffset = switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection,
        constraints.growthDirection,
      )) {
        AxisDirection.down => Offset(crossAxisPosition, mainAxisPosition),
        AxisDirection.right => Offset(mainAxisPosition, crossAxisPosition),
        AxisDirection.up => Offset(crossAxisPosition, geometry!.paintExtent - mainAxisPosition),
        AxisDirection.left => Offset(geometry!.paintExtent - mainAxisPosition, crossAxisPosition),
      };

      final T? clip = _clip;
      if (clip != null && !clipContains(hitOffset, clip)) {
        return false;
      }
    }

    return super.hitTest(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    return switch (clipBehavior) {
      Clip.none => null,
      Clip.hardEdge || Clip.antiAlias || Clip.antiAliasWithSaveLayer =>
        _clipper?.getApproximateClipRect(paintBounds.size) ?? Offset.zero & paintBounds.size,
    };
  }

  @protected
  double getClipOriginForOverlap(double clipExtent) =>
      constraints.overlap -
      math.max(
        constraints.scrollOffset +
            constraints.overlap +
            geometry!.maxScrollObstructionExtent -
            clipExtent,
        0.0,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<T>>('clipper', clipper, defaultValue: null));
    properties.add(DiagnosticsProperty<T?>('clip', _clip));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
    properties.add(DiagnosticsProperty<bool>('clipOverlap', clipOverlap, defaultValue: true));
  }
}
