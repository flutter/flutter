// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An object that can handle events.
abstract class AnnotationTestTarget<T> {
  // This class is intended to be used as an interface with the implements
  // keyword, and should not be extended directly.
  factory AnnotationTestTarget._() => null;

  /// TODOC
  T get value;
}

/// Data collected during a hit test about a specific [AnnotationTestTarget].
///
/// Subclass this object to pass additional information from the hit test phase
/// to the event propagation phase.
class AnnotationTestEntry<T> {
  /// Creates a hit test entry.
  AnnotationTestEntry(this.target);

  /// The [HitTestTarget] encountered during the hit test.
  final AnnotationTestTarget<T> target;

  @override
  String toString() => '$target';
}

/// The result of performing a hit test on layers.
class AnnotationTestResult<T> {
  /// Creates an empty layer hit test result.
  AnnotationTestResult()
     : _path = <AnnotationTestEntry<T>>[];

  /// An unmodifiable list of [LayerHitTestEntry] objects recorded during the hit test.
  ///
  /// The first entry in the path is the most specific, typically the one at
  /// the leaf of tree being hit tested. Event propagation starts with the most
  /// specific (i.e., first) entry and proceeds in order through the path.
  Iterable<AnnotationTestEntry<T>> get path => _path;
  final List<AnnotationTestEntry<T>> _path;

  /// Add a [HitTestEntry] to the path.
  ///
  /// The new entry is added at the end of the path, which means entries should
  /// be added in order from most specific to least specific, typically during an
  /// upward walk of the tree being hit tested.
  void add(AnnotationTestEntry<T> entry) {
    _path.add(entry);
  }

  @override
  String toString() => 'AnnotationTestResult(${_path.isEmpty ? "<empty path>" : _path.join(", ")})';
}
