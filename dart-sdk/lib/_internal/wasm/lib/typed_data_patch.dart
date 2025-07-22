// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_simd';
import 'dart:_typed_data';
import 'dart:_wasm';

@patch
class ByteData {
  @patch
  factory ByteData(int length) => I8ByteData(length);
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) => I8List(length);

  @patch
  factory Int8List.fromList(List<int> elements) =>
      I8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) => U8List(length);

  @patch
  factory Uint8List.fromList(List<int> elements) =>
      U8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) => U8ClampedList(length);

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =>
      U8ClampedList(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) => I16List(length);

  @patch
  factory Int16List.fromList(List<int> elements) =>
      I16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) => U16List(length);

  @patch
  factory Uint16List.fromList(List<int> elements) =>
      U16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) => I32List(length);

  @patch
  factory Int32List.fromList(List<int> elements) =>
      I32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) => U32List(length);

  @patch
  factory Uint32List.fromList(List<int> elements) =>
      U32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) => I64List(length);

  @patch
  factory Int64List.fromList(List<int> elements) =>
      I64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) => U64List(length);

  @patch
  factory Uint64List.fromList(List<int> elements) =>
      U64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) => F32List(length);

  @patch
  factory Float32List.fromList(List<double> elements) =>
      F32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) => F64List(length);

  @patch
  factory Float64List.fromList(List<double> elements) =>
      F64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) = NaiveInt32x4List;

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =
      NaiveInt32x4List.fromList;
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) = NaiveFloat32x4List;

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =
      NaiveFloat32x4List.fromList;
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) = NaiveFloat64x2List;

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =
      NaiveFloat64x2List.fromList;
}
