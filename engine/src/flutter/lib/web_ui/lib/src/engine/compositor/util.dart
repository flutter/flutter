// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// An error related to the CanvasKit rendering backend.
class CanvasKitError extends Error {
  CanvasKitError(this.message);

  /// Describes this error.
  final String message;

  @override
  String toString() => 'CanvasKitError: $message';
}

/// Converts a list of [ui.Color] into the 2d array expected by CanvasKit.
js.JsArray<Float32List> makeColorList(List<ui.Color> colors) {
  var result = js.JsArray<Float32List>();
  result.length = colors.length;
  for (var i = 0; i < colors.length; i++) {
    var color = colors[i];
    var jsColor = Float32List(4);
    jsColor[0] = color.red / 255.0;
    jsColor[1] = color.green / 255.0;
    jsColor[2] = color.blue / 255.0;
    jsColor[3] = color.alpha / 255.0;
    result[i] = jsColor;
  }
  return result;
}

js.JsObject _mallocColorArray() {
  return canvasKit
      .callMethod('Malloc', <dynamic>[js.context['Float32Array'], 4]);
}

js.JsObject? sharedSkColor1;
js.JsObject? sharedSkColor2;
js.JsObject? sharedSkColor3;

void _setSharedColor(js.JsObject sharedColor, ui.Color color) {
  Float32List array = sharedColor.callMethod('toTypedArray');
  array[0] = color.red / 255.0;
  array[1] = color.green / 255.0;
  array[2] = color.blue / 255.0;
  array[3] = color.alpha / 255.0;
}

void setSharedSkColor1(ui.Color color) {
  if (sharedSkColor1 == null) {
    sharedSkColor1 = _mallocColorArray();
  }
  _setSharedColor(sharedSkColor1!, color);
}

void setSharedSkColor2(ui.Color color) {
  if (sharedSkColor2 == null) {
    sharedSkColor2 = _mallocColorArray();
  }
  _setSharedColor(sharedSkColor2!, color);
}

void setSharedSkColor3(ui.Color color) {
  if (sharedSkColor3 == null) {
    sharedSkColor3 = _mallocColorArray();
  }
  _setSharedColor(sharedSkColor3!, color);
}

/// Creates a new color array.
Float32List makeFreshSkColor(ui.Color color) {
  final Float32List result = Float32List(4);
  result[0] = color.red / 255.0;
  result[1] = color.green / 255.0;
  result[2] = color.blue / 255.0;
  result[3] = color.alpha / 255.0;
  return result;
}

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

// TODO(hterkelsen): https://github.com/flutter/flutter/issues/58824
/// Creates a point list using a 2D JS array.
js.JsArray<js.JsArray<double>>? encodePointList(List<ui.Offset>? points) {
  if (points == null) {
    return null;
  }
  final int pointCount = points.length;
  final js.JsArray<js.JsArray<double>> result =
      js.JsArray<js.JsArray<double>>();
  result.length = pointCount;
  for (int i = 0; i < pointCount; ++i) {
    final ui.Offset point = points[i];
    assert(_offsetIsValid(point));
    final js.JsArray<double> skPoint = js.JsArray<double>();
    skPoint.length = 2;
    skPoint[0] = point.dx;
    skPoint[1] = point.dy;
    result[i] = skPoint;
  }
  return result;
}

// TODO(hterkelsen): https://github.com/flutter/flutter/issues/58824
/// Creates a point list using a 2D JS array.
List<List<double>>? encodeRawPointList(Float32List? points) {
  if (points == null) {
    return null;
  }
  assert(points.length % 2 == 0);
  var pointLength = points.length ~/ 2;
  final js.JsArray<js.JsArray<double>> result =
      js.JsArray<js.JsArray<double>>();
  result.length = pointLength;
  for (var i = 0; i < pointLength; i++) {
    var x = i * 2;
    var y = x + 1;
    final js.JsArray<double> skPoint = js.JsArray<double>();
    skPoint.length = 2;
    skPoint[0] = points[x];
    skPoint[1] = points[y];
    result[i] = skPoint;
  }
  return result;
}

js.JsObject? makeSkPointMode(ui.PointMode pointMode) {
  switch (pointMode) {
    case ui.PointMode.points:
      return canvasKit['PointMode']['Points'];
    case ui.PointMode.lines:
      return canvasKit['PointMode']['Lines'];
    case ui.PointMode.polygon:
      return canvasKit['PointMode']['Polygon'];
    default:
      throw StateError('Unrecognized point mode $pointMode');
  }
}

js.JsObject? makeSkBlendMode(ui.BlendMode? blendMode) {
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

// Mappings from SkMatrix-index to input-index.
const List<int> _skMatrixIndexToMatrix4Index = <int>[
  0, 4, 12, // Row 1
  1, 5, 13, // Row 2
  3, 7, 15, // Row 3
];

/// Converts a 4x4 Flutter matrix (represented as a [Float32List]) to an
/// SkMatrix, which is a 3x3 transform matrix.
js.JsArray<double> makeSkMatrixFromFloat32(Float32List? matrix4) {
  final js.JsArray<double> skMatrix = js.JsArray<double>();
  skMatrix.length = 9;
  for (int i = 0; i < 9; ++i) {
    final int matrix4Index = _skMatrixIndexToMatrix4Index[i];
    if (matrix4Index < matrix4!.length)
      skMatrix[i] = matrix4[matrix4Index];
    else
      skMatrix[i] = 0.0;
  }
  return skMatrix;
}

js.JsArray<double> makeSkMatrixFromFloat64(Float64List matrix4) {
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
js.JsArray<double> makeSkiaColorStops(List<double>? colorStops) {
  if (colorStops == null) {
    return _kDefaultColorStops;
  }

  final js.JsArray<double> jsColorStops = js.JsArray<double>.from(colorStops);
  jsColorStops.length = colorStops.length;
  return jsColorStops;
}

void drawSkShadow(
  js.JsObject skCanvas,
  CkPath path,
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

  final js.JsObject inTonalColors = js.JsObject.jsify(<String, Float32List>{
    'ambient': makeFreshSkColor(inAmbient),
    'spot': makeFreshSkColor(inSpot),
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
