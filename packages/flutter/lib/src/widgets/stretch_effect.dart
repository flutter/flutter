// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'image_filter.dart';
import 'layout_builder.dart';

/// A widget that applies a stretching visual effect to its child.
///
/// When shader-based effects are supported, this effect replicates the native Android stretch overscroll effect.
/// Otherwise, a capped translation along the scroll axis provides overscroll feedback without scaling the
/// child, which distorts text under Impeller. See https://github.com/flutter/flutter/issues/167795.
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

  /// Whether to use the fragment-shader based stretch effect.
  ///
  /// Disabled by default because applying [ImageFilter.shader] to scrollable
  /// content under Impeller causes text to jitter and stretch incorrectly.
  /// See https://github.com/flutter/flutter/issues/167795.
  @visibleForTesting
  static const bool useShaderStretchEffect = false;

  /// Maximum fraction of the main-axis extent used for transform-based overscroll
  /// feedback when the shader path is disabled.
  ///
  /// Scaling scrollable content (especially text) under Impeller distorts glyphs.
  /// See https://github.com/flutter/flutter/issues/167795.
  @visibleForTesting
  static const double maxTransformTranslationFraction = 0.12;

  Widget _buildTransformStretch() {
    if (stretchStrength.abs() <= precisionErrorTolerance) {
      return child;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double? mainExtent = switch (axis) {
          Axis.vertical =>
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null,
          Axis.horizontal =>
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null,
        };

        if (mainExtent == null || mainExtent <= 0) {
          return child;
        }

        final double translation =
            stretchStrength * mainExtent * maxTransformTranslationFraction;

        final Offset offset = switch (axis) {
          Axis.vertical => Offset(0.0, translation),
          Axis.horizontal => Offset(translation, 0.0),
        };

        return Transform.translate(
          offset: offset,
          filterQuality: FilterQuality.medium,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (useShaderStretchEffect && ui.ImageFilter.isShaderFilterSupported) {
      return _StretchOverscrollEffect(stretchStrength: stretchStrength, axis: axis, child: child);
    }

    return _buildTransformStretch();
  }
}

/// A widget that replicates the native Android stretch overscroll effect.
///
/// This widget is used in the [StretchEffect] widget and creates
/// a stretch visual feedback when the user overscrolls at the edges.
///
/// Only supported when using the Impeller rendering engine.
class _StretchOverscrollEffect extends StatefulWidget {
  /// Creates a [_StretchOverscrollEffect] widget that applies a stretch
  /// effect when the user overscrolls horizontally or vertically.
  const _StretchOverscrollEffect({
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
  /// For horizontal axis, Positive values apply a pull from
  /// left to right, while negative values pull from right to left.
  final double stretchStrength;

  /// The axis along which the stretching overscroll effect is applied.
  ///
  /// Determines the direction of the stretch, either horizontal or vertical.
  final Axis axis;

  /// The child widget that the stretching overscroll effect applies to.
  final Widget child;

  @override
  State<_StretchOverscrollEffect> createState() => _StretchOverscrollEffectState();
}

class _StretchOverscrollEffectState extends State<_StretchOverscrollEffect> {
  ui.FragmentShader? _fragmentShader;
  bool _fragmentShaderInitialized = false;
  ui.ImageFilter? _imageFilter;

  /// The maximum scale multiplier applied during a stretch effect.
  static const double maxStretchIntensity = 1.0;

  /// The strength of the interpolation used for smoothing the effect.
  static const double interpolationStrength = 0.7;

  /// A no-op [ui.ImageFilter] that uses the identity matrix.
  static final ui.ImageFilter _emptyFilter = ui.ImageFilter.matrix(Matrix4.identity().storage);

  @override
  void dispose() {
    _fragmentShader?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _StretchEffectShader.initializeShader();
  }

  void _updateFragmentShaderUniforms() {
    if (_fragmentShader == null) {
      return;
    }
    _fragmentShader!
      ..setFloat(2, maxStretchIntensity)
      ..setFloat(3, widget.axis == Axis.vertical ? 0.0 : widget.stretchStrength)
      ..setFloat(4, widget.axis == Axis.vertical ? widget.stretchStrength : 0.0)
      ..setFloat(5, interpolationStrength);
  }

  ui.ImageFilter _createImageFilter() {
    if (_StretchEffectShader._initialized && _fragmentShader != null) {
      return ui.ImageFilter.shader(_fragmentShader!);
    }
    return _emptyFilter;
  }

  @override
  Widget build(BuildContext context) {
    final bool isShaderNeeded = widget.stretchStrength.abs() > precisionErrorTolerance;

    if (_StretchEffectShader._initialized && !_fragmentShaderInitialized) {
      _fragmentShader = _StretchEffectShader._program!.fragmentShader();
      _fragmentShaderInitialized = true;
      _imageFilter = _createImageFilter();
    }

    if (_fragmentShaderInitialized) {
      _updateFragmentShaderUniforms();
      // ImageFilter.shader captures uniform values at creation time.
      _imageFilter = _createImageFilter();
    } else {
      _imageFilter = _emptyFilter;
    }

    return ImageFiltered(
      imageFilter: _imageFilter!,
      enabled: isShaderNeeded,
      // A nearly-transparent pixels is used to ensure the shader gets applied,
      // even when the child is visually transparent or has no paint operations.
      child: CustomPaint(
        painter: isShaderNeeded ? _StretchEffectPainter() : null,
        child: widget.child,
      ),
    );
  }
}

/// A [CustomPainter] that draws nearly transparent pixels at the four corners.
///
/// This ensures the fragment shader covers the entire canvas by forcing
/// painting operations on all edges, preventing shader optimization skips.
class _StretchEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(1, 0, 0, 0)
      ..style = PaintingStyle.fill;

    canvas.drawPoints(ui.PointMode.points, <Offset>[
      Offset.zero,
      Offset(size.width - 1, 0),
      Offset(0, size.height - 1),
      Offset(size.width - 1, size.height - 1),
    ], paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StretchEffectShader {
  static bool _initCalled = false;
  static bool _initialized = false;
  static ui.FragmentProgram? _program;

  static void initializeShader() {
    if (!_initCalled) {
      ui.FragmentProgram.fromAsset('shaders/stretch_effect.frag').then((
        ui.FragmentProgram program,
      ) {
        _program = program;
        _initialized = true;
      });
      _initCalled = true;
    }
  }
}
