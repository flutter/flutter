// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter/rendering.dart' show ClipOverlapBehavior;

/// A sliver that clips its child using a rectangle.
///
/// By default, it clips the child to its bounds. It can also clip based on a
/// custom [clipper].
///
/// This widget is particularly useful when used in a [CustomScrollView] with
/// pinned slivers (like [SliverAppBar] with [SliverAppBar.pinned] set to true).
///
/// {@template flutter.widgets.sliver_clip.SliverClipRect.clipOverlap}
/// When [clipOverlap] is `true` (the default), it automatically clips the portion
/// of the child that is overlapped by the pinned sliver, preventing the child
/// from being visible underneath a semi-transparent or translucent pinned header.
/// {@endtemplate}
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
  /// Creates a sliver that clips its child using a rectangle.
  ///
  /// If [clipper] is null, the clip will match the layout size and position of
  /// the child.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  ///
  /// {@macro flutter.widgets.sliver_clip.SliverClipRect.clipOverlap}
  const SliverClipRect({
    super.key,
    required Widget sliver,
    this.clipper,
    this.clipBehavior = .antiAlias,
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
      ..clipOverlap = clipOverlap ? .followEdge : .none;
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

/// A sliver that clips its child using a rounded rectangle.
///
/// By default, it clips the child to its bounds with the given [borderRadius].
/// It can also clip based on a custom [clipper].
///
/// This widget is particularly useful when used in a [CustomScrollView] with
/// pinned slivers (like [SliverAppBar] with [SliverAppBar.pinned] set to true).
///
/// {@template flutter.widgets.sliver_clip.SliverClipRRect.clipOverlap}
/// The [clipOverlap] parameter controls how the clip reacts to the area that
/// overlaps with a preceding pinned sliver:
///
///  * [ClipOverlapBehavior.followEdge] (default): the clip rectangle is
///    truncated at the overlap boundary.
///  * [ClipOverlapBehavior.preserveShape]: the entire rounded rectangle shifts
///    inward so that corners are never hidden by the overlap. This produces a
///    smoother visual when items scroll underneath a pinned header.
///  * [ClipOverlapBehavior.none]: the overlap is ignored and no additional
///    clipping is applied.
/// {@endtemplate}
///
/// {@tool snippet}
///
/// This example shows a [CustomScrollView] with a pinned [SliverAppBar] and a
/// [SliverClipRRect] wrapping a list. As items scroll behind the translucent
/// app bar, they are clipped with rounded corners that stay visible thanks to
/// [ClipOverlapBehavior.preserveShape].
///
/// ```dart
/// CustomScrollView(
///   slivers: <Widget>[
///     SliverAppBar(
///       pinned: true,
///       expandedHeight: 200.0,
///       backgroundColor: Colors.blue.withAlpha(128), // Semi-transparent
///       flexibleSpace: const FlexibleSpaceBar(
///         title: Text('SliverClipRRect'),
///       ),
///     ),
///     SliverClipRRect(
///       borderRadius: .circular(16.0),
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
///  * [SliverClipRect], which clips a sliver with a rectangle.
///  * [ClipRRect], which clips a box widget with a rounded rectangle.
///  * [ClipOverlapBehavior], which describes the available overlap-clipping
///    strategies.
///  * [CustomClipper], for creating custom clips.
class SliverClipRRect extends SingleChildRenderObjectWidget {
  /// Creates a sliver that clips its child using a rounded-rectangle.
  ///
  /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
  /// right-angled corners.
  ///
  /// If [clipper] is non-null, then [borderRadius] is ignored.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  ///
  /// {@macro flutter.widgets.sliver_clip.SliverClipRRect.clipOverlap}
  const SliverClipRRect({
    super.key,
    required Widget sliver,
    this.borderRadius = .zero,
    this.clipper,
    this.clipBehavior = .antiAlias,
    this.clipOverlap = .followEdge,
  }) : super(child: sliver);

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  final BorderRadiusGeometry borderRadius;

  /// If non-null, determines which clip to use instead of the default
  /// rounded rectangle derived from [borderRadius].
  ///
  /// When a clipper is provided, [borderRadius] is ignored.
  final CustomClipper<RRect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  final Clip clipBehavior;

  /// How the clip reacts to the area overlapped by preceding pinned slivers.
  ///
  /// When set to [ClipOverlapBehavior.followEdge] (the default), the clip
  /// rectangle is truncated at the overlap boundary defined by
  /// [SliverConstraints.overlap].
  ///
  /// When set to [ClipOverlapBehavior.preserveShape], the entire rounded
  /// rectangle is shifted inward so that corners remain fully visible,
  /// producing a smoother visual effect as items scroll under a pinned header.
  ///
  /// When set to [ClipOverlapBehavior.none], no overlap clipping is applied
  /// and content may render underneath translucent pinned slivers.
  ///
  /// See [ClipOverlapBehavior] for details on each mode.
  final ClipOverlapBehavior clipOverlap;

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
      DiagnosticsProperty<BorderRadiusGeometry>(
        'borderRadius',
        borderRadius,
        defaultValue: BorderRadius.zero,
      ),
    );
    properties.add(
      DiagnosticsProperty<CustomClipper<RRect>>('clipper', clipper, defaultValue: null),
    );
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.antiAlias));
    properties.add(
      EnumProperty<ClipOverlapBehavior>(
        'clipOverlap',
        clipOverlap,
        defaultValue: ClipOverlapBehavior.followEdge,
      ),
    );
  }
}
