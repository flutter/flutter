// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'basic.dart';
/// @docImport 'sliver.dart';
library;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// A widget that applies a transformation before painting its sliver child.
///
/// Unlike [Transform], which operates on boxes, this widget operates on slivers.
/// The transformation is applied just prior to painting, which means the
/// transformation is not taken into account when calculating the layout geometry
/// of the sliver.
///
/// The following video demonstrates how the box equivalent, [Transform], works:
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=9z_YNlRlWfA}
///
/// See also:
///
///  * [Transform], the box version of this widget.
///  * [RenderSliverTransform], the render object that implements the transformation.
class SliverTransform extends SingleChildRenderObjectWidget {
  /// Creates a widget that transforms its sliver child.
  const SliverTransform({
    super.key,
    required Matrix4 this.transform,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    this.filterQuality,
    Widget? sliver,
  }) : delegate = null,
       super(child: sliver);

  /// Creates a widget that dynamically computes its transformation matrix
  /// based on the sliver's constraints and geometry using a delegate.
  ///
  /// The [delegate] computes the transformation matrix during the paint and
  /// hit testing phases.
  ///
  /// See also:
  ///
  ///  * [SliverTransform], for static transformations with a predetermined matrix.
  ///  * [SliverTransformDelegate], for the delegate interface.
  const SliverTransform.custom({
    super.key,
    required SliverTransformDelegate this.delegate,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    this.filterQuality,
    Widget? sliver,
  }) : transform = null,
       super(child: sliver);

  /// Creates a widget that transforms its sliver child using a rotation around the
  /// center.
  ///
  /// The `angle` argument gives the rotation in clockwise radians.
  ///
  /// {@tool snippet}
  ///
  /// This example rotates a sliver child around its center:
  ///
  /// ```dart
  /// SliverTransform.rotate(
  ///   angle: 0.25,
  ///   sliver: const SliverToBoxAdapter(
  ///     child: Text('Rotated sliver'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [Transform.rotate], the box equivalent.
  SliverTransform.rotate({
    super.key,
    required double angle,
    this.origin,
    this.alignment = .center,
    this.transformHitTests = true,
    this.filterQuality,
    Widget? sliver,
  }) : transform = Transform.computeRotation(angle),
       delegate = null,
       super(child: sliver);

  /// Creates a widget that transforms its sliver child using a translation.
  ///
  /// The `offset` argument specifies the translation.
  ///
  /// {@tool snippet}
  ///
  /// This example shifts the sliver down by fifteen pixels:
  ///
  /// ```dart
  /// SliverTransform.translate(
  ///   offset: const Offset(0.0, 15.0),
  ///   sliver: const SliverToBoxAdapter(
  ///     child: Text('Translated sliver'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [Transform.translate], the box equivalent.
  SliverTransform.translate({
    super.key,
    required Offset offset,
    this.transformHitTests = true,
    this.filterQuality,
    Widget? sliver,
  }) : transform = Matrix4.translationValues(offset.dx, offset.dy, 0.0),
       origin = null,
       alignment = null,
       delegate = null,
       super(child: sliver);

  /// Creates a widget that scales its sliver child along the 2D plane.
  ///
  /// The `scaleX` argument provides the scalar by which to multiply the `x`
  /// axis, and the `scaleY` argument provides the scalar by which to multiply
  /// the `y` axis. Either may be omitted, in which case the scaling factor for
  /// that axis defaults to 1.0.
  ///
  /// For convenience, to scale the child uniformly, instead of providing
  /// `scaleX` and `scaleY`, the `scale` parameter may be used.
  ///
  /// At least one of `scale`, `scaleX`, and `scaleY` must be non-null. If
  /// `scale` is provided, the other two must be null; similarly, if it is not
  /// provided, one of the other two must be provided.
  ///
  /// The [alignment] controls the origin of the scale; by default, this is the
  /// center of the sliver.
  ///
  /// {@tool snippet}
  ///
  /// This example scales the sliver to 1.5 times its normal size:
  ///
  /// ```dart
  /// SliverTransform.scale(
  ///   scale: 1.5,
  ///   sliver: const SliverToBoxAdapter(
  ///     child: Text('Scaled sliver'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [Transform.scale], the box equivalent.
  SliverTransform.scale({
    super.key,
    double? scale,
    double? scaleX,
    double? scaleY,
    this.origin,
    this.alignment = .center,
    this.transformHitTests = true,
    this.filterQuality,
    Widget? sliver,
  }) : assert(
         !(scale == null && scaleX == null && scaleY == null),
         "At least one of 'scale', 'scaleX' and 'scaleY' is required to be non-null",
       ),
       assert(
         scale == null || (scaleX == null && scaleY == null),
         "If 'scale' is non-null then 'scaleX' and 'scaleY' must be left null",
       ),
       transform = Matrix4.diagonal3Values(scale ?? scaleX ?? 1.0, scale ?? scaleY ?? 1.0, 1.0),
       delegate = null,
       super(child: sliver);

