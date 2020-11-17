// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

abstract class CkShader extends ManagedSkiaObject<SkShader> implements ui.Shader {
  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}

class CkGradientSweep extends CkShader implements ui.Gradient {
  CkGradientSweep(this.center, this.colors, this.colorStops, this.tileMode,
      this.startAngle, this.endAngle, this.matrix4)
      : assert(_offsetIsValid(center)),
        assert(colors != null), // ignore: unnecessary_null_comparison
        assert(tileMode != null), // ignore: unnecessary_null_comparison
        assert(startAngle != null), // ignore: unnecessary_null_comparison
        assert(endAngle != null), // ignore: unnecessary_null_comparison
        assert(startAngle < endAngle),
        assert(matrix4 == null || _matrix4IsValid(matrix4)) {
    _validateColorStops(colors, colorStops);
  }

  final ui.Offset center;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final double startAngle;
  final double endAngle;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    return canvasKit.Shader.MakeSweepGradient(
      center.dx,
      center.dy,
      toSkFloatColorList(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
      0,
      startAngle,
      endAngle,
    );
  }

  @override
  SkShader resurrect() {
    return createDefault();
  }
}

class CkGradientLinear extends CkShader implements ui.Gradient {
  CkGradientLinear(
    this.from,
    this.to,
    this.colors,
    this.colorStops,
    this.tileMode,
    Float64List? matrix,
  )   : assert(_offsetIsValid(from)),
        assert(_offsetIsValid(to)),
        assert(colors != null), // ignore: unnecessary_null_comparison
        assert(tileMode != null), // ignore: unnecessary_null_comparison
        this.matrix4 = matrix == null ? null : _FastMatrix64(matrix) {
    if (assertionsEnabled) {
      _validateColorStops(colors, colorStops);
    }
  }

  final ui.Offset from;
  final ui.Offset to;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final _FastMatrix64? matrix4;

  @override
  SkShader createDefault() {
    assert(useCanvasKit);

    return canvasKit.Shader.MakeLinearGradient(
      toSkPoint(from),
      toSkPoint(to),
      toSkFloatColorList(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
    );
  }

  @override
  SkShader resurrect() => createDefault();
}

class CkGradientRadial extends CkShader implements ui.Gradient {
  CkGradientRadial(this.center, this.radius, this.colors, this.colorStops,
      this.tileMode, this.matrix4);

  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    assert(useCanvasKit);

    return canvasKit.Shader.MakeRadialGradient(
      toSkPoint(center),
      radius,
      toSkFloatColorList(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
      0,
    );
  }

  @override
  SkShader resurrect() => createDefault();
}

class CkGradientConical extends CkShader implements ui.Gradient {
  CkGradientConical(this.focal, this.focalRadius, this.center, this.radius,
      this.colors, this.colorStops, this.tileMode, this.matrix4);

  final ui.Offset focal;
  final double focalRadius;
  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  SkShader createDefault() {
    assert(useCanvasKit);
    return canvasKit.Shader.MakeTwoPointConicalGradient(
      toSkPoint(focal),
      focalRadius,
      toSkPoint(center),
      radius,
      toSkFloatColorList(colors),
      toSkColorStops(colorStops),
      toSkTileMode(tileMode),
      matrix4 != null ? toSkMatrixFromFloat32(matrix4!) : null,
      0,
    );
  }

  @override
  SkShader resurrect() => createDefault();
}

class CkImageShader extends CkShader implements ui.ImageShader {
  CkImageShader(
      ui.Image image, this.tileModeX, this.tileModeY, this.matrix4)
      : _image = image as CkImage;

  final ui.TileMode tileModeX;
  final ui.TileMode tileModeY;
  final Float64List matrix4;
  final CkImage _image;

  @override
  SkShader createDefault() => _image.skImage.makeShader(
    toSkTileMode(tileModeX),
    toSkTileMode(tileModeY),
    toSkMatrixFromFloat64(matrix4),
  );

  @override
  SkShader resurrect() => createDefault();

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}
