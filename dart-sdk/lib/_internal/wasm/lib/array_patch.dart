// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, EfficientLengthIterable;
import 'dart:_list';
import 'dart:_wasm';

@patch
class List<E> {
  @patch
  @pragma("wasm:prefer-inline")
  factory List.empty({bool growable = false}) {
    return growable ? <E>[] : ModifiableFixedLengthList<E>(0);
  }

  @patch
  @pragma("wasm:prefer-inline")
  factory List.filled(int length, E fill, {bool growable = false}) =>
      growable
          ? GrowableList<E>.filled(length, fill)
          : ModifiableFixedLengthList<E>.filled(length, fill);

  @patch
  @pragma("wasm:prefer-inline")
  factory List.from(Iterable elements, {bool growable = true}) =>
      growable
          ? GrowableList<E>.ofUntypedIterable(elements)
          : ModifiableFixedLengthList<E>.ofUntypedIterable(elements);

  @patch
  @pragma("wasm:prefer-inline")
  factory List.of(Iterable<E> elements, {bool growable = true}) =>
      growable
          ? GrowableList<E>.of(elements)
          : ModifiableFixedLengthList<E>.of(elements);

  @patch
  @pragma("wasm:prefer-inline")
  factory List.generate(
    int length,
    E generator(int index), {
    bool growable = true,
  }) =>
      growable
          ? GrowableList<E>.generate(length, generator)
          : ModifiableFixedLengthList<E>.generate(length, generator);

  @patch
  @pragma("wasm:prefer-inline")
  factory List.unmodifiable(Iterable elements) {
    return ImmutableList<E>.ofUntypedIterable(elements);
  }
}
