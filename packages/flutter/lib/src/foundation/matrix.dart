// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

import 'constants.dart';

const bool _kUseSimd = bool.fromEnvironment('flutter.simd') || !kIsWeb;

// Create a column order encoding of the provided matrix in SIMD registers.
Float32x4List _loadMatrixIntoSimd(Matrix4 matrix) {
  assert(!kIsWeb);
  final Float32x4List result = Float32x4List(4);
  final Float64List storage = matrix.storage;
  result[0] = Float32x4(storage[0],  storage[1],  storage[2],  storage[3]);
  result[1] = Float32x4(storage[4],  storage[5],  storage[6],  storage[7]);
  result[2] = Float32x4(storage[8],  storage[9],  storage[10], storage[11]);
  result[3] = Float32x4(storage[12], storage[13], storage[14], storage[15]);
  return result;
}

/// Multiply [left] with [right], returning a new matrix.
Matrix4 multiplied(Matrix4 left, Matrix4 right) {
  if (_kUseSimd) {
    final Float64List result = Float64List(16);
    return Matrix4.fromFloat64List(_multiplySimd(_loadMatrixIntoSimd(left), _loadMatrixIntoSimd(right), result));
  }
  return left.multiplied(right);
}

Float32List multiplied32(Float32List left, Float32List right) {
  final Float32List result = Float32List(16);
  return _multiplySimd32(left.buffer.asFloat32x4List(), right.buffer.asFloat32x4List(), result);
}

/// Multiply [left] with [right], returning the result into left.
void multiply(Matrix4 left, Matrix4 right) {
  if (_kUseSimd) {
    Matrix4.fromFloat64List(_multiplySimd(_loadMatrixIntoSimd(left), _loadMatrixIntoSimd(right), left.storage));
    return;
  }
  left.multiply(right);
}

/// Multiply [left] with [right] and store the result in [result].
/// It is safe to re-use the storage of either [left] or [right] for [result].
Float64List _multiplySimd(Float32x4List left, Float32x4List right, Float64List result) {
  assert(result.length == 16);
  assert(left.length == 4);
  assert(right.length == 4);

  final Float32x4 a3 = left[3];
  final Float32x4 a2 = left[2];
  final Float32x4 a1 = left[1];
  final Float32x4 a0 = left[0];

  final Float32x4 b0 = right[0];
  final Float32x4 result0 = b0.shuffle(Float32x4.xxxx) * a0 +
      b0.shuffle(Float32x4.yyyy) * a1 +
      b0.shuffle(Float32x4.zzzz) * a2 +
      b0.shuffle(Float32x4.wwww) * a3;
  final Float32x4 b1 = right[1];
  final Float32x4 result1 = b1.shuffle(Float32x4.xxxx) * a0 +
      b1.shuffle(Float32x4.yyyy) * a1 +
      b1.shuffle(Float32x4.zzzz) * a2 +
      b1.shuffle(Float32x4.wwww) * a3;
  final Float32x4 b2 = right[2];
  final Float32x4 result2 = b2.shuffle(Float32x4.xxxx) * a0 +
      b2.shuffle(Float32x4.yyyy) * a1 +
      b2.shuffle(Float32x4.zzzz) * a2 +
      b2.shuffle(Float32x4.wwww) * a3;
  final Float32x4 b3 = right[3];
  final Float32x4 result3 = b3.shuffle(Float32x4.xxxx) * a0 +
      b3.shuffle(Float32x4.yyyy) * a1 +
      b3.shuffle(Float32x4.zzzz) * a2 +
      b3.shuffle(Float32x4.wwww) * a3;

  result[15] = result3.w;
  result[14] = result3.z;
  result[13] = result3.y;
  result[12] = result3.x;

  result[11] = result2.w;
  result[10] = result2.z;
  result[9]  = result2.y;
  result[8]  = result2.x;

  result[7] = result1.w;
  result[6] = result1.z;
  result[5] = result1.y;
  result[4] = result1.x;

  result[3] = result0.w;
  result[2] = result0.z;
  result[1] = result0.y;
  result[0] = result0.x;

  return result;
}

Float32List _multiplySimd32(Float32x4List left, Float32x4List right, Float32List result) {
  assert(result.length == 16);
  assert(left.length == 4);
  assert(right.length == 4);

  final Float32x4 a3 = left[3];
  final Float32x4 a2 = left[2];
  final Float32x4 a1 = left[1];
  final Float32x4 a0 = left[0];

  final Float32x4 b0 = right[0];
  final Float32x4 result0 = b0.shuffle(Float32x4.xxxx) * a0 +
      b0.shuffle(Float32x4.yyyy) * a1 +
      b0.shuffle(Float32x4.zzzz) * a2 +
      b0.shuffle(Float32x4.wwww) * a3;
  final Float32x4 b1 = right[1];
  final Float32x4 result1 = b1.shuffle(Float32x4.xxxx) * a0 +
      b1.shuffle(Float32x4.yyyy) * a1 +
      b1.shuffle(Float32x4.zzzz) * a2 +
      b1.shuffle(Float32x4.wwww) * a3;
  final Float32x4 b2 = right[2];
  final Float32x4 result2 = b2.shuffle(Float32x4.xxxx) * a0 +
      b2.shuffle(Float32x4.yyyy) * a1 +
      b2.shuffle(Float32x4.zzzz) * a2 +
      b2.shuffle(Float32x4.wwww) * a3;
  final Float32x4 b3 = right[3];
  final Float32x4 result3 = b3.shuffle(Float32x4.xxxx) * a0 +
      b3.shuffle(Float32x4.yyyy) * a1 +
      b3.shuffle(Float32x4.zzzz) * a2 +
      b3.shuffle(Float32x4.wwww) * a3;
  final Float32x4List resultView = result.buffer.asFloat32x4List();
  resultView[3] = result3;
  resultView[2] = result2;
  resultView[1] = result1;
  resultView[0] = result0;

  return result;
}
