// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class SkPathMetrics extends IterableBase<ui.PathMetric>
    implements ui.PathMetrics {
  SkPathMetrics(SkPath path, bool forceClosed)
      : _iterator = SkPathMetricIterator._(_SkPathMeasure(path, forceClosed));

  final Iterator<ui.PathMetric> _iterator;

  @override
  Iterator<ui.PathMetric> get iterator => _iterator;
}

class SkPathMetricIterator implements Iterator<ui.PathMetric> {
  SkPathMetricIterator._(this._pathMeasure) : assert(_pathMeasure != null);

  _SkPathMetric _pathMetric;
  _SkPathMeasure _pathMeasure;

  @override
  ui.PathMetric get current => _pathMetric;

  @override
  bool moveNext() {
    if (_pathMeasure._nextContour()) {
      _pathMetric = _SkPathMetric._(_pathMeasure);
      return true;
    }
    _pathMetric = null;
    return false;
  }
}

class _SkPathMetric implements ui.PathMetric {
  _SkPathMetric._(this._measure)
      : assert(_measure != null),
        length = _measure.length(_measure.currentContourIndex),
        isClosed = _measure.isClosed(_measure.currentContourIndex),
        contourIndex = _measure.currentContourIndex;

  @override
  final double length;

  @override
  final bool isClosed;

  @override
  final int contourIndex;

  final _SkPathMeasure _measure;

  @override
  ui.Tangent getTangentForOffset(double distance) {
    return _measure.getTangentForOffset(contourIndex, distance);
  }

  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    return _measure.extractPath(contourIndex, start, end,
        startWithMoveTo: startWithMoveTo);
  }

  @override
  String toString() => 'PathMetric{length: $length, isClosed: $isClosed, '
      'contourIndex: $contourIndex}';
}

class _SkPathMeasure {
  _SkPathMeasure(SkPath path, bool forceClosed) {
    currentContourIndex = -1;
    pathMeasure = js.JsObject(canvasKit['SkPathMeasure'], <dynamic>[
      path._skPath,
      forceClosed,
      1,
    ]);
  }

  js.JsObject pathMeasure;

  double length(int contourIndex) {
    assert(contourIndex == currentContourIndex,
        'PathMetrics are invalid if it is not the current contour.');
    return pathMeasure.callMethod('getLength');
  }

  ui.Tangent getTangentForOffset(int contourIndex, double distance) {
    assert(contourIndex == currentContourIndex,
        'PathMetrics are invalid if it is not the current contour.');
    final js.JsObject posTan =
        pathMeasure.callMethod('getPosTan', <double>[distance]);
    return ui.Tangent(
      ui.Offset(posTan[0], posTan[1]),
      ui.Offset(posTan[2], posTan[3]),
    );
  }

  ui.Path extractPath(int contourIndex, double start, double end,
      {bool startWithMoveTo = true}) {
    assert(contourIndex == currentContourIndex,
        'PathMetrics are invalid if it is not the current contour.');
    final js.JsObject skPath = pathMeasure
        .callMethod('getSegment', <dynamic>[start, end, startWithMoveTo]);
    return SkPath._fromSkPath(skPath);
  }

  bool isClosed(int contourIndex) {
    assert(contourIndex == currentContourIndex,
        'PathMetrics are invalid if it is not the current contour.');
    return pathMeasure.callMethod('isClosed');
  }

  bool _nextContour() {
    final bool next = pathMeasure.callMethod('nextContour');
    if (next) {
      currentContourIndex++;
    }
    return next;
  }

  int currentContourIndex;
}
