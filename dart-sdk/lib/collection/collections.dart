// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// An unmodifiable [List] view of another List.
///
/// The source of the elements may be a [List] or any [Iterable] with
/// efficient [Iterable.length] and [Iterable.elementAt].
///
/// ```dart
/// final numbers = <int>[10, 20, 30];
/// final unmodifiableListView = UnmodifiableListView(numbers);
///
/// // Insert new elements into the original list.
/// numbers.addAll([40, 50]);
/// print(unmodifiableListView); // [10, 20, 30, 40, 50]
///
/// unmodifiableListView.remove(20); // Throws.
/// ```
class UnmodifiableListView<E> extends UnmodifiableListBase<E> {
  final Iterable<E> _source;

  /// Creates an unmodifiable list backed by [source].
  ///
  /// The [source] of the elements may be a [List] or any [Iterable] with
  /// efficient [Iterable.length] and [Iterable.elementAt].
  UnmodifiableListView(Iterable<E> source) : _source = source;

  List<R> cast<R>() => UnmodifiableListView(_source.cast<R>());
  int get length => _source.length;

  E operator [](int index) => _source.elementAt(index);
}
