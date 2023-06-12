// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'combined_iterator.dart';

/// A view of several lists combined into a single list.
///
/// All methods and accessors treat the [CombinedListView] list as if it were a
/// single concatenated list, but the underlying implementation is based on
/// lazily accessing individual list instances. This means that if the
/// underlying lists change, the [CombinedListView] will reflect those changes.
///
/// The index operator (`[]`) and [length] property of a [CombinedListView] are
/// both `O(lists)` rather than `O(1)`. A [CombinedListView] is unmodifiable.
class CombinedListView<T> extends ListBase<T>
    implements UnmodifiableListView<T> {
  static Never _throw() {
    throw UnsupportedError('Cannot modify an unmodifiable List');
  }

  /// The lists that this combines.
  final List<List<T>> _lists;

  /// Creates a combined view of [lists].
  CombinedListView(this._lists);

  @override
  Iterator<T> get iterator =>
      CombinedIterator<T>(_lists.map((i) => i.iterator).iterator);

  @override
  set length(int length) {
    _throw();
  }

  @override
  int get length => _lists.fold(0, (length, list) => length + list.length);

  @override
  T operator [](int index) {
    var initialIndex = index;
    for (var i = 0; i < _lists.length; i++) {
      var list = _lists[i];
      if (index < list.length) {
        return list[index];
      }
      index -= list.length;
    }
    throw RangeError.index(initialIndex, this, 'index', null, length);
  }

  @override
  void operator []=(int index, T value) {
    _throw();
  }

  @override
  void clear() {
    _throw();
  }

  @override
  bool remove(Object? element) {
    _throw();
  }

  @override
  void removeWhere(bool Function(T) test) {
    _throw();
  }

  @override
  void retainWhere(bool Function(T) test) {
    _throw();
  }
}
