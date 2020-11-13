// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

class CkPathMetrics extends IterableBase<ui.PathMetric>
    implements ui.PathMetrics {
  CkPathMetrics(this._path, this._forceClosed);

  final CkPath _path;
  final bool _forceClosed;

  /// The [CkPath.isEmpty] case is special-cased to avoid booting the WASM machinery just to find out there are no contours.
  @override
  Iterator<ui.PathMetric> get iterator => _path.isEmpty
    ? const CkPathMetricIteratorEmpty._()
    : CkContourMeasureIter(this);
}

class CkContourMeasureIter extends ManagedSkiaObject<SkContourMeasureIter> implements Iterator<ui.PathMetric> {
  CkContourMeasureIter(this._metrics);

  final CkPathMetrics _metrics;

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
    final SkContourMeasure? skContourMeasure = skiaObject.next();
    if (skContourMeasure == null) {
      _current = null;
      return false;
    }

    _current = CkContourMeasure(_metrics, skContourMeasure, _contourIndexCounter);
    _contourIndexCounter += 1;
    return true;
  }

  @override
  SkContourMeasureIter createDefault() {
    return SkContourMeasureIter(
      _metrics._path.skiaObject,
      _metrics._forceClosed,
      1.0,
    );
  }

  @override
  SkContourMeasureIter resurrect() {
    final SkContourMeasureIter iterator = createDefault();

    // When resurrecting we must advance the iterator to the last known
    // position.
    for (int i = 0; i < _contourIndexCounter; i++) {
      iterator.next();
    }

    return iterator;
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }
}

class CkContourMeasure extends ManagedSkiaObject<SkContourMeasure> implements ui.PathMetric {
  CkContourMeasure(this._metrics, SkContourMeasure jsObject, this.contourIndex)
    : super(jsObject);

  /// The path metrics used to create this measure.
  ///
  /// This is used to resurrect the object if it is deleted prematurely.
  final CkPathMetrics _metrics;

  @override
  final int contourIndex;

  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    final SkPath skPath = skiaObject.getSegment(start, end, startWithMoveTo);
    return CkPath._fromSkPath(skPath, _metrics._path._fillType);
  }

  @override
  ui.Tangent getTangentForOffset(double distance) {
    final Float32List posTan = skiaObject.getPosTan(distance);
    return ui.Tangent(
      ui.Offset(posTan[0], posTan[1]),
      ui.Offset(posTan[2], posTan[3]),
    );
  }

  @override
  bool get isClosed {
    return skiaObject.isClosed();
  }

  @override
  double get length {
    return skiaObject.length();
  }

  @override
  SkContourMeasure createDefault() {
    // This method must never be called. The default instance comes from the
    // iterator's [SkContourMeasureIter.next] method initialized by the
    // constructor.
    throw StateError('Unreachable code');
  }

  @override
  SkContourMeasure resurrect() {
    final CkContourMeasureIter iterator = _metrics.iterator as CkContourMeasureIter;
    final SkContourMeasureIter skIterator = iterator.skiaObject;

    // When resurrecting we must advance the iterator to the last known
    // position.
    for (int i = 0; i < contourIndex; i++) {
      skIterator.next();
    }

    final SkContourMeasure? result = skIterator.next();

    if (result == null) {
      throw StateError('Failed to resurrect SkContourMeasure');
    }

    return result;
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
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
