// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

js.JsObject makeSkRect(ui.Rect rect) {
  return js.JsObject(canvasKit['LTRBRect'],
      <double>[rect.left, rect.top, rect.right, rect.bottom]);
}

js.JsArray<double> makeSkPoint(ui.Offset point) {
  final js.JsArray<double> skPoint = js.JsArray<double>();
  skPoint.length = 2;
  skPoint[0] = point.dx;
  skPoint[1] = point.dy;
  return skPoint;
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

  js.JsObject skBlendMode;
  switch (paint.blendMode) {
    case ui.BlendMode.clear:
      skBlendMode = canvasKit['BlendMode']['Clear'];
      break;

    case ui.BlendMode.src:
      skBlendMode = canvasKit['BlendMode']['Src'];
      break;

    case ui.BlendMode.dst:
      skBlendMode = canvasKit['BlendMode']['Dst'];
      break;

    case ui.BlendMode.srcOver:
      skBlendMode = canvasKit['BlendMode']['SrcOver'];
      break;

    case ui.BlendMode.dstOver:
      skBlendMode = canvasKit['BlendMode']['DstOver'];
      break;

    case ui.BlendMode.srcIn:
      skBlendMode = canvasKit['BlendMode']['SrcIn'];
      break;

    case ui.BlendMode.dstIn:
      skBlendMode = canvasKit['BlendMode']['DstIn'];
      break;

    case ui.BlendMode.srcOut:
      skBlendMode = canvasKit['BlendMode']['SrcOut'];
      break;

    case ui.BlendMode.dstOut:
      skBlendMode = canvasKit['BlendMode']['DstOut'];
      break;

    case ui.BlendMode.srcATop:
      skBlendMode = canvasKit['BlendMode']['SrcATop'];
      break;

    case ui.BlendMode.dstATop:
      skBlendMode = canvasKit['BlendMode']['DstATop'];
      break;

    case ui.BlendMode.xor:
      skBlendMode = canvasKit['BlendMode']['Xor'];
      break;

    case ui.BlendMode.plus:
      skBlendMode = canvasKit['BlendMode']['Plus'];
      break;

    case ui.BlendMode.modulate:
      skBlendMode = canvasKit['BlendMode']['Modulate'];
      break;

    case ui.BlendMode.screen:
      skBlendMode = canvasKit['BlendMode']['Screen'];
      break;

    case ui.BlendMode.overlay:
      skBlendMode = canvasKit['BlendMode']['Overlay'];
      break;

    case ui.BlendMode.darken:
      skBlendMode = canvasKit['BlendMode']['Darken'];
      break;

    case ui.BlendMode.lighten:
      skBlendMode = canvasKit['BlendMode']['Lighten'];
      break;

    case ui.BlendMode.colorDodge:
      skBlendMode = canvasKit['BlendMode']['ColorDodge'];
      break;

    case ui.BlendMode.colorBurn:
      skBlendMode = canvasKit['BlendMode']['ColorBurn'];
      break;

    case ui.BlendMode.hardLight:
      skBlendMode = canvasKit['BlendMode']['HardLight'];
      break;

    case ui.BlendMode.softLight:
      skBlendMode = canvasKit['BlendMode']['SoftLight'];
      break;

    case ui.BlendMode.difference:
      skBlendMode = canvasKit['BlendMode']['Difference'];
      break;

    case ui.BlendMode.exclusion:
      skBlendMode = canvasKit['BlendMode']['Exclusion'];
      break;

    case ui.BlendMode.multiply:
      skBlendMode = canvasKit['BlendMode']['Multiply'];
      break;

    case ui.BlendMode.hue:
      skBlendMode = canvasKit['BlendMode']['Hue'];
      break;

    case ui.BlendMode.saturation:
      skBlendMode = canvasKit['BlendMode']['Saturation'];
      break;

    case ui.BlendMode.color:
      skBlendMode = canvasKit['BlendMode']['Color'];
      break;

    case ui.BlendMode.luminosity:
      skBlendMode = canvasKit['BlendMode']['Luminosity'];
      break;
  }
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

void drawSkShadow(
  js.JsObject skCanvas,
  SkPath path,
  ui.Color color,
  double elevation,
  bool transparentOccluder,
) {
  const double ambientAlpha = 0.039;
  const double spotAlpha = 0.25;

  final int flags = transparentOccluder ? 0x01 : 0x00;

  final ui.Rect bounds = path.getBounds();
  final double shadowX = (bounds.left + bounds.right) / 2.0;
  final double shadowY = bounds.top - 600.0;

  final ui.Color ambientColor =
      ui.Color.fromARGB((color.alpha * ambientAlpha).round(), 0, 0, 0);

  // This is a port of SkShadowUtils::ComputeTonalColors
  final int minSpot = math.min(color.red, math.min(color.green, color.blue));
  final int maxSpot = math.max(color.red, math.max(color.green, color.blue));
  final double luminance = 0.5 * (maxSpot + minSpot) / 255.0;
  final double originalAlpha = (color.alpha * spotAlpha) / 255.0;
  final double alphaAdjust =
      (2.6 + (-2.66667 + 1.06667 * originalAlpha) * originalAlpha) *
          originalAlpha;
  double colorAlpha =
      (3.544762 + (-4.891428 + 2.3466 * luminance) * luminance) * luminance;
  colorAlpha = (colorAlpha * alphaAdjust).clamp(0.0, 1.0);

  final double greyscaleAlpha =
      (originalAlpha * (1.0 - 0.4 * luminance)).clamp(0.0, 1.0);

  final double colorScale = colorAlpha * (1.0 - greyscaleAlpha);
  final double tonalAlpha = colorScale + greyscaleAlpha;
  final double unPremulScale = colorScale / tonalAlpha;

  final ui.Color spotColor = ui.Color.fromARGB(
    (tonalAlpha * 255.999).round(),
    (unPremulScale * color.red).round(),
    (unPremulScale * color.green).round(),
    (unPremulScale * color.blue).round(),
  );

  skCanvas.callMethod('drawShadow', <dynamic>[
    path._skPath,
    js.JsArray<double>.from(<double>[0, 0, elevation]),
    js.JsArray<double>.from(<double>[shadowX, shadowY, 600]),
    800,
    ambientColor.value,
    spotColor.value,
    flags,
  ]);
}
