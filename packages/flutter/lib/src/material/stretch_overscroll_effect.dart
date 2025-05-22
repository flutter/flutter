// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Implements the Android native overscroll effect identically in Flutter.
///
/// This widget only supported with Impeller rendering engine.
class StretchOverscrollEffect extends StatefulWidget {
  /// Creates a StretchOverscrollEffect widget that applies a stretch
  /// effect when the user overscrolls horizontally or vertically.
  const StretchOverscrollEffect({
    super.key,
    this.overscrollX = 0.0,
    this.overscrollY = 0.0,
    required this.child,
  });

  /// The horizontal overscroll amount applied for stretching effect,
  /// and value should be between -1 and 1 inclusive.
  final double overscrollX;

  /// The vertical overscroll amount applied for stretching effect,
  /// and value should be between -1 and 1 inclusive.
  final double overscrollY;

  /// The child widget that receives the stretching overscroll effect.
  final Widget child;

  @override
  State<StretchOverscrollEffect> createState() => _StretchOverscrollEffectState();
}

class _StretchOverscrollEffectState extends State<StretchOverscrollEffect> {
  ui.FragmentShader? _fragmentShader;

  @override
  void dispose() {
    _fragmentShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isShaderNeeded =
        widget.overscrollX.abs() > precisionErrorTolerance ||
        widget.overscrollY.abs() > precisionErrorTolerance;

    final ui.ImageFilter imageFilter;

    if (_StretchOverscrollEffectShader._initialized) {
      _fragmentShader?.dispose();
      _fragmentShader = _StretchOverscrollEffectShader._program!.fragmentShader();
      _fragmentShader!.setFloat(2, 1.0);
      _fragmentShader!.setFloat(3, widget.overscrollX);
      _fragmentShader!.setFloat(4, widget.overscrollY);
      _fragmentShader!.setFloat(5, 0.7);

      imageFilter = ui.ImageFilter.shader(_fragmentShader!);
    } else {
      if (!_StretchOverscrollEffectShader._initCalled) {
        _StretchOverscrollEffectShader.initializeShader();
      } else {
        _fragmentShader?.dispose();
        _fragmentShader = null;
      }

      imageFilter = ui.ImageFilter.matrix(Matrix4.identity().storage);
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

/// CustomPainter that draws nearly transparent pixels at the four corners.
///
/// This ensures the fragment shader covers the entire canvas by forcing
/// painting operations on all edges, preventing shader optimization skips.
class _StretchOverscrollEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = const Color.fromRGBO(0, 0, 0, 0.00000003)
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
