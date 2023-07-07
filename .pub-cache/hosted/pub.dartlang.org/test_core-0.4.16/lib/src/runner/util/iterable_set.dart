// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';

/// An unmodifiable [Set] view backed by an arbitrary [Iterable].
///
/// Note that contrary to most APIs that take iterables, this does not convert
/// its argument to another collection before use. This means that if it's
/// lazily-generated, that generation will happen for every operation.
///
/// Note also that set operations that are usually expected to be `O(1)` or
/// `O(log(n))`, such as [contains], may be `O(n)` for many underlying iterable
/// types. As such, this should only be used for small iterables.
class IterableSet<E> with SetMixin<E>, UnmodifiableSetMixin<E> {
  /// The base iterable that set operations forward to.
  final Iterable<E> _base;

  @override
  int get length => _base.length;

  @override
  Iterator<E> get iterator => _base.iterator;

  /// Creates a [Set] view of [base].
  IterableSet(this._base);

  @override
  bool contains(Object? element) => _base.contains(element);

  @override
  E? lookup(Object? element) {
    for (var e in _base) {
      if (e == element) return e;
    }
    return null;
  }

  @override
  Set<E> toSet() => _base.toSet();
}
