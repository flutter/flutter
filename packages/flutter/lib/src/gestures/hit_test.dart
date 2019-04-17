// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'events.dart';

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

  /// Push a new transform matrix that is to be applied to all future
  /// [HitTestEntry]s added via [add] until it is removed via [popTransform].
  ///
  /// The provided `transform` matrix should describe how to transform
  /// [PointerEvent]s from the coordinate space of the method caller to the
  /// coordinate space of its children.
  ///
  /// [HitTestable]s should call this in their [HitTestable.hitTest] method
  /// before hit testing their children if they apply any kind of paint
  /// transform to their children. In most cases the `transform` provided is
  /// derived from inverting the result of running
  /// [RenderObject.applyPaintTransform] through
  /// [PointerEvent.paintTransformToPointerEventTransform].
  ///
  /// {@tool sample}
  /// The following code snippet shows how [pushTransform] and [popTransform]
  /// can be called from [RenderBox.hitTestChildern].
  ///
  /// ```dart
  /// abstract class Foo extends RenderBox {
  ///
  /// final Matrix4 _effectiveTransform = Matrix4.rotationZ(50);
  ///
  /// @override
  /// void applyPaintTransform(RenderBox child, Matrix4 transform) {
  ///   transform.multiply(_effectiveTransform);
  /// }
  ///
  /// @override
  /// bool hitTestChildren(HitTestResult result, { Offset position }) {
  ///   final Matrix4 inverse = Matrix4.tryInvert(
  ///     PointerEvent.paintTransformToPointerEventTransform(_effectiveTransform)
  ///   );
  ///
  ///   if (inverse == null) {
  ///     // We cannot invert the effective transform. That means the child
  ///     // doesn't appear on screen and cannot be hit.
  ///     return false;
  ///   }
  ///
  ///   result.pushTransform(inverse);
  ///
  ///   position = MatrixUtils.transformPoint(inverse, position);
  ///   final bool absorbed = super.hitTestChildren(result, position: position);
  ///
  ///   result.popTransform();
  ///
  ///   return absorbed;
  /// }
  /// ```
  /// {@end-tool}
  void pushTransform(Matrix4 transform) {
    _transforms.add(_transforms.isEmpty ? transform : _transforms.last * transform);
  }

  /// Removes the last transform added via [pushTransform].
  ///
  /// This is usually called from within [HitTestable.hitTest] after hit testing
  /// children that have a point transform applied to them.
  ///
  /// See also:
  ///
  ///  * [pushTransform], which has an example show-casing how to use these
  ///    methods.
  void popTransform() {
    assert(_transforms.isNotEmpty);
    _transforms.removeLast();
  }

  /// Returns a matrix describing how [PointerEvent]s delivered to `entry`
  /// should be transformed from the global coordinate space of the screen to
  /// the local coordinate space of `entry`.
  ///
  /// See also:
  ///
  ///  * [pushTransform] and [popTransform], which are called during hit testing
  ///    to build up the transform returned by this method.
  Matrix4 getTransform(HitTestEntry entry) {
    assert(_path.containsKey(entry));
    return _path[entry];
  }

  @override
  String toString() => 'HitTestResult(${_path.isEmpty ? "<empty path>" : _path.keys.join(", ")})';
}
