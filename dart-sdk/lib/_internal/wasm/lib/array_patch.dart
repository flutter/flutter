// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal'
    show makeFixedListUnmodifiable, makeListFixedLength, patch;
import 'dart:_list';

@patch
class List<E> {
  @patch
  factory List.empty({bool growable = false}) {
    return growable ? <E>[] : ModifiableFixedLengthList<E>(0);
  }

  @patch
  @pragma("wasm:prefer-inline")
  factory List.filled(int length, E fill, {bool growable = false}) => growable
      ? GrowableList<E>.filled(length, fill)
      : ModifiableFixedLengthList<E>.filled(length, fill);

  @patch
  factory List.from(Iterable elements, {bool growable = true}) {
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element.
    if (elements is Iterable<E>) {
      return List.of(elements, growable: growable);
    }
    List<E> list = GrowableList<E>(0);
    for (E e in elements) {
      list.add(e);
    }
    if (growable) return list;
    return makeListFixedLength(list);
  }

  @patch
  @pragma("wasm:prefer-inline")
  factory List.of(Iterable<E> elements, {bool growable = true}) => growable
      ? GrowableList<E>.of(elements)
      : ModifiableFixedLengthList<E>.of(elements);

  @patch
  @pragma("wasm:prefer-inline")
  factory List.generate(int length, E generator(int index),
          {bool growable = true}) =>
      growable
          ? GrowableList<E>.generate(length, generator)
          : ModifiableFixedLengthList<E>.generate(length, generator);

  @patch
  factory List.unmodifiable(Iterable elements) {
    final result = List<E>.from(elements, growable: false);
    return makeFixedListUnmodifiable(result);
  }
}
