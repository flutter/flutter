// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library is only supported on dart2wasm because of [allowInterop].

library dart.js;

import 'dart:_internal' show patch;
import 'dart:_js_helper';
import 'dart:_wasm';
import 'dart:collection' show ListMixin;

@patch
JsObject get context => throw UnimplementedError();

@patch
class JsObject {
  // No argument empty constructor to support inheritance.
  JsObject._() {
    throw UnimplementedError();
  }

  @patch
  factory JsObject(JsFunction constructor, [List? arguments]) =>
      throw UnimplementedError();

  @patch
  factory JsObject.fromBrowserObject(Object object) =>
      throw UnimplementedError();

  @patch
  factory JsObject.jsify(Object object) => throw UnimplementedError();

  @patch
  dynamic operator [](Object property) => throw UnimplementedError();

  @patch
  void operator []=(Object property, Object? value) =>
      throw UnimplementedError();

  @patch
  bool operator ==(Object other) => throw UnimplementedError();

  @patch
  bool hasProperty(Object property) => throw UnimplementedError();

  @patch
  void deleteProperty(Object property) => throw UnimplementedError();

  @patch
  bool instanceof(JsFunction type) => throw UnimplementedError();

  @patch
  String toString() => throw UnimplementedError();

  @patch
  dynamic callMethod(Object method, [List? args]) => throw UnimplementedError();
}

@patch
class JsFunction extends JsObject {
  @patch
  factory JsFunction.withThis(Function f) => throw UnimplementedError();

  @patch
  dynamic apply(List args, {thisArg}) => throw UnimplementedError();
}

@patch
// TODO(johnniwinther): Support with clause in patches/augmentations.
class JsArray<E> /*extends JsObject with ListMixin<E>*/ {
  @patch
  factory JsArray() => throw UnimplementedError();

  @patch
  factory JsArray.from(Iterable<E> other) => throw UnimplementedError();

  @patch
  E operator [](Object index) => throw UnimplementedError();

  @patch
  void operator []=(Object index, E value) => throw UnimplementedError();

  @patch
  int get length => throw UnimplementedError();

  @patch
  void set length(int length) => throw UnimplementedError();

  @patch
  void add(E value) => throw UnimplementedError();

  @patch
  void addAll(Iterable<E> iterable) => throw UnimplementedError();

  @patch
  void insert(int index, E element) => throw UnimplementedError();

  @patch
  E removeAt(int index) => throw UnimplementedError();

  @patch
  E removeLast() => throw UnimplementedError();

  @patch
  void removeRange(int start, int end) => throw UnimplementedError();

  @patch
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      throw UnimplementedError();

  @patch
  void sort([int compare(E a, E b)?]) => throw UnimplementedError();
}