  /// Creates a widget that mirrors its sliver child about the widget's center point.
  ///
  /// If `flipX` is true, the child widget will be flipped horizontally. Defaults to false.
  ///
  /// If `flipY` is true, the child widget will be flipped vertically. Defaults to false.
  ///
  /// If both are true, the child widget will be flipped both vertically and horizontally,
  /// equivalent to a 180 degree rotation.
  ///
  /// {@tool snippet}
  ///
  /// This example flips the sliver horizontally:
  ///
  /// ```dart
  /// SliverTransform.flip(
  ///   flipX: true,
  ///   sliver: const SliverToBoxAdapter(
  ///     child: Text('Flipped sliver'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [Transform.flip], the box equivalent.
  SliverTransform.flip({
    super.key,
    bool flipX = false,
    bool flipY = false,
    this.origin,
    this.transformHitTests = true,
    this.filterQuality,
    Widget? sliver,
  }) : alignment = .center,
       transform = Matrix4.diagonal3Values(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0, 1.0),
       delegate = null,
       super(child: sliver);

  /// The matrix to transform the child by during painting.
  ///
  /// Exactly one of [transform] and [delegate] must be specified.
  final Matrix4? transform;

  /// The delegate that controls the transformation matrix of the child.
  ///
  /// Exactly one of [transform] and [delegate] must be specified.
  final SliverTransformDelegate? delegate;

  /// The origin of the coordinate system in which to apply the matrix,
  /// described relative to the point given by [alignment].
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  ///
  /// The origin is resolved relative to the sliver's full paint bounds
  /// ([RenderSliver.getMaxPaintRect]), which corresponds to [SliverGeometry.maxPaintExtent]
  /// along the main axis and [SliverConstraints.crossAxisExtent] along the cross axis,
  /// accounting for [SliverConstraints.scrollOffset]. If the bounds are not finite,
  /// it falls back to [paintBounds].
  final Offset? origin;

  /// The alignment of the origin, relative to the size of the sliver.
  ///
  /// When this and [origin] are both null, the origin is the upper-left corner
  /// of this render object.
  /// The default for this field is null for some constructors,
  /// and [Alignment.center] for others.
  ///
  /// The alignment is resolved relative to the sliver's full paint bounds
  /// ([RenderSliver.getMaxPaintRect]), which corresponds to [SliverGeometry.maxPaintExtent]
  /// along the main axis and [SliverConstraints.crossAxisExtent] along the cross axis,
  /// accounting for [SliverConstraints.scrollOffset]. If the bounds are not finite,
  /// it falls back to [paintBounds].
  final AlignmentGeometry? alignment;

  /// Whether to transform registered hits into the child's resulting coordinate system.
  final bool transformHitTests;

  /// The filter quality with which to apply the transform as a bitmap operation.
  ///
  /// {@macro flutter.widgets.Transform.optional.FilterQuality}
  final FilterQuality? filterQuality;

  SliverTransformDelegate get _effectiveDelegate {
    assert(
      (transform == null) != (delegate == null),
      'Exactly one of transform or delegate must be specified.',
    );
    return delegate ?? .matrix(transform!);
  }

  @override
  RenderSliverTransform createRenderObject(BuildContext context) {
    return RenderSliverTransform(
      delegate: _effectiveDelegate,
      origin: origin,
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
      transformHitTests: transformHitTests,
      filterQuality: filterQuality,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverTransform renderObject) {
    assert(
      (transform == null) != (delegate == null),
      'Exactly one of transform or delegate must be specified.',
    );
    renderObject
      ..delegate = _effectiveDelegate
      ..origin = origin
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context)
      ..transformHitTests = transformHitTests
      ..filterQuality = filterQuality;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('transform matrix', transform, defaultValue: null));
    properties.add(
      DiagnosticsProperty<SliverTransformDelegate>('delegate', delegate, defaultValue: null),
    );
    properties.add(DiagnosticsProperty<Offset>('origin', origin, defaultValue: null));
    properties.add(
      DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null),
    );
    properties.add(
      FlagProperty(
        'transformHitTests',
        value: transformHitTests,
        ifTrue: 'transform hit tests enabled',
        ifFalse: 'transform hit tests disabled',
        defaultValue: true,
      ),
    );
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality, defaultValue: null));
  }
}
