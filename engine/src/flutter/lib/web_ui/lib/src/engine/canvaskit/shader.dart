// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../backend/shader.dart';
import '../vector_math.dart';
import 'canvaskit_api.dart';
import 'image.dart';

/// Refines the generic [ui.Shader] interface with CanvasKit-specific features.
abstract class CkShader implements BackendShader {
  /// Returns a Skia shader.
  SkShader get skShader;
}

class CkGradient extends BackendGradient implements CkShader {
  CkGradient.linear(
    Float32List endPoints,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ) {
    _skShader = canvasKit.Shader.MakeLinearGradient(
      Float32List.fromList(<double>[endPoints[0], endPoints[1]]),
      Float32List.fromList(<double>[endPoints[2], endPoints[3]]),
      colors,
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4) : null,
    );
  }

  CkGradient.radial(
    double centerX,
    double centerY,
    double radius,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ) {
    _skShader = canvasKit.Shader.MakeRadialGradient(
      Float32List.fromList(<double>[centerX, centerY]),
      radius,
      colors,
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4) : null,
      0,
    );
  }

  CkGradient.conical(
    double startX,
    double startY,
    double startRadius,
    double endX,
    double endY,
    double endRadius,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    Float32List? matrix4,
  ) {
    _skShader = canvasKit.Shader.MakeTwoPointConicalGradient(
      toSkPoint(ui.Offset(startX, startY)),
      startRadius,
      toSkPoint(ui.Offset(endX, endY)),
      endRadius,
      colors,
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4) : null,
      0,
    );
  }

  CkGradient.sweep(
    double centerX,
    double centerY,
    Uint32List colors,
    Float32List? colorStops,
    ui.TileMode tileMode,
    double startAngle,
    double endAngle,
    Float32List? matrix4,
  ) {
    _skShader = canvasKit.Shader.MakeSweepGradient(
      centerX,
      centerY,
      colors,
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4) : null,
      0,
      ui.toDegrees(startAngle),
      ui.toDegrees(endAngle),
    );
  }

  SkShader? _skShader;

  @override
  SkShader get skShader => _skShader!;

  bool get debugDisposed => _skShader == null;

  @override
  void dispose() {
    _skShader?.delete();
    _skShader = null;
  }
}

/// Implements [ui.ImageShader] for CanvasKit.
class CkImageShader extends BackendImageShader implements CkShader {
  CkImageShader(
    this._image,
    this.tileModeX,
    this.tileModeY,
    Float64List? matrix4,
    this.filterQuality,
  ) {
    this.matrix4 = matrix4 ?? Matrix4.identity().toFloat64();
    _initializeSkImageShader(filterQuality);
  }

  final ui.TileMode tileModeX;
  final ui.TileMode tileModeY;
  late Float64List matrix4;
  final ui.FilterQuality filterQuality;
  final CkImageDelegate _image;

  SkShader? _skShader;

  int get imageWidth => _image.width;

  int get imageHeight => _image.height;

  @override
  SkShader get skShader {
    assert(!debugDisposed, 'Cannot get the skShader of a disposed ImageShader.');
    return _skShader!;
  }

  void _initializeSkImageShader(ui.FilterQuality quality) {
    final SkImage skImage = _image.skImage;
    if (quality == ui.FilterQuality.high) {
      _skShader = skImage.makeShaderCubic(
        toSkTileMode(tileModeX),
        toSkTileMode(tileModeY),
        1.0 / 3.0,
        1.0 / 3.0,
        toSkMatrixFromFloat64(matrix4),
      );
    } else {
      _skShader = skImage.makeShaderOptions(
        toSkTileMode(tileModeX),
        toSkTileMode(tileModeY),
        toSkFilterMode(quality),
        toSkMipmapMode(quality),
        toSkMatrixFromFloat64(matrix4),
      );
    }
  }

  bool _isDisposed = false;

  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _isDisposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('debugDisposed is only available when asserts are enabled.');
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _skShader?.delete();
    _skShader = null;
  }
}
