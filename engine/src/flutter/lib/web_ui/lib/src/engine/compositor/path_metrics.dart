// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

class CkPathMetrics extends IterableBase<ui.PathMetric>
    implements ui.PathMetrics {
  CkPathMetrics(this._path, this._forceClosed);

  final CkPath _path;
  final bool _forceClosed;

  /// The [CkPath.isEmpty] case is special-cased to avoid booting the WASM machinery just to find out there are no contours.
  @override
  Iterator<ui.PathMetric> get iterator => _path.isEmpty ? const CkPathMetricIteratorEmpty._() : CkContourMeasureIter(_path, _forceClosed);
}

class CkContourMeasureIter implements Iterator<ui.PathMetric> {
  CkContourMeasureIter(CkPath path, bool forceClosed)
    : _skObject = SkContourMeasureIter(
        path._skPath,
        forceClosed,
        1,
      ),
      _fillType = path._fillType;

  final SkContourMeasureIter _skObject;
  final ui.PathFillType _fillType;

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
    final SkContourMeasure? skContourMeasure = _skObject.next();
    if (skContourMeasure == null) {
      _current = null;
      return false;
    }

    _current = CkContourMeasure(_contourIndexCounter, skContourMeasure, _fillType);
    _contourIndexCounter += 1;
    return true;
  }
}

class CkContourMeasure implements ui.PathMetric {
  CkContourMeasure(this.contourIndex, this._skObject, this._fillType);

  final SkContourMeasure _skObject;
  final ui.PathFillType _fillType;

  @override
  final int contourIndex;

  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    final SkPath skPath = _skObject.getSegment(start, end, startWithMoveTo);
    return CkPath._fromSkPath(skPath, _fillType);
  }

  @override
  ui.Tangent getTangentForOffset(double distance) {
    final Float32List posTan = _skObject.getPosTan(distance);
    return ui.Tangent(
      ui.Offset(posTan[0], posTan[1]),
      ui.Offset(posTan[2], posTan[3]),
    );
  }

  @override
  bool get isClosed {
    return _skObject.isClosed();
  }

  @override
  double get length {
    return _skObject.length();
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
