// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'image_filter.dart';

/// A widget that replicates the native Android stretch overscroll effect.
///
/// This widget is used in the [StretchingOverscrollIndicator] widget and creates
/// a stretch visual feedback when the user overscrolls at the edges.
///
/// Only supported when using the Impeller rendering engine.
class StretchOverscrollEffect extends StatefulWidget {
  /// Creates a StretchOverscrollEffect widget that applies a stretch
  /// effect when the user overscrolls horizontally or vertically.
  const StretchOverscrollEffect({
    super.key,
    this.stretchStrengthX = 0.0,
    this.stretchStrengthY = 0.0,
    required this.child,
  }) : assert(
         stretchStrengthX >= -1.0 && stretchStrengthX <= 1.0,
         'stretchStrengthX must be between -1.0 and 1.0',
       ),
       assert(
         stretchStrengthY >= -1.0 && stretchStrengthY <= 1.0,
         'stretchStrengthY must be between -1.0 and 1.0',
       );

  /// The horizontal overscroll strength applied for the stretching effect.
  ///
  /// The value should be between -1.0 and 1.0 inclusive.
  /// Positive values apply a pull from left to right,
  /// while negative values pull from right to left.
  ///
  /// {@tool snippet}
  /// This example shows how to set the horizontal stretch strength to pull right.
  ///
  /// ```dart
  /// const StretchOverscrollEffect(
  ///   stretchStrengthX: 0.5,
  ///   child: Text('Hello, World!'),
  /// );
  /// ```
  /// {@end-tool}
  final double stretchStrengthX;

  /// The vertical overscroll strength applied for the stretching effect.
  ///
  /// The value should be between -1.0 and 1.0 inclusive.
  /// Positive values apply a pull from top to bottom,
  /// while negative values pull from bottom to top.
  ///
  /// {@tool snippet}
  /// This example shows how to set the vertical stretch strength to pull bottom.
  ///
  /// ```dart
  /// const StretchOverscrollEffect(
  ///   stretchStrengthY: 0.5,
  ///   child: Text('Hello, World!'),
  /// );
  /// ```
  /// {@end-tool}
  final double stretchStrengthY;

  /// The child widget that receives the stretching overscroll effect.
  final Widget child;

  @override
  State<StretchOverscrollEffect> createState() => _StretchOverscrollEffectState();
}

class _StretchOverscrollEffectState extends State<StretchOverscrollEffect> {
  ui.FragmentShader? _fragmentShader;

  /// The maximum scale multiplier applied during a stretch effect.
  static const double maxStretchIntensity = 1.0;

  /// The strength of the interpolation used for smoothing the effect.
  static const double interpolationStrength = 0.7;

  @override
  void dispose() {
    _fragmentShader?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _StretchOverscrollEffectShader.initializeShader();
  }

  @override
  Widget build(BuildContext context) {
    final bool isShaderNeeded =
        widget.stretchStrengthX.abs() > precisionErrorTolerance ||
        widget.stretchStrengthY.abs() > precisionErrorTolerance;

    final ui.ImageFilter imageFilter;

    if (_StretchOverscrollEffectShader._initialized) {
      _fragmentShader?.dispose();
      _fragmentShader = _StretchOverscrollEffectShader._program!.fragmentShader();
      _fragmentShader!.setFloat(2, maxStretchIntensity);
      _fragmentShader!.setFloat(3, widget.stretchStrengthX);
      _fragmentShader!.setFloat(4, widget.stretchStrengthY);
      _fragmentShader!.setFloat(5, interpolationStrength);

      imageFilter = ui.ImageFilter.shader(_fragmentShader!);
    } else {
      _fragmentShader?.dispose();
      _fragmentShader = null;

      imageFilter = kEmptyFilter;
    }

    return ImageFiltered(
      imageFilter: imageFilter,
      enabled: isShaderNeeded,
      // A nearly-transparent pixels is used to ensure the shader gets applied,
      // even when the child is visually transparent or has no paint operations.
      child: CustomPaint(
        painter: isShaderNeeded ? _StretchOverscrollEffectPainter() : null,
        child: widget.child,
      ),
    );
  }
}

/// A [CustomPainter] that draws nearly transparent pixels at the four corners.
///
/// This ensures the fragment shader covers the entire canvas by forcing
/// painting operations on all edges, preventing shader optimization skips.
class _StretchOverscrollEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
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

class _StretchOverscrollEffectShader {
  static bool _initCalled = false;
  static bool _initialized = false;
  static ui.FragmentProgram? _program;

  static void initializeShader() {
    if (!_initCalled) {
      ui.FragmentProgram.fromAsset('shaders/stretch_overscroll.frag').then((
        ui.FragmentProgram program,
      ) {
        _program = program;
        _initialized = true;
      });
      _initCalled = true;
    }
  }
}
