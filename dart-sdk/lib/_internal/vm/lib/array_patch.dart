// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal'
    show makeFixedListUnmodifiable, makeListFixedLength, patch;

@patch
class List<E> {
  @patch
  factory List.empty({bool growable = false}) {
    return growable ? <E>[] : _List<E>(0);
  }

  @patch
  @pragma("vm:prefer-inline")
  factory List.filled(int length, E fill, {bool growable = false}) => growable
      ? _GrowableList<E>.filled(length, fill)
      : _List<E>.filled(length, fill);

  @patch
  factory List.from(Iterable elements, {bool growable = true}) {
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element.
    if (elements is Iterable<E>) {
      return List.of(elements, growable: growable);
    }
    List<E> list = _GrowableList<E>(0);
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  @patch
  @pragma("vm:prefer-inline")
  factory List.of(Iterable<E> elements, {bool growable = true}) =>
      growable ? _GrowableList<E>.of(elements) : _List<E>.of(elements);

  @patch
  @pragma("vm:prefer-inline")
  factory List.generate(int length, E generator(int index),
          {bool growable = true}) =>
      growable
          ? _GrowableList<E>.generate(length, generator)
          : _List<E>.generate(length, generator);

  @patch
  factory List.unmodifiable(Iterable elements) {
    final result = List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }
}

// Used by Dart_ListLength.
@pragma("vm:entry-point", "call")
int _listLength(List list) => list.length;

// Used by Dart_ListGetRange, Dart_ListGetAsBytes.
@pragma("vm:entry-point", "call")
Object? _listGetAt(List list, int index) => list[index];

// Used by Dart_ListSetAt, Dart_ListSetAsBytes.
@pragma("vm:entry-point", "call")
void _listSetAt(List list, int index, Object? value) {
  list[index] = value;
}
