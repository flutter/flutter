// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class CkPathMetrics extends IterableBase<ui.PathMetric>
    implements ui.PathMetrics {
  CkPathMetrics(this._path, this._forceClosed);

  final CkPath _path;
  final bool _forceClosed;

  /// The [CkPath.isEmpty] case is special-cased to avoid booting the WASM machinery just to find out there are no contours.
  @override
  Iterator<ui.PathMetric> get iterator => _path.isEmpty! ? const CkPathMetricIteratorEmpty._() : CkContourMeasureIter(_path, _forceClosed);
}

class CkContourMeasureIter implements Iterator<ui.PathMetric> {
  /// Cached constructor function for `SkContourMeasureIter`, so we don't have to look it
  /// up every time we're constructing a new instance.
  static final js.JsFunction? _skContourMeasureIterConstructor = canvasKit['SkContourMeasureIter'];

  CkContourMeasureIter(CkPath path, bool forceClosed)
    : _skObject = js.JsObject(_skContourMeasureIterConstructor!, <dynamic>[
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
  ui.PathMetric get current {
    final ui.PathMetric? currentMetric = _current;
    if (currentMetric == null) {
      throw RangeError(
        'PathMetricIterator is not pointing to a PathMetric. This can happen in two situations:\n'
        '- The iteration has not started yet. If so, call "moveNext" to start iteration.'
        '- The iterator ran out of elements. If so, check that "moveNext" returns true prior to calling "current".'
      );
    }
    return currentMetric;
  }
  CkContourMeasure? _current;

  @override
  bool moveNext() {
    final js.JsObject? skContourMeasure = _skObject.callMethod('next');
    if (skContourMeasure == null) {
      _current = null;
      return false;
    }

    _current = CkContourMeasure(_contourIndexCounter, skContourMeasure);
    _contourIndexCounter += 1;
    return true;
  }
}

class CkContourMeasure implements ui.PathMetric {
  CkContourMeasure(this.contourIndex, this._skObject);

  final js.JsObject _skObject;

  @override
  final int contourIndex;

  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    final js.JsObject? skPath = _skObject
        .callMethod('getSegment', <dynamic>[start, end, startWithMoveTo]);
    return CkPath._fromSkPath(skPath);
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

class CkPathMetricIteratorEmpty implements Iterator<ui.PathMetric> {
  const CkPathMetricIteratorEmpty._();

  @override
  ui.PathMetric get current {
    throw RangeError('PathMetric iterator is empty.');
  }

  @override
  bool moveNext() {
    return false;
  }
}
