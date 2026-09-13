// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'proxy_box.dart';
library;

import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'layer.dart';
import 'object.dart';
import 'proxy_sliver.dart';
import 'sliver.dart';

/// Signature for dynamically computing a transformation matrix
/// based on the sliver's constraints and geometry.
///
/// If this returns null, no transformation is applied.
///
/// Used by [SliverTransformDelegate.callback].
typedef SliverTransformCallback = Matrix4? Function(
  SliverConstraints constraints,
  SliverGeometry geometry,
);

/// A delegate that controls the transformation matrix for a [RenderSliverTransform].
///
/// Subclasses can override [computeTransform] to dynamically calculate a
/// transformation matrix based on the sliver's [SliverConstraints] and [SliverGeometry].
///
/// The transform will update whenever [repaint] notifies its listeners, or
/// when the sliver's constraints or geometry change during scrolling.
///
/// See also:
///
///  * [SliverTransform.custom], the widget that uses this delegate.
///  * [RenderSliverTransform], the render object that uses this delegate.
@immutable
abstract class SliverTransformDelegate {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  ///
  /// The [semanticsUpdate] object notifies when the semantics tree should be
  /// updated. If [semanticsUpdate] is null, then [repaint] will be used instead.
  /// To avoid triggering semantics updates on every [repaint] notification
  /// (for example during a continuous 60/120 Hz animation), an inactive or
  /// dummy [Listenable] can be passed to [semanticsUpdate].
  const SliverTransformDelegate({this._repaint, this._semanticsUpdate});

  /// Creates a delegate that computes the transformation matrix using a callback.
  ///
  /// The [callback] will be called during the paint and hit testing phases to
  /// compute the transformation matrix.
  ///
  /// The [semanticsUpdate] object notifies when the semantics tree should be
  /// updated. If [semanticsUpdate] is null, then [repaint] will be used instead.
  /// To avoid triggering semantics updates on every [repaint] notification
  /// (for example during a continuous 60/120 Hz animation), an inactive or
  /// dummy [Listenable] can be passed to [semanticsUpdate].
  ///
  /// For better performance and maintainability, consider subclassing
  /// [SliverTransformDelegate] and implementing [computeTransform] and
  /// [shouldRepaint] directly.
  const factory SliverTransformDelegate.callback(
    SliverTransformCallback callback, {
    Listenable? repaint,
    Listenable? semanticsUpdate,
  }) = _SliverTransformCallbackDelegate;

  /// Creates a delegate that always provides a predetermined transformation matrix.
  ///
  /// For transformations that dynamically change based on scrolling or constraints,
  /// use [SliverTransformDelegate.callback] or create a subclass of [SliverTransformDelegate].
  const factory SliverTransformDelegate.matrix(Matrix4 transform) = _FixedSliverTransformDelegate;

  final Listenable? _repaint;
  final Listenable? _semanticsUpdate;

  Listenable? get _effectiveSemanticsUpdate => _semanticsUpdate ?? _repaint;

  /// Computes the transformation matrix for the given constraints and geometry.
  ///
  /// The [constraints] describe the sliver's layout constraints, and [geometry]
  /// describes the sliver's layout geometry.
  ///
  /// If this returns null, no transformation is applied.
  ///
  /// This method is called during the paint and hit testing phases. It must not
  /// mutate any state or trigger layout or paint.
  Matrix4? computeTransform(SliverConstraints constraints, SliverGeometry geometry);

  /// Called whenever a new instance of the delegate is provided to the
  /// [RenderSliverTransform] object to determine whether the transformation
  /// needs to be updated.
  ///
  /// If the new instance represents different information than the old instance,
  /// this method should return true, otherwise it should return false.
  bool shouldRepaint(covariant SliverTransformDelegate oldDelegate);

  @override
  String toString() => objectRuntimeType(this, 'SliverTransformDelegate');
}

@immutable
class _SliverTransformCallbackDelegate extends SliverTransformDelegate {
  const _SliverTransformCallbackDelegate(this.callback, {super.repaint, super.semanticsUpdate});

  /// The callback that builds the transformation matrix.
  final SliverTransformCallback callback;

  @override
  Matrix4? computeTransform(SliverConstraints constraints, SliverGeometry geometry) {
    return callback(constraints, geometry);
  }

  @override
  bool shouldRepaint(covariant _SliverTransformCallbackDelegate oldDelegate) {
    return oldDelegate.callback != callback;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _SliverTransformCallbackDelegate &&
          other.callback == callback &&
          other._repaint == _repaint &&
          other._semanticsUpdate == _semanticsUpdate);

  @override
  int get hashCode => Object.hash(callback, _repaint, _semanticsUpdate);

  @override
  String toString() => '${objectRuntimeType(this, '_SliverTransformCallbackDelegate')}($callback)';
}

@immutable
class _FixedSliverTransformDelegate extends SliverTransformDelegate {
  const _FixedSliverTransformDelegate(this.transform);

  /// The fixed transformation matrix.
  final Matrix4 transform;

  @override
  Matrix4? computeTransform(SliverConstraints constraints, SliverGeometry geometry) {
    return transform;
  }

