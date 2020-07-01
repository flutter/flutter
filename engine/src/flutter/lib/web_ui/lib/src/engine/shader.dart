// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

bool _offsetIsValid(ui.Offset offset) {
  assert(offset != null, 'Offset argument was null.'); // ignore: unnecessary_null_comparison
  assert(!offset.dx.isNaN && !offset.dy.isNaN,
      'Offset argument contained a NaN value.');
  return true;
}

bool _matrix4IsValid(Float32List matrix4) {
  assert(matrix4 != null, 'Matrix4 argument was null.'); // ignore: unnecessary_null_comparison
  assert(matrix4.length == 16, 'Matrix4 must have 16 entries.');
  return true;
}

abstract class EngineShader {
  /// Create a shader for use in the Skia backend.
  js.JsObject? createSkiaShader();
}

abstract class EngineGradient implements ui.Gradient, EngineShader {
  /// Hidden constructor to prevent subclassing.
  EngineGradient._();

  /// Creates a fill style to be used in painting.
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx);

  List<dynamic> webOnlySerializeToCssPaint() {
    throw UnsupportedError('CSS paint not implemented for this shader type');
  }
}

class GradientSweep extends EngineGradient {
  GradientSweep(this.center, this.colors, this.colorStops, this.tileMode,
      this.startAngle, this.endAngle, this.matrix4)
      : assert(_offsetIsValid(center)),
        assert(colors != null), // ignore: unnecessary_null_comparison
        assert(tileMode != null), // ignore: unnecessary_null_comparison
        assert(startAngle != null), // ignore: unnecessary_null_comparison
        assert(endAngle != null), // ignore: unnecessary_null_comparison
        assert(startAngle < endAngle),
        assert(matrix4 == null || _matrix4IsValid(matrix4)),
        super._() {
    _validateColorStops(colors, colorStops);
  }

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx) {
    throw UnimplementedError();
  }

  final ui.Offset center;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final double startAngle;
  final double endAngle;
  final Float32List? matrix4;

  @override
  js.JsObject createSkiaShader() {
    throw UnimplementedError();
  }
}

void _validateColorStops(List<ui.Color> colors, List<double>? colorStops) {
  if (colorStops == null) {
    if (colors.length != 2)
      throw ArgumentError(
          '"colors" must have length 2 if "colorStops" is omitted.');
  } else {
    if (colors.length != colorStops.length)
      throw ArgumentError(
          '"colors" and "colorStops" arguments must have equal length.');
  }
}

