// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// An implementation of [ui.PathMetrics] that computes and exposes metrics for
/// a given [EnginePath].
class EnginePathMetrics extends IterableBase<ui.PathMetric> implements ui.PathMetrics {
  /// Creates an [EnginePathMetrics] instance for the given [path].
  ///
  /// If [forceClosed] is true, the contours of the path are measured as if they
  /// were closed, even if they were not explicitly closed.
  EnginePathMetrics({required EnginePath path, required bool forceClosed})
    : iterator = EnginePathMetricIterator(path, forceClosed);

  /// The iterator used to traverse the path metrics.
  @override
  final EnginePathMetricIterator iterator;
}

/// An [Iterator] for traversing the metrics of each contour in an [EnginePath].
class EnginePathMetricIterator implements Iterator<ui.PathMetric>, Collectable {
  /// Creates an [EnginePathMetricIterator] for the given [path].
  EnginePathMetricIterator(this.path, this.forceClosed);

  /// The path being iterated over.
  final EnginePath path;

  /// Whether to force the contours of the path to be closed.
  final bool forceClosed;
  int _nextIndex = 0;
  BackendPathMetricIterator? _cachedIterator;
  final List<BackendPathMetric> _metrics = [];
  bool _isAtEnd = false;

  /// The current [ui.PathMetric] of the iteration.
  @override
  ui.PathMetric get current {
    if (_nextIndex == 0 || _isAtEnd) {
      throw RangeError(
        'PathMetricIterator is not pointing to a PathMetric. This can happen in two situations:\n'
        '- The iteration has not started yet. If so, call "moveNext" to start iteration.\n'
        '- The iterator ran out of elements. If so, check that "moveNext" returns true prior to calling "current".',
      );
    }
    return EnginePathMetric(this, _nextIndex - 1);
  }

  /// Moves to the next [ui.PathMetric] in the iteration.
  ///
  /// Returns `true` if there is a next element, or `false` if the iteration is complete.
  @override
  bool moveNext() {
    if (_isAtEnd) {
      return false;
    }
    buildIterator();
    assert(_cachedIterator != null);
    assert(_nextIndex == _metrics.length);
    _nextIndex++;
    if (_cachedIterator!.moveNext()) {
      _metrics.add(_cachedIterator!.current);
      return true;
    } else {
      _isAtEnd = true;
      return false;
    }
  }

  /// Disposes of cached metrics and cleans up resources.
  @override
  void collect() {
    _cachedIterator?.dispose();
    _cachedIterator = null;

    for (final BackendPathMetric metric in _metrics) {
      metric.dispose();
    }
    _metrics.clear();
  }

  /// Builds the underlying backend iterator if it hasn't been built yet.
  void buildIterator() {
    if (_cachedIterator != null) {
      return;
    }
    _cachedIterator = path.backendPath.computeMetrics(forceClosed: forceClosed);
    for (var i = 0; i < _nextIndex; i++) {
      if (_cachedIterator!.moveNext()) {
        _metrics.add(_cachedIterator!.current);
      } else {
        break;
      }
    }
    EnginePlatformDispatcher.instance.frameArena.add(this);
  }

  /// Returns the built backend path metric at the given [index].
  BackendPathMetric builtMetricAtIndex(int index) {
    buildIterator();
    return _metrics[index];
  }
}

/// An implementation of [ui.PathMetric] that provides measurements and properties
/// for a specific contour of an [EnginePath].
class EnginePathMetric implements ui.PathMetric {
  /// Creates an [EnginePathMetric] associated with the given [iterator] and [contourIndex].
  EnginePathMetric(this.iterator, this.contourIndex);

  /// The iterator that generated this path metric.
  final EnginePathMetricIterator iterator;

  /// The zero-based index of the contour represented by this metric.
  @override
  final int contourIndex;

  /// The underlying [BackendPathMetric] for this contour.
  BackendPathMetric get builtMetric => iterator.builtMetricAtIndex(contourIndex);

  /// Extracts a segment of the contour from [start] to [end] as a new [ui.Path].
  @override
  ui.Path extractPath(double start, double end, {bool startWithMoveTo = true}) {
    return EnginePath.extracted(iterator.path, this, start, end, startWithMoveTo: startWithMoveTo);
  }

  /// Builds a backend path segment of this contour from [start] to [end].
  BackendPathBuilder buildExtractedPath(double start, double end, {required bool startWithMoveTo}) {
    return builtMetric.extractPath(start, end, startWithMoveTo: startWithMoveTo);
  }

  /// Computes the position and tangent vector of the contour at the given [distance].
  @override
  ui.Tangent? getTangentForOffset(double distance) {
    return builtMetric.getTangentForOffset(distance);
  }

  /// Whether this contour is closed.
  @override
  bool get isClosed => builtMetric.isClosed;

  /// The total length of this contour in logical pixels.
  @override
  double get length => builtMetric.length;
}
