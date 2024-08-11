// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_native_typed_data';

@patch
class ByteData {
  @patch
  factory ByteData(int length) = NativeByteData;
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) = NativeFloat32List;

  @patch
  factory Float32List.fromList(List<double> elements) =
      NativeFloat32List.fromList;
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) = NativeFloat64List;

  @patch
  factory Float64List.fromList(List<double> elements) =
      NativeFloat64List.fromList;
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) = NativeInt16List;

  @patch
  factory Int16List.fromList(List<int> elements) = NativeInt16List.fromList;
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) = NativeInt32List;

  @patch
  factory Int32List.fromList(List<int> elements) = NativeInt32List.fromList;
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) = NativeInt8List;

  @patch
  factory Int8List.fromList(List<int> elements) = NativeInt8List.fromList;
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) = NativeUint32List;

  @patch
  factory Uint32List.fromList(List<int> elements) = NativeUint32List.fromList;
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) = NativeUint16List;

  @patch
  factory Uint16List.fromList(List<int> elements) = NativeUint16List.fromList;
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) = NativeUint8ClampedList;

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =
      NativeUint8ClampedList.fromList;
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) = NativeUint8List;

  @patch
  factory Uint8List.fromList(List<int> elements) = NativeUint8List.fromList;
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) {
    throw UnsupportedError("Int64List not supported on the web.");
  }

  @patch
  factory Int64List.fromList(List<int> elements) {
    throw UnsupportedError("Int64List not supported on the web.");
  }
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) {
    throw UnsupportedError("Uint64List not supported on the web.");
  }

  @patch
  factory Uint64List.fromList(List<int> elements) {
    throw UnsupportedError("Uint64List not supported on the web.");
  }
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) = NativeInt32x4List;

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =
      NativeInt32x4List.fromList;
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) = NativeFloat32x4List;

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =
      NativeFloat32x4List.fromList;
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) = NativeFloat64x2List;

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =
      NativeFloat64x2List.fromList;
}

@patch
class Float32x4 {
  @patch
  factory Float32x4(double x, double y, double z, double w) = NativeFloat32x4;
  @patch
  factory Float32x4.splat(double v) = NativeFloat32x4.splat;
  @patch
  factory Float32x4.zero() = NativeFloat32x4.zero;
  @patch
  factory Float32x4.fromInt32x4Bits(Int32x4 x) =
      NativeFloat32x4.fromInt32x4Bits;
  @patch
  factory Float32x4.fromFloat64x2(Float64x2 v) = NativeFloat32x4.fromFloat64x2;
}

@patch
class Int32x4 {
  @patch
  factory Int32x4(int x, int y, int z, int w) = NativeInt32x4;
  @patch
  factory Int32x4.bool(bool x, bool y, bool z, bool w) = NativeInt32x4.bool;
  @patch
  factory Int32x4.fromFloat32x4Bits(Float32x4 x) =
      NativeInt32x4.fromFloat32x4Bits;
}

@patch
class Float64x2 {
  @patch
  factory Float64x2(double x, double y) = NativeFloat64x2;
  @patch
  factory Float64x2.splat(double v) = NativeFloat64x2.splat;
  @patch
  factory Float64x2.zero() = NativeFloat64x2.zero;
  @patch
  factory Float64x2.fromFloat32x4(Float32x4 v) = NativeFloat64x2.fromFloat32x4;
}