  @override
  bool shouldRepaint(covariant _FixedSliverTransformDelegate oldDelegate) {
    return oldDelegate.transform != transform;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FixedSliverTransformDelegate && other.transform == transform);

  @override
  int get hashCode => transform.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, '_FixedSliverTransformDelegate')}($transform)';
}

/// Applies a transformation before painting its sliver child.
///
/// See also:
///
///  * [SliverTransform], the widget that corresponds to this render object.
///  * [RenderTransform], the equivalent render object for boxes.
class RenderSliverTransform extends RenderProxySliver with RenderSliverHelpers {
  /// Creates a render object that transforms its sliver child.
  RenderSliverTransform({
    required this._delegate,
    Offset? origin,
    AlignmentGeometry? alignment,
    TextDirection? textDirection,
    this.transformHitTests = true,
    FilterQuality? filterQuality,
    RenderSliver? sliver,
  }) : super(sliver) {
    this.origin = origin;
    this.alignment = alignment;
    this.textDirection = textDirection;
    this.filterQuality = filterQuality;
  }

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  ///
  /// The origin is resolved relative to the sliver's full paint bounds
  /// ([getMaxPaintRect]), which corresponds to [SliverGeometry.maxPaintExtent]
  /// along the main axis and [SliverConstraints.crossAxisExtent] along the cross axis,
  /// accounting for [SliverConstraints.scrollOffset]. If the bounds are not finite,
  /// it falls back to [paintBounds].
  Offset? get origin => _origin;
  Offset? _origin;
  set origin(Offset? value) {
    if (_origin == value) {
      return;
    }
    _origin = value;
    _invalidateEffectiveTransform();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The alignment of the origin, relative to the size of the sliver.
  ///
  /// This is equivalent to setting an origin based on the size of the sliver.
  /// If it is specified at the same time as an offset, both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [textDirection] is
  /// [TextDirection.ltr], and `1.0` if [textDirection] is [TextDirection.rtl].
  /// Similarly [AlignmentDirectional.centerEnd] is the same as an [Alignment]
  /// whose [Alignment.x] value is `1.0` if [textDirection] is
  /// [TextDirection.ltr], and `-1.0` if [textDirection] is [TextDirection.rtl].
  ///
  /// The alignment is resolved relative to the sliver's full paint bounds
  /// ([getMaxPaintRect]), which corresponds to [SliverGeometry.maxPaintExtent]
  /// along the main axis and [SliverConstraints.crossAxisExtent] along the cross axis,
  /// accounting for [SliverConstraints.scrollOffset]. If the bounds are not finite,
  /// it falls back to [paintBounds].
  AlignmentGeometry? get alignment => _alignment;
  AlignmentGeometry? _alignment;
  set alignment(AlignmentGeometry? value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    _invalidateEffectiveTransform();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The text direction with which to resolve [alignment].
  ///
  /// This may be changed to null, but only after [alignment] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _invalidateEffectiveTransform();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Matrix4? _cachedEffectiveTransform;
  bool _hasEffectiveTransform = false;

  void _invalidateEffectiveTransform() {
    _cachedEffectiveTransform = null;
    _hasEffectiveTransform = false;
  }

  void _handleRepaint() {
    _invalidateEffectiveTransform();
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _filterQuality != null;

  @override
  void performLayout() {
    _invalidateEffectiveTransform();
    super.performLayout();
  }

  /// When set to true, hit tests are performed based on the position of the
  /// child as it is painted. When set to false, hit tests are performed
  /// ignoring the transformation.
  ///
  /// [applyPaintTransform], and therefore [localToGlobal] and [globalToLocal],
  /// always honor the transformation, regardless of the value of this property.
  bool transformHitTests;

  /// The delegate that controls the transformation matrix of the child.
  SliverTransformDelegate get delegate => _delegate;
  SliverTransformDelegate _delegate;
  set delegate(SliverTransformDelegate newDelegate) {
    if (_delegate == newDelegate) {
      return;
    }
    final SliverTransformDelegate oldDelegate = _delegate;
    _delegate = newDelegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType ||
        newDelegate.shouldRepaint(oldDelegate)) {
      _invalidateEffectiveTransform();
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
    if (attached) {
      if (newDelegate._repaint != oldDelegate._repaint) {
        oldDelegate._repaint?.removeListener(_handleRepaint);
        newDelegate._repaint?.addListener(_handleRepaint);
      }

      if (newDelegate._effectiveSemanticsUpdate != oldDelegate._effectiveSemanticsUpdate) {
        oldDelegate._effectiveSemanticsUpdate?.removeListener(markNeedsSemanticsUpdate);
        newDelegate._effectiveSemanticsUpdate?.addListener(markNeedsSemanticsUpdate);
      }
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate._repaint?.addListener(_handleRepaint);
    _delegate._effectiveSemanticsUpdate?.addListener(markNeedsSemanticsUpdate);
  }

  @override
  void detach() {
    _delegate._repaint?.removeListener(_handleRepaint);
    _delegate._effectiveSemanticsUpdate?.removeListener(markNeedsSemanticsUpdate);
    super.detach();
  }

  /// The filter quality with which to apply the transform as a bitmap operation.
  ///
  /// {@macro flutter.widgets.Transform.optional.FilterQuality}
  FilterQuality? get filterQuality => _filterQuality;
  FilterQuality? _filterQuality;
  set filterQuality(FilterQuality? value) {
    if (_filterQuality == value) {
      return;
    }
    final bool didNeedCompositing = alwaysNeedsCompositing;
    _filterQuality = value;
    if (didNeedCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
  }

  Matrix4? get _effectiveTransform {
    if (!_hasEffectiveTransform) {
      _cachedEffectiveTransform = _computeEffectiveTransform();
      _hasEffectiveTransform = true;
    }
    return _cachedEffectiveTransform;
  }

  Matrix4? _computeEffectiveTransform() {
    final Matrix4? rawTransform = geometry != null
        ? delegate.computeTransform(constraints, geometry!)
        : null;
    if (rawTransform == null) {
      return null;
    }
    Rect maxPaintRect = getMaxPaintRect();
    if (!maxPaintRect.isFinite) {
      maxPaintRect = paintBounds;
    }

    return MatrixUtils.computeEffectiveTransform(
      transform: rawTransform,
      size: maxPaintRect.size,
      origin: (_origin ?? .zero) + maxPaintRect.topLeft,
      alignment: _alignment,
      textDirection: _textDirection,
    );
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    // RenderSliverTransform objects don't check if they are themselves hit,
    // because it's confusing to think about how the untransformed size and the
    // child's transformed position interact.
    return hitTestChildren(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (child == null || geometry == null || geometry!.hitTestExtent <= 0.0) {
      return false;
    }
    final Matrix4? transform = _effectiveTransform;
    if (!transformHitTests || transform == null) {
      return child!.hitTest(
        result,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      );
    }
    final Matrix4? inverse = Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
    if (inverse == null) {
      // Objects are not visible on screen and cannot be hit-tested.
      return false;
    }
    final bool rightWayUp = isRightWayUp(constraints);
    final Offset point = switch (constraints.axis) {
      .horizontal => Offset(
        rightWayUp ? mainAxisPosition : geometry!.paintExtent - mainAxisPosition,
        crossAxisPosition,
      ),
      .vertical => Offset(
        crossAxisPosition,
        rightWayUp ? mainAxisPosition : geometry!.paintExtent - mainAxisPosition,
      ),
    };
    final Offset transformedPoint = MatrixUtils.transformPoint(inverse, point);
    final double childMainAxisPosition;
    final double childCrossAxisPosition;
    switch (constraints.axis) {
      case .horizontal:
        childMainAxisPosition = rightWayUp
            ? transformedPoint.dx
            : geometry!.paintExtent - transformedPoint.dx;
        childCrossAxisPosition = transformedPoint.dy;
      case .vertical:
        childMainAxisPosition = rightWayUp
            ? transformedPoint.dy
            : geometry!.paintExtent - transformedPoint.dy;
        childCrossAxisPosition = transformedPoint.dx;
    }
    return result.addWithOutOfBandPosition(
      rawTransform: inverse,
      hitTest: (SliverHitTestResult result) {
        return child!.hitTest(
          result,
          mainAxisPosition: childMainAxisPosition,
          crossAxisPosition: childCrossAxisPosition,
        );
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child!.geometry!.visible) {
      final Matrix4? transform = _effectiveTransform;
      if (transform == null) {
        super.paint(context, offset);
        layer = null;
        return;
      }
      if (filterQuality == null) {
        final Offset? childOffset = MatrixUtils.getAsTranslation(transform);
        if (childOffset == null) {
          // if the matrix is singular the children would be compressed to a line or
          // single point, instead short-circuit and paint nothing.
          final double det = transform.determinant();
          if (det == 0 || !det.isFinite) {
            layer = null;
            return;
          }
          layer = context.pushTransform(
            needsCompositing,
            offset,
            transform,
            super.paint,
            oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
          );
        } else {
          super.paint(context, offset + childOffset);
          layer = null;
        }
      } else {
        final effectiveTransform = Matrix4.translationValues(offset.dx, offset.dy, 0.0)
          ..multiply(transform)
          ..translateByDouble(-offset.dx, -offset.dy, 0, 1);
        final filter = ui.ImageFilter.matrix(
          effectiveTransform.storage,
          filterQuality: filterQuality!,
        );
        if (layer case final ImageFilterLayer filterLayer) {
          filterLayer.imageFilter = filter;
        } else {
          layer = ImageFilterLayer(imageFilter: filter);
        }
        context.pushLayer(layer!, super.paint, offset);
        assert(() {
          layer!.debugCreator = debugCreator;
          return true;
        }());
      }
    } else {
      layer = null;
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    if (_effectiveTransform != null) {
      transform.multiply(_effectiveTransform!);
    }
    super.applyPaintTransform(child, transform);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverTransformDelegate>('delegate', delegate));
    properties.add(DiagnosticsProperty<Offset>('origin', origin, defaultValue: null));
    properties.add(
      DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null),
    );
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
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
