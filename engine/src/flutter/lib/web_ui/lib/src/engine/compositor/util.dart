// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

js.JsObject makeSkRect(ui.Rect rect) {
  return js.JsObject(canvasKit['LTRBRect'],
      <double>[rect.left, rect.top, rect.right, rect.bottom]);
}

js.JsObject makeSkRRect(ui.RRect rrect) {
  return js.JsObject.jsify({
    'rect': makeSkRect(rrect.outerRect),
    'rx1': rrect.tlRadiusX,
    'ry1': rrect.tlRadiusY,
    'rx2': rrect.trRadiusX,
    'ry2': rrect.trRadiusY,
    'rx3': rrect.brRadiusX,
    'ry3': rrect.brRadiusY,
    'rx4': rrect.blRadiusX,
    'ry4': rrect.blRadiusY,
  });
}

ui.Rect fromSkRect(js.JsObject skRect) {
  return ui.Rect.fromLTRB(
    skRect['fLeft'],
    skRect['fTop'],
    skRect['fRight'],
    skRect['fBottom'],
  );
}

ui.TextPosition fromPositionWithAffinity(js.JsObject positionWithAffinity) {
  if (positionWithAffinity['affinity'] == canvasKit['Affinity']['Upstream']) {
    return ui.TextPosition(
      offset: positionWithAffinity['pos'],
      affinity: ui.TextAffinity.upstream,
    );
  } else {
    assert(positionWithAffinity['affinity'] ==
        canvasKit['Affinity']['Downstream']);
    return ui.TextPosition(
      offset: positionWithAffinity['pos'],
      affinity: ui.TextAffinity.downstream,
    );
  }
}

js.JsArray<double> makeSkPoint(ui.Offset point) {
  final js.JsArray<double> skPoint = js.JsArray<double>();
  skPoint.length = 2;
  skPoint[0] = point.dx;
  skPoint[1] = point.dy;
  return skPoint;
}

js.JsObject makeSkBlendMode(ui.BlendMode blendMode) {
  switch (blendMode) {
    case ui.BlendMode.clear:
      return canvasKit['BlendMode']['Clear'];
    case ui.BlendMode.src:
      return canvasKit['BlendMode']['Src'];
    case ui.BlendMode.dst:
      return canvasKit['BlendMode']['Dst'];
    case ui.BlendMode.srcOver:
      return canvasKit['BlendMode']['SrcOver'];
    case ui.BlendMode.dstOver:
      return canvasKit['BlendMode']['DstOver'];
    case ui.BlendMode.srcIn:
      return canvasKit['BlendMode']['SrcIn'];
    case ui.BlendMode.dstIn:
      return canvasKit['BlendMode']['DstIn'];
    case ui.BlendMode.srcOut:
      return canvasKit['BlendMode']['SrcOut'];
    case ui.BlendMode.dstOut:
      return canvasKit['BlendMode']['DstOut'];
    case ui.BlendMode.srcATop:
      return canvasKit['BlendMode']['SrcATop'];
    case ui.BlendMode.dstATop:
      return canvasKit['BlendMode']['DstATop'];
    case ui.BlendMode.xor:
      return canvasKit['BlendMode']['Xor'];
    case ui.BlendMode.plus:
      return canvasKit['BlendMode']['Plus'];
    case ui.BlendMode.modulate:
      return canvasKit['BlendMode']['Modulate'];
    case ui.BlendMode.screen:
      return canvasKit['BlendMode']['Screen'];
    case ui.BlendMode.overlay:
      return canvasKit['BlendMode']['Overlay'];
    case ui.BlendMode.darken:
      return canvasKit['BlendMode']['Darken'];
    case ui.BlendMode.lighten:
      return canvasKit['BlendMode']['Lighten'];
    case ui.BlendMode.colorDodge:
      return canvasKit['BlendMode']['ColorDodge'];
    case ui.BlendMode.colorBurn:
      return canvasKit['BlendMode']['ColorBurn'];
    case ui.BlendMode.hardLight:
      return canvasKit['BlendMode']['HardLight'];
    case ui.BlendMode.softLight:
      return canvasKit['BlendMode']['SoftLight'];
    case ui.BlendMode.difference:
      return canvasKit['BlendMode']['Difference'];
    case ui.BlendMode.exclusion:
      return canvasKit['BlendMode']['Exclusion'];
    case ui.BlendMode.multiply:
      return canvasKit['BlendMode']['Multiply'];
    case ui.BlendMode.hue:
      return canvasKit['BlendMode']['Hue'];
    case ui.BlendMode.saturation:
      return canvasKit['BlendMode']['Saturation'];
    case ui.BlendMode.color:
      return canvasKit['BlendMode']['Color'];
    case ui.BlendMode.luminosity:
      return canvasKit['BlendMode']['Luminosity'];
    default:
      return null;
  }
}

