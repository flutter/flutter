// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class SkPathMetrics extends IterableBase<ui.PathMetric>
    implements ui.PathMetrics {
  SkPathMetrics(this._path, this._forceClosed);

  final SkPath _path;
  final bool _forceClosed;

  /// The [SkPath.isEmpty] case is special-cased to avoid booting the WASM machinery just to find out there are no contours.
  @override
  Iterator<ui.PathMetric> get iterator => _path.isEmpty ? const SkPathMetricIteratorEmpty._() : SkContourMeasureIter(_path, _forceClosed);
}

class SkContourMeasureIter implements Iterator<ui.PathMetric> {
  /// Cached constructor function for `SkContourMeasureIter`, so we don't have to look it
  /// up every time we're constructing a new instance.
  static final js.JsFunction _skContourMeasureIterConstructor = canvasKit['SkContourMeasureIter'];

  SkContourMeasureIter(SkPath path, bool forceClosed)
    : _skObject = js.JsObject(_skContourMeasureIterConstructor, <dynamic>[
        path._skPath,
        forceClosed,
        1,
      ]);

  /// The JavaScript `SkContourMeasureIter` object.
  final js.JsObject _skObject;

  /// A monotonically increasing counter used to generate [ui.PathMetric.contourIndex].
  ///
  /// CanvasKit does not supply the contour index. We have to add it ourselves.
  int _contourIndexCounter = 0;

  @override
  ui.PathMetric get current => _current;
  SkContourMeasure _current;

  @override
  bool moveNext() {
    final js.JsObject skContourMeasure = _skObject.callMethod('next');
    if (skContourMeasure == null) {
      _current = null;
      return false;
    }

    _current = SkContourMeasure(_contourIndexCounter, skContourMeasure);
    _contourIndexCounter += 1;
    return true;
  }
}

class SkContourMeasure implements ui.PathMetric {
  SkContourMeasure(this.contourIndex, this._skObject);

  final js.JsObject _skObject;

  @override
  final int contourIndex;

  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    final js.JsObject skPath = _skObject
        .callMethod('getSegment', <dynamic>[start, end, startWithMoveTo]);
    return SkPath._fromSkPath(skPath);
  }

  @override
  ui.Tangent getTangentForOffset(double distance) {
    final js.JsObject posTan = _skObject.callMethod('getPosTan', <double>[distance]);
    return ui.Tangent(
      ui.Offset(posTan[0], posTan[1]),
      ui.Offset(posTan[2], posTan[3]),
    );
  }

  @override
  bool get isClosed {
    return _skObject.callMethod('isClosed');
  }

  @override
  double get length {
    return _skObject.callMethod('length');
  }
}

class SkPathMetricIteratorEmpty implements Iterator<ui.PathMetric> {
  const SkPathMetricIteratorEmpty._();

  @override
  ui.PathMetric get current => null;

  @override
  bool moveNext() {
    return false;
  }
}
