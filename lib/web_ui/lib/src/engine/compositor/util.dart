// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// An object backed by a [js.JsObject] mapped onto a Skia C++ object in the
/// WebAssembly heap.
///
/// These objects are automatically deleted when no longer used.
///
/// Because there is no feedback from JavaScript's GC (no destructors or
/// finalizers), we pessimistically delete the underlying C++ object before
/// the Dart object is garbage-collected. The current algorithm deletes objects
/// at the end of every frame. This allows reusing the C++ objects within the
/// frame. In the future we may add smarter strategies that will allow us to
/// reuse C++ objects across frames.
///
/// The lifecycle of a C++ object is as follows:
///
/// - Create default: when instantiating a C++ object for a Dart object for the
///   first time, the C++ object is populated with default data (the defaults are
///   defined by Flutter; Skia defaults are corrected if necessary). The
///   default object is created by [createDefault].
/// - Zero or more cycles of delete + resurrect: when a Dart object is reused
///   after its C++ object is deleted we create a new C++ object populated with
///   data from the current state of the Dart object. This is done using the
///   [resurrect] method.
/// - Final delete: if a Dart object is never reused, it is GC'd after its
///   underlying C++ object is deleted. This is implemented by [SkiaObjects].
abstract class SkiaObject {
  SkiaObject() {
    _skiaObject = createDefault();
    SkiaObjects.manage(this);
  }

  /// The JavaScript object that's mapped onto a Skia C++ object in the WebAssembly heap.
  js.JsObject get skiaObject {
    if (_skiaObject == null) {
      _skiaObject = resurrect();
      SkiaObjects.manage(this);
    }
    return _skiaObject;
  }

  /// Do not use this field outside this class. Use [skiaObject] instead.
  js.JsObject _skiaObject;

  /// Instantiates a new Skia-backed JavaScript object containing default
  /// values.
  ///
  /// The object is expected to represent Flutter's defaults. If Skia uses
  /// different defaults from those used by Flutter, this method is expected
  /// initialize the object to Flutter's defaults.
  js.JsObject createDefault();

  /// Creates a new Skia-backed JavaScript object containing data representing
  /// the current state of the Dart object.
  js.JsObject resurrect();
}

/// Singleton that manages the lifecycles of [SkiaObject] instances.
class SkiaObjects {
  // TODO(yjbanov): some sort of LRU strategy would allow us to reuse objects
  //                beyond a single frame.
  @visibleForTesting
  static final List<SkiaObject> managedObjects = () {
    window.rasterizer.addPostFrameCallback(postFrameCleanUp);
    return <SkiaObject>[];
  }();

  /// Starts managing the lifecycle of [object].
  ///
  /// The object's underlying WASM object is deleted by calling the
  /// "delete" method when it goes out of scope.
  ///
  /// The current implementation deletes objects at the end of every frame.
  static void manage(SkiaObject object) {
    managedObjects.add(object);
  }

  /// Deletes all C++ objects created this frame.
  static void postFrameCleanUp() {
    if (managedObjects.isEmpty) {
      return;
    }

    for (int i = 0; i < managedObjects.length; i++) {
      final SkiaObject object = managedObjects[i];
      object._skiaObject.callMethod('delete');
      object._skiaObject = null;
    }

    managedObjects.clear();
  }
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

/// Creates a point list using a typed buffer created by CanvasKit.Malloc.
Float32List encodePointList(List<ui.Offset> points) {
  assert(points != null);
  final int pointCount = points.length;
  final Float32List result = canvasKit.callMethod('Malloc', <dynamic>[js.context['Float32Array'], pointCount * 2]);
  for (int i = 0; i < pointCount; ++i) {
    final int xIndex = i * 2;
    final int yIndex = xIndex + 1;
    final ui.Offset point = points[i];
    assert(_offsetIsValid(point));
    result[xIndex] = point.dx;
    result[yIndex] = point.dy;
  }
  return result;
}

js.JsObject makeSkPointMode(ui.PointMode pointMode) {
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

// Mappings from SkMatrix-index to input-index.
const List<int> _skMatrixIndexToMatrix4Index = <int>[
  0, 4, 12, // Row 1
  1, 5, 13, // Row 2
  3, 7, 15, // Row 3
];

/// Converts a 4x4 Flutter matrix (represented as a [Float32List]) to an
/// SkMatrix, which is a 3x3 transform matrix.
js.JsArray<double> makeSkMatrixFromFloat32(Float32List matrix4) {
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
js.JsArray<double> makeSkiaColorStops(List<double> colorStops) {
  if (colorStops == null) {
    return _kDefaultColorStops;
  }

  final js.JsArray<double> jsColorStops = js.JsArray<double>.from(colorStops);
  jsColorStops.length = colorStops.length;
  return jsColorStops;
}

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
