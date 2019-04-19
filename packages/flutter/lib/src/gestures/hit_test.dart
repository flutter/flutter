// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'events.dart';

typedef HitTest = bool Function(HitTestResult result, Offset position);

/// An object that can hit-test pointers.
abstract class HitTestable {
  // This class is intended to be used as an interface with the implements
  // keyword, and should not be extended directly.
  factory HitTestable._() => null;

  /// Check whether the given position hits this object.
  ///
  /// If this given position hits this object, consider adding a [HitTestEntry]
  /// to the given hit test result.
  void hitTest(HitTestResult result, Offset position);
}

/// An object that can dispatch events.
abstract class HitTestDispatcher {
  // This class is intended to be used as an interface with the implements
  // keyword, and should not be extended directly.
  factory HitTestDispatcher._() => null;

  /// Override this method to dispatch events.
  void dispatchEvent(PointerEvent event, HitTestResult result);
}

/// An object that can handle events.
abstract class HitTestTarget {
  // This class is intended to be used as an interface with the implements
  // keyword, and should not be extended directly.
  factory HitTestTarget._() => null;

  /// Override this method to receive events.
  void handleEvent(PointerEvent event, HitTestEntry entry);
}

/// Data collected during a hit test about a specific [HitTestTarget].
///
/// Subclass this object to pass additional information from the hit test phase
/// to the event propagation phase.
class HitTestEntry {
  /// Creates a hit test entry.
  const HitTestEntry(this.target);

  /// The [HitTestTarget] encountered during the hit test.
  final HitTestTarget target;

  @override
  String toString() => '$target';
}

/// The result of performing a hit test.
class HitTestResult {
  /// Creates an empty hit test result.
  HitTestResult();

  /// An unmodifiable list of [HitTestEntry] objects recorded during the hit test.
  ///
  /// The first entry in the path is the most specific, typically the one at
  /// the leaf of tree being hit tested. Event propagation starts with the most
  /// specific (i.e., first) entry and proceeds in order through the path.
  Iterable<HitTestEntry> get path => _path.keys;
  final Map<HitTestEntry, Matrix4> _path = <HitTestEntry, Matrix4>{};

  /// Add a [HitTestEntry] to the path.
  ///
  /// The new entry is added at the end of the path, which means entries should
  /// be added in order from most specific to least specific, typically during an
  /// upward walk of the tree being hit tested.
  void add(HitTestEntry entry) {
    _path[entry] = _transforms.isEmpty ? null : _transforms.last;
  }

  final List<Matrix4> _transforms = <Matrix4>[];

  void _pushTransform(Matrix4 transform) {
//    assert(transform.getRow(2) == Vector4(0, 0, 1, 0) && transform.getColumn(2) == Vector4(0, 0, 1, 0),
//      'The third row and third column of a transform matrix for pointer '
//      'events must be Vector4(0, 0, 1, 0). Did you forget to run the paint '
//      'matrix through PointerEvent.paintTransformToPointerEventTransform?'
//      'The provided matrix is:\n$transform'
//    );
    _transforms.add(_transforms.isEmpty ? transform : _transforms.last * transform);
  }

  void _popTransform() {
    assert(_transforms.isNotEmpty);
    _transforms.removeLast();
  }

  /// Convenience method to transform a position before hit-testing a child.
  ///
  /// This can be used instead of [_pushTransform] and [_popTransform].
  ///
  /// The provided paint [transform] from the child coordinate system to the
  /// coordinate system of the caller, will be turned into a transform matrix
  /// for pointer events. The inverted transformed matrix is used to transform
  /// [position] from the parent coordinate system to the child coordinate system
  /// before calling the provided [hitTest] callback.
  ///
  /// If the provided [transform] cannot be inverted, [hitTest] will not be
  /// called and false is returned. Otherwise, the return value of [hitTest]
  /// is returned.
  ///
  /// {@tool sample}
  /// This method is often used in [RenderBox.hitTestChildren]:
  ///
  /// ```dart
  /// abstract class Foo extends RenderBox {
  ///
  ///   final Matrix4 _effectiveTransform = Matrix4.rotationZ(50);
  ///
  ///   @override
  ///   void applyPaintTransform(RenderBox child, Matrix4 transform) {
  ///     transform.multiply(_effectiveTransform);
  ///   }
  ///
  ///   @override
  ///   bool hitTestChildren(HitTestResult result, { Offset position }) {
  ///     return result.withTransform(
  ///       transform: _effectiveTransform,
  ///       position: position,
  ///       hitTest: (HitTestResult result, Offset position) {
  ///         return super.hitTestChildren(result, position: position);
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  bool withPaintTransform({
    @required Matrix4 transform,
    @required Offset position,
    @required HitTest hitTest,
  }) {
    assert(hitTest != null);
    if (transform != null) {
      transform = Matrix4.tryInvert(PointerEvent.paintTransformToPointerEventTransform(transform));
      if (transform == null) {
        // Objects are not visible on screen and cannot be hit-tested.
        return false;
      }
      _pushTransform(transform);
    }
    final Offset transformedPosition = transform == null || position == null ? position : MatrixUtils.transformPoint(transform, position);
    final bool absorbed = hitTest(this, transformedPosition);
    if (transform != null) {
      _popTransform();
    }
    return absorbed;
  }

  bool withPaintOffset({
    @required Offset offset,
    @required Offset position,
    @required HitTest hitTest,
  }) {
    assert(hitTest != null);
    return withRawTransform(
      transform: offset != null ? Matrix4.translationValues(-offset.dx, -offset.dy, 0.0) : null,
      position: position,
      hitTest: hitTest,
    );
  }

  bool withRawTransform({
    @required Matrix4 transform,
    @required Offset position,
    @required HitTest hitTest,
  }) {
    assert(hitTest != null);
    if (transform != null) {
      _pushTransform(transform);
    }
    final Offset transformedPosition = transform == null || position == null ? position : MatrixUtils.transformPoint(transform, position);
    final bool absorbed = hitTest(this, transformedPosition);
    if (transform != null) {
      _popTransform();
    }
    return absorbed;
  }

  /// Returns a matrix describing how [PointerEvent]s delivered to `entry`
  /// should be transformed from the global coordinate space of the screen to
  /// the local coordinate space of `entry`.
  ///
  /// See also:
  ///
  ///  * [_pushTransform] and [_popTransform], which are called during hit testing
  ///    to build up the transform returned by this method.
  Matrix4 getTransform(HitTestEntry entry) {
    assert(_path.containsKey(entry));
    return _path[entry];
  }

  @override
  String toString() => 'HitTestResult(${_path.isEmpty ? "<empty path>" : _path.keys.join(", ")})';
}
