// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

class CkContourMeasureIter implements DisposablePathMetricIterator {
  CkContourMeasureIter(this._path, bool forceClosed)
    : skiaObject = SkContourMeasureIter(_path.skiaObject, forceClosed, 1.0);

  @override
  void dispose() {
    skiaObject.delete();
  }

  final CkPath _path;

  final SkContourMeasureIter skiaObject;

  @override
  CkContourMeasure get current {
    final CkContourMeasure? currentMetric = _current;
    if (currentMetric == null) {
      throw RangeError(
        'PathMetricIterator is not pointing to a PathMetric. This can happen in two situations:\n'
        '- The iteration has not started yet. If so, call "moveNext" to start iteration.\n'
        '- The iterator ran out of elements. If so, check that "moveNext" returns true prior to calling "current".',
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

    _current = CkContourMeasure(_path.fillType, skContourMeasure);
    return true;
  }
}

class CkContourMeasure implements DisposablePathMetric {
  CkContourMeasure(this._fillType, SkContourMeasure skiaObject) {
    _ref = UniqueRef<SkContourMeasure>(this, skiaObject, 'PathMetric');
  }

  final ui.PathFillType _fillType;

  late final UniqueRef<SkContourMeasure> _ref;

  SkContourMeasure get skiaObject => _ref.nativeObject;

  @override
  void dispose() {
    _ref.dispose();
  }

  @override
  CkPath extractPath(double start, double end, {bool startWithMoveTo = true}) {
    final SkPath skPath = skiaObject.getSegment(start, end, startWithMoveTo);
    skPath.setFillType(toSkFillType(_fillType));
    return CkPath(skPath);
  }

  @override
  ui.Tangent getTangentForOffset(double distance) {
    final Float32List posTan = skiaObject.getPosTan(distance);
    return ui.Tangent(ui.Offset(posTan[0], posTan[1]), ui.Offset(posTan[2], posTan[3]));
  }

  @override
  bool get isClosed {
    return skiaObject.isClosed();
  }

  @override
  double get length {
    return skiaObject.length();
  }
}

class CkPathMetricIteratorEmpty implements DisposablePathMetricIterator {
  const CkPathMetricIteratorEmpty();

  @override
  CkContourMeasure get current {
    throw RangeError('PathMetric iterator is empty.');
  }

  @override
  bool moveNext() {
    return false;
  }

  @override
  void dispose() {}
}
