// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'union_set.dart';

/// A controller that exposes a view of the union of a collection of sets.
///
/// This is a convenience class for creating a [UnionSet] whose contents change
/// over the lifetime of a class. For example:
///
/// ```dart
/// class Engine {
///   Set<Test> get activeTests => _activeTestsGroup.set;
///   final _activeTestsGroup = UnionSetController<Test>();
///
///   void addSuite(Suite suite) {
///     _activeTestsGroup.add(suite.tests);
///     _runSuite(suite);
///     _activeTestsGroup.remove(suite.tests);
///   }
/// }
/// ```
class UnionSetController<E> {
  /// The [UnionSet] that provides a view of the union of sets in [this].
  final UnionSet<E> set;

  /// The sets whose union is exposed through [set].
  final Set<Set<E>> _sets;

  /// Creates a set of sets that provides a view of the union of those sets.
  ///
  /// If [disjoint] is `true`, this assumes that all component sets are
  /// disjoint—that is, that they contain no elements in common. This makes
  /// many operations including [length] more efficient.
  UnionSetController({bool disjoint = false}) : this._(<Set<E>>{}, disjoint);

  /// Creates a controller with the provided [_sets].
  UnionSetController._(this._sets, bool disjoint)
      : set = UnionSet<E>(_sets, disjoint: disjoint);

  /// Adds the contents of [component] to [set].
  ///
  /// If the contents of [component] change over time, [set] will change
  /// accordingly.
  void add(Set<E> component) {
    _sets.add(component);
  }

  /// Removes the contents of [component] to [set].
  ///
  /// If another set in [this] has overlapping elements with [component], those
  /// elements will remain in [set].
  bool remove(Set<E> component) => _sets.remove(component);
}