js.JsObject makeSkPaint(ui.Paint paint) {
  final dynamic skPaint = js.JsObject(canvasKit['SkPaint']);

  if (paint.shader != null) {
    final EngineGradient engineShader = paint.shader;
    skPaint.callMethod(
        'setShader', <js.JsObject>[engineShader.createSkiaShader()]);
  }

  if (paint.color != null) {
    skPaint.callMethod('setColor', <int>[paint.color.value]);
  }

  js.JsObject skPaintStyle;
  switch (paint.style) {
    case ui.PaintingStyle.stroke:
      skPaintStyle = canvasKit['PaintStyle']['Stroke'];
      break;
    case ui.PaintingStyle.fill:
      skPaintStyle = canvasKit['PaintStyle']['Fill'];
      break;
  }
  skPaint.callMethod('setStyle', <js.JsObject>[skPaintStyle]);

  js.JsObject skBlendMode = makeSkBlendMode(paint.blendMode);
  if (skBlendMode != null) {
    skPaint.callMethod('setBlendMode', <js.JsObject>[skBlendMode]);
  }

  skPaint.callMethod('setAntiAlias', <bool>[paint.isAntiAlias]);

  if (paint.strokeWidth != 0.0) {
    skPaint.callMethod('setStrokeWidth', <double>[paint.strokeWidth]);
  }

  if (paint.maskFilter != null) {
    final ui.BlurStyle blurStyle = paint.maskFilter.webOnlyBlurStyle;
    final double sigma = paint.maskFilter.webOnlySigma;

    js.JsObject skBlurStyle;
    switch (blurStyle) {
      case ui.BlurStyle.normal:
        skBlurStyle = canvasKit['BlurStyle']['Normal'];
        break;
      case ui.BlurStyle.solid:
        skBlurStyle = canvasKit['BlurStyle']['Solid'];
        break;
      case ui.BlurStyle.outer:
        skBlurStyle = canvasKit['BlurStyle']['Outer'];
        break;
      case ui.BlurStyle.inner:
        skBlurStyle = canvasKit['BlurStyle']['Inner'];
        break;
    }

    final js.JsObject skMaskFilter = canvasKit
        .callMethod('MakeBlurMaskFilter', <dynamic>[skBlurStyle, sigma, true]);
    skPaint.callMethod('setMaskFilter', <js.JsObject>[skMaskFilter]);
  }

  if (paint.imageFilter != null) {
    final SkImageFilter skImageFilter = paint.imageFilter;
    skPaint.callMethod(
        'setImageFilter', <js.JsObject>[skImageFilter.skImageFilter]);
  }

  if (paint.colorFilter != null) {
    EngineColorFilter engineFilter = paint.colorFilter;
    SkColorFilter skFilter = engineFilter._toSkColorFilter();
    skPaint.callMethod('setColorFilter', <js.JsObject>[skFilter.skColorFilter]);
  }

  return skPaint;
}

// Mappings from SkMatrix-index to input-index.
const List<int> _skMatrixIndexToMatrix4Index = <int>[
  0, 4, 12, // Row 1
  1, 5, 13, // Row 2
  3, 7, 15, // Row 3
];

/// Converts a 4x4 Flutter matrix (represented as a [Float64List]) to an
/// SkMatrix, which is a 3x3 transform matrix.
js.JsArray<double> makeSkMatrix(Float64List matrix4) {
  final js.JsArray<double> skMatrix = js.JsArray<double>();
  skMatrix.length = 9;
  for (int i = 0; i < 9; ++i) {
    final int matrix4Index = _skMatrixIndexToMatrix4Index[i];
    if (matrix4Index < matrix4.length)
      skMatrix[i] = matrix4[matrix4Index];
    else
      skMatrix[i] = 0.0;
  }
  return skMatrix;
}

/// Color stops used when the framework specifies `null`.
final js.JsArray<double> _kDefaultColorStops = () {
  final js.JsArray<double> jsColorStops = js.JsArray<double>();
  jsColorStops.length = 2;
  jsColorStops[0] = 0;
  jsColorStops[1] = 1;
  return jsColorStops;
}();

/// Converts a list of color stops into a Skia-compatible JS array or color stops.
///
/// In Flutter `null` means two color stops `[0, 1]` that in Skia must be specified explicitly.
js.JsArray<double> makeSkiaColorStops(List<double> colorStops) {
  if (colorStops == null) {
    return _kDefaultColorStops;
  }

  final js.JsArray<double> jsColorStops = js.JsArray<double>.from(colorStops);
  jsColorStops.length = colorStops.length;
  return jsColorStops;
}

// These must be kept in sync with `flow/layers/physical_shape_layer.cc`.
const double kLightHeight = 600.0;
const double kLightRadius = 800.0;

void drawSkShadow(
  js.JsObject skCanvas,
  SkPath path,
  ui.Color color,
  double elevation,
  bool transparentOccluder,
  double devicePixelRatio,
) {
  const double ambientAlpha = 0.039;
  const double spotAlpha = 0.25;

  final int flags = transparentOccluder ? 0x01 : 0x00;

  final ui.Rect bounds = path.getBounds();
  final double shadowX = (bounds.left + bounds.right) / 2.0;
  final double shadowY = bounds.top - 600.0;

  ui.Color inAmbient = color.withAlpha((color.alpha * ambientAlpha).round());
  ui.Color inSpot = color.withAlpha((color.alpha * spotAlpha).round());

  final js.JsObject inTonalColors = js.JsObject.jsify(<String, int>{
    'ambient': inAmbient.value,
    'spot': inSpot.value,
  });

  final js.JsObject tonalColors =
      canvasKit.callMethod('computeTonalColors', <js.JsObject>[inTonalColors]);

  skCanvas.callMethod('drawShadow', <dynamic>[
    path._skPath,
    js.JsArray<double>.from(<double>[0, 0, devicePixelRatio * elevation]),
    js.JsArray<double>.from(
        <double>[shadowX, shadowY, devicePixelRatio * kLightHeight]),
    devicePixelRatio * kLightRadius,
    tonalColors['ambient'],
    tonalColors['spot'],
    flags,
  ]);
}
