// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'overscroll_indicator.dart';
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';

/// A widget that applies a stretching visual effect to its child.
///
/// When shader-based effects are supported, this effect replicates the native Android stretch overscroll effect.
/// Otherwise, a matrix transform provides an approximation.
///
/// Used by [StretchingOverscrollIndicator] widget.
class StretchEffect extends StatelessWidget {
  /// Creates a [StretchEffect] widget that applies a stretch effect
  /// when the user overscrolls horizontally or vertically.
  ///
  /// The [stretchStrength] controls the intensity of the stretch effect
  /// and must be between -1.0 and 1.0.
  const StretchEffect({
    super.key,
    this.stretchStrength = 0.0,
    required this.axis,
    required this.child,
  }) : assert(
         stretchStrength >= -1.0 && stretchStrength <= 1.0,
         'stretchStrength must be between -1.0 and 1.0',
       );

  /// The overscroll strength applied for the stretching effect.
  ///
  /// The value should be between -1.0 and 1.0 inclusive.
  ///
  /// For the horizontal axis:
  /// - Positive values apply a pull/stretch from left to right,
  ///   where 1.0 represents the maximum stretch to the right.
  /// - Negative values apply a pull/stretch from right to left,
  ///   where -1.0 represents the maximum stretch to the left.
  ///
  /// For the vertical axis:
  /// - Positive values apply a pull/stretch from top to bottom,
  ///   where 1.0 represents the maximum stretch downward.
  /// - Negative values apply a pull/stretch from bottom to top,
  ///   where -1.0 represents the maximum stretch upward.
  ///
  /// {@tool snippet}
  /// This example shows how to set the horizontal stretch strength to pull right.
  ///
  /// ```dart
  /// const StretchEffect(
  ///   stretchStrength: 0.5,
  ///   axis: Axis.horizontal,
  ///   child: Text('Hello, World!'),
  /// );
  /// ```
  /// {@end-tool}
  final double stretchStrength;

  /// The axis along which the stretching overscroll effect is applied.
  ///
  /// Determines the direction of the stretch, either horizontal or vertical.
  final Axis axis;

  /// The child widget that the stretching overscroll effect applies to.
  final Widget child;

  AlignmentGeometry _getAlignment(TextDirection direction) {
    final bool isForward = stretchStrength > 0;

    if (axis == Axis.vertical) {
      return isForward ? AlignmentDirectional.topCenter : AlignmentDirectional.bottomCenter;
    }

    // RTL horizontal.
    if (direction == TextDirection.rtl) {
      return isForward ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart;
    } else {
      return isForward ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ui.ImageFilter.isShaderFilterSupported) {
      return _StretchOverscrollEffect(stretchStrength: stretchStrength, axis: axis, child: child);
    }

    final TextDirection textDirection = Directionality.of(context);
    var x = 1.0;
    var y = 1.0;

    switch (axis) {
      case Axis.horizontal:
        x += stretchStrength.abs();
      case Axis.vertical:
        y += stretchStrength.abs();
    }

    return Transform(
      alignment: _getAlignment(textDirection),
      transform: Matrix4.diagonal3Values(x, y, 1.0),
      filterQuality: stretchStrength == 0 ? null : FilterQuality.medium,
      child: child,
    );
  }
}

/// A widget that replicates the native Android stretch overscroll effect.
///
/// This widget is used in the [StretchEffect] widget and creates
/// a stretch visual feedback when the user overscrolls at the edges.
///
/// Only supported when using the Impeller rendering engine.
class _StretchOverscrollEffect extends SingleChildRenderObjectWidget {
  /// Creates a [_StretchOverscrollEffect] widget that applies a stretch
  /// effect when the user overscrolls horizontally or vertically.
  const _StretchOverscrollEffect({
    this.stretchStrength = 0.0,
    required this.axis,
    required super.child,
  }) : assert(
         stretchStrength >= -1.0 && stretchStrength <= 1.0,
         'stretchStrength must be between -1.0 and 1.0',
       );

  /// The overscroll strength applied for the stretching effect.
  ///
  /// The value should be between -1.0 and 1.0 inclusive.
  /// For horizontal axis, positive values apply a pull from
  /// left to right, while negative values pull from right to left.
  final double stretchStrength;

  /// The axis along which the stretching overscroll effect is applied.
  ///
  /// Determines the direction of the stretch, either horizontal or vertical.
  final Axis axis;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderStretchOverscrollEffect(
      stretchStrength: stretchStrength,
      axis: axis,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderStretchOverscrollEffect)
      ..stretchStrength = stretchStrength
      ..axis = axis;
  }
}

class _RenderStretchOverscrollEffect extends RenderProxyBox {
  _RenderStretchOverscrollEffect({
    required double stretchStrength,
    required Axis axis,
  }) : _stretchStrength = stretchStrength,
       _axis = axis;

  /// The strength of the interpolation used for smoothing the effect.
  static const double interpolationStrength = 0.7;

  Size? _previousSize;

  bool get _isStretchNeeded => _stretchStrength.abs() > precisionErrorTolerance;

  double get stretchStrength => _stretchStrength;
  double _stretchStrength;
  set stretchStrength(double value) {
    if (value == _stretchStrength) {
      return;
    }
    final bool wasRepaintBoundary = isRepaintBoundary;
    _stretchStrength = value;
    if (isRepaintBoundary != wasRepaintBoundary) {
      markNeedsCompositingBitsUpdate();
      markNeedsPaint();
    } else if (_isStretchNeeded) {
      markNeedsCompositedLayerUpdate();
    }
  }

  Axis get axis => _axis;
  Axis _axis;
  set axis(Axis value) {
    if (value == _axis) {
      return;
    }
    _axis = value;
    if (_isStretchNeeded) {
      markNeedsCompositedLayerUpdate();
    }
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _isStretchNeeded;

  @override
  bool get isRepaintBoundary => alwaysNeedsCompositing;

  @override
  void performLayout() {
    super.performLayout();
    if (_previousSize != size) {
      _previousSize = size;
      if (_isStretchNeeded) {
        markNeedsCompositedLayerUpdate();
      }
    }
  }

  @override
  OffsetLayer updateCompositedLayer({required covariant ImageFilterLayer? oldLayer}) {
    final ImageFilterLayer layer = oldLayer ?? ImageFilterLayer();
    layer.imageFilter = ui.ImageFilter.stretch(
      overscrollX: _axis == Axis.horizontal ? _stretchStrength : 0.0,
      overscrollY: _axis == Axis.vertical ? _stretchStrength : 0.0,
      interpolationStrength: interpolationStrength,
      bounds: Offset.zero & size,
    );
    return layer;
  }
}