class GradientLinear extends EngineGradient {
  GradientLinear(
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
        this.matrix4 = matrix == null ? null : _FastMatrix64(matrix),
        super._() {
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
  html.CanvasGradient createPaintStyle(html.CanvasRenderingContext2D? ctx) {
    _FastMatrix64? matrix4 = this.matrix4;
    html.CanvasGradient gradient;
    if (matrix4 != null) {
      final centerX = (from.dx + to.dx) / 2.0;
      final centerY = (from.dy + to.dy) / 2.0;
      matrix4.transform(from.dx - centerX, from.dy - centerY);
      final double fromX = matrix4.transformedX + centerX;
      final double fromY = matrix4.transformedY + centerY;
      matrix4.transform(to.dx - centerX, to.dy - centerY);
      gradient = ctx!.createLinearGradient(fromX, fromY,
          matrix4.transformedX + centerX, matrix4.transformedY + centerY);
    } else {
      gradient = ctx!.createLinearGradient(from.dx, from.dy, to.dx, to.dy);
    }

    final List<double>? colorStops = this.colorStops;
    if (colorStops == null) {
      assert(colors.length == 2);
      gradient.addColorStop(0, colorToCssString(colors[0])!);
      gradient.addColorStop(1, colorToCssString(colors[1])!);
      return gradient;
    }
    for (int i = 0; i < colors.length; i++) {
      gradient.addColorStop(colorStops[i], colorToCssString(colors[i])!);
    }
    return gradient;
  }

  @override
  List<dynamic> webOnlySerializeToCssPaint() {
    final List<dynamic> serializedColors = <dynamic>[];
    for (int i = 0; i < colors.length; i++) {
      serializedColors.add(colorToCssString(colors[i]));
    }
    return <dynamic>[
      1,
      from.dx,
      from.dy,
      to.dx,
      to.dy,
      serializedColors,
      colorStops,
      tileMode.index
    ];
  }

  @override
  js.JsObject? createSkiaShader() {
    assert(experimentalUseSkia);

    var jsColors = makeColorList(colors);

    return canvasKit['SkShader'].callMethod('MakeLinearGradient', <dynamic>[
      makeSkPoint(from),
      makeSkPoint(to),
      jsColors,
      makeSkiaColorStops(colorStops),
      tileMode.index,
    ]);
  }
}

// TODO(flutter_web): For transforms and tile modes implement as webgl
// For now only GradientRotation is supported in flutter which is implemented
// for linear gradient.
// See https://github.com/flutter/flutter/issues/32819
class GradientRadial extends EngineGradient {
  GradientRadial(this.center, this.radius, this.colors, this.colorStops,
      this.tileMode, this.matrix4)
      : super._();

  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx) {
    if (!experimentalUseSkia) {
      if (tileMode != ui.TileMode.clamp) {
        throw UnimplementedError(
            'TileMode not supported in GradientRadial shader');
      }
    }
    final html.CanvasGradient gradient = ctx!.createRadialGradient(
        center.dx, center.dy, 0, center.dx, center.dy, radius);
    final List<double>? colorStops = this.colorStops;
    if (colorStops == null) {
      assert(colors.length == 2);
      gradient.addColorStop(0, colorToCssString(colors[0])!);
      gradient.addColorStop(1, colorToCssString(colors[1])!);
      return gradient;
    } else {
      for (int i = 0; i < colors.length; i++) {
        gradient.addColorStop(colorStops[i], colorToCssString(colors[i])!);
      }
    }
    return gradient;
  }

  @override
  js.JsObject? createSkiaShader() {
    assert(experimentalUseSkia);

    var jsColors = makeColorList(colors);

    return canvasKit['SkShader'].callMethod('MakeRadialGradient', <dynamic>[
      makeSkPoint(center),
      radius,
      jsColors,
      makeSkiaColorStops(colorStops),
      tileMode.index,
      matrix4 != null ? makeSkMatrixFromFloat32(matrix4) : null,
      0,
    ]);
  }
}

class GradientConical extends EngineGradient {
  GradientConical(this.focal, this.focalRadius, this.center, this.radius,
      this.colors, this.colorStops, this.tileMode, this.matrix4)
      : super._();

  final ui.Offset focal;
  final double focalRadius;
  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double>? colorStops;
  final ui.TileMode tileMode;
  final Float32List? matrix4;

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D? ctx) {
    throw UnimplementedError();
  }

  @override
  js.JsObject? createSkiaShader() {
    assert(experimentalUseSkia);

    var jsColors = makeColorList(colors);

    return canvasKit['SkShader']
        .callMethod('MakeTwoPointConicalGradient', <dynamic>[
      makeSkPoint(focal),
      focalRadius,
      makeSkPoint(center),
      radius,
      jsColors,
      makeSkiaColorStops(colorStops),
      tileMode.index,
      matrix4 != null ? makeSkMatrixFromFloat32(matrix4) : null,
      0,
    ]);
  }
}

/// Backend implementation of [ui.ImageFilter].
///
/// Currently only `blur` is supported.
class EngineImageFilter implements ui.ImageFilter {
  EngineImageFilter.blur({this.sigmaX = 0.0, this.sigmaY = 0.0});

  final double sigmaX;
  final double sigmaY;

  @override
  bool operator ==(Object other) {
    return other is EngineImageFilter
        && other.sigmaX == sigmaX
        && other.sigmaY == sigmaY;
  }

  @override
  int get hashCode => ui.hashValues(sigmaX, sigmaY);

  @override
  String toString() {
    return 'ImageFilter.blur($sigmaX, $sigmaY)';
  }
}

js.JsObject? _skTileMode(ui.TileMode tileMode) {
  switch (tileMode) {
    case ui.TileMode.clamp:
      return canvasKit['TileMode']['Clamp'];
    case ui.TileMode.repeated:
      return canvasKit['TileMode']['Repeat'];
    case ui.TileMode.mirror:
    default:
      return canvasKit['TileMode']['Mirror'];
  }
}

/// Backend implementation of [ui.ImageShader].
class EngineImageShader implements ui.ImageShader, EngineShader {
  EngineImageShader(
      ui.Image image, this.tileModeX, this.tileModeY, this.matrix4)
      : _skImage = image as CkImage;

  final ui.TileMode tileModeX;
  final ui.TileMode tileModeY;
  final Float64List matrix4;
  final CkImage _skImage;

  js.JsObject? createSkiaShader() => _skImage.skImage!.callMethod(
      'makeShader', <dynamic>[_skTileMode(tileModeX), _skTileMode(tileModeY)]);
}
