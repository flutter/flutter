// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

bool _offsetIsValid(ui.Offset offset) {
  assert(offset != null, 'Offset argument was null.');
  assert(!offset.dx.isNaN && !offset.dy.isNaN,
      'Offset argument contained a NaN value.');
  return true;
}

bool _matrix4IsValid(Float64List matrix4) {
  assert(matrix4 != null, 'Matrix4 argument was null.');
  assert(matrix4.length == 16, 'Matrix4 must have 16 entries.');
  return true;
}

abstract class EngineGradient implements ui.Gradient {
  /// Hidden constructor to prevent subclassing.
  EngineGradient._();

  /// Creates a fill style to be used in painting.
  Object createPaintStyle(html.CanvasRenderingContext2D ctx);

  List<dynamic> webOnlySerializeToCssPaint() {
    throw UnsupportedError('CSS paint not implemented for this shader type');
  }

  /// Create a shader for use in the Skia backend.
  js.JsObject createSkiaShader();
}

class GradientSweep extends EngineGradient {
  GradientSweep(this.center, this.colors, this.colorStops, this.tileMode,
      this.startAngle, this.endAngle, this.matrix4)
      : assert(_offsetIsValid(center)),
        assert(colors != null),
        assert(tileMode != null),
        assert(startAngle != null),
        assert(endAngle != null),
        assert(startAngle < endAngle),
        assert(matrix4 == null || _matrix4IsValid(matrix4)),
        super._() {
    _validateColorStops(colors, colorStops);
  }

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D ctx) {
    throw UnimplementedError();
  }

  final ui.Offset center;
  final List<ui.Color> colors;
  final List<double> colorStops;
  final ui.TileMode tileMode;
  final double startAngle;
  final double endAngle;
  final Float64List matrix4;

  @override
  js.JsObject createSkiaShader() {
    throw UnimplementedError();
  }
}

void _validateColorStops(List<ui.Color> colors, List<double> colorStops) {
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
  )   : assert(_offsetIsValid(from)),
        assert(_offsetIsValid(to)),
        assert(colors != null),
        assert(tileMode != null),
        super._() {
    _validateColorStops(colors, colorStops);
  }

  final ui.Offset from;
  final ui.Offset to;
  final List<ui.Color> colors;
  final List<double> colorStops;
  final ui.TileMode tileMode;

  @override
  html.CanvasGradient createPaintStyle(html.CanvasRenderingContext2D ctx) {
    final html.CanvasGradient gradient =
        ctx.createLinearGradient(from.dx, from.dy, to.dx, to.dy);
    if (colorStops == null) {
      assert(colors.length == 2);
      gradient.addColorStop(0, colors[0].toCssString());
      gradient.addColorStop(1, colors[1].toCssString());
      return gradient;
    }
    for (int i = 0; i < colors.length; i++) {
      gradient.addColorStop(colorStops[i], colors[i].toCssString());
    }
    return gradient;
  }

  @override
  List<dynamic> webOnlySerializeToCssPaint() {
    final List<dynamic> serializedColors = <dynamic>[];
    for (int i = 0; i < colors.length; i++) {
      serializedColors.add(colors[i].toCssString());
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
  js.JsObject createSkiaShader() {
    assert(experimentalUseSkia);

    final js.JsArray<num> jsColors = js.JsArray<num>();
    jsColors.length = colors.length;
    for (int i = 0; i < colors.length; i++) {
      jsColors[i] = colors[i].value;
    }

    js.JsArray<double> jsColorStops;
    if (colorStops == null) {
      jsColorStops = js.JsArray<double>();
      jsColorStops.length = 2;
      jsColorStops[0] = 0;
      jsColorStops[1] = 1;
    } else {
      jsColorStops = js.JsArray<double>.from(colorStops);
      jsColorStops.length = colorStops.length;
    }
    return canvasKit.callMethod('MakeLinearGradientShader', <dynamic>[
      makeSkPoint(from),
      makeSkPoint(to),
      jsColors,
      jsColorStops,
      tileMode.index,
    ]);
  }
}

class GradientRadial extends EngineGradient {
  GradientRadial(this.center, this.radius, this.colors, this.colorStops,
      this.tileMode, this.matrix4)
      : super._();

  final ui.Offset center;
  final double radius;
  final List<ui.Color> colors;
  final List<double> colorStops;
  final ui.TileMode tileMode;
  final Float64List matrix4;

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D ctx) {
    throw UnimplementedError();
  }

  @override
  js.JsObject createSkiaShader() {
    throw UnimplementedError();
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
  final List<double> colorStops;
  final ui.TileMode tileMode;
  final Float64List matrix4;

  @override
  Object createPaintStyle(html.CanvasRenderingContext2D ctx) {
    throw UnimplementedError();
  }

  @override
  js.JsObject createSkiaShader() {
    throw UnimplementedError();
  }
}
