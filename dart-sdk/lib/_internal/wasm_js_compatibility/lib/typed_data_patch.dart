// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_types';
import 'dart:typed_data';

@patch
class ByteData {
  @patch
  factory ByteData(int length) = JSDataViewImpl;
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) = JSUint8ArrayImpl;

  @patch
  factory Uint8List.fromList(List<int> elements) =>
      JSUint8ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) = JSInt8ArrayImpl;

  @patch
  factory Int8List.fromList(List<int> elements) =>
      JSInt8ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) = JSUint8ClampedArrayImpl;

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =>
      JSUint8ClampedArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) = JSUint16ArrayImpl;

  @patch
  factory Uint16List.fromList(List<int> elements) =>
      JSUint16ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) = JSInt16ArrayImpl;

  @patch
  factory Int16List.fromList(List<int> elements) =>
      JSInt16ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) = JSUint32ArrayImpl;

  @patch
  factory Uint32List.fromList(List<int> elements) =>
      JSUint32ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) = JSInt32ArrayImpl;

  @patch
  factory Int32List.fromList(List<int> elements) =>
      JSInt32ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) =>
      JSInt32x4ArrayImpl.externalStorage(JSInt32ArrayImpl(length * 4));

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =>
      Int32x4List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) = JSBigInt64ArrayImpl;

  @patch
  factory Int64List.fromList(List<int> elements) =>
      JSBigInt64ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) = JSBigUint64ArrayImpl;

  @patch
  factory Uint64List.fromList(List<int> elements) =>
      JSBigUint64ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) = JSFloat32ArrayImpl;

  @patch
  factory Float32List.fromList(List<double> elements) =>
      JSFloat32ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) =>
      JSFloat32x4ArrayImpl.externalStorage(JSFloat32ArrayImpl(length * 4));

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =>
      Float32x4List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) = JSFloat64ArrayImpl;

  @patch
  factory Float64List.fromList(List<double> elements) =>
      JSFloat64ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) =>
      JSFloat64x2ArrayImpl.externalStorage(JSFloat64ArrayImpl(length * 2));

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =>
      Float64x2List(elements.length)..setRange(0, elements.length, elements);
}
