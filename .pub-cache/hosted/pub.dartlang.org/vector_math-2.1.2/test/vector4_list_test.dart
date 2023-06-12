// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';
import 'package:vector_math/vector_math_lists.dart';

import 'test_utils.dart';

void testVector4ListWithOffset() {
  final list = Vector4List(12, 1);
  list[0] = Vector4(1.0, 2.0, 3.0, 4.0);
  relativeTest(list[0].x, 1.0);
  relativeTest(list[0].y, 2.0);
  relativeTest(list[0].z, 3.0);
  relativeTest(list[0].w, 4.0);
  relativeTest(list.buffer[0], 0.0); // unset
  relativeTest(list.buffer[1], 1.0);
  relativeTest(list.buffer[2], 2.0);
  relativeTest(list.buffer[3], 3.0);
  relativeTest(list.buffer[4], 4.0);
  relativeTest(list.buffer[5], 0.0); // unset
}

void testVector4ListView() {
  final buffer = Float32List(12);
  final list = Vector4List.view(buffer, 1, 5);
  // The list length should be (12 - 1) ~/ 5 == 2.
  expect(list.length, 2);
  list[0] = Vector4(1.0, 2.0, 3.0, 4.0);
  list[1] = Vector4(5.0, 6.0, 7.0, 8.0);
  expect(buffer[0], 0.0);
  expect(buffer[1], 1.0);
  expect(buffer[2], 2.0);
  expect(buffer[3], 3.0);
  expect(buffer[4], 4.0);
  expect(buffer[5], 0.0);
  expect(buffer[6], 5.0);
  expect(buffer[7], 6.0);
  expect(buffer[8], 7.0);
  expect(buffer[9], 8.0);
  expect(buffer[10], 0.0);
  expect(buffer[11], 0.0);
}

void testVector4ListViewTightFit() {
  final buffer = Float32List(12);
  final list = Vector4List.view(buffer, 2, 5);
  // The list length should be (12 - 2) ~/ 5 == 2 as the stride of the last
  // element is negligible.
  expect(list.length, 2);
  list[0] = Vector4(1.0, 2.0, 3.0, 4.0);
  list[1] = Vector4(5.0, 6.0, 7.0, 8.0);
  expect(buffer[0], 0.0);
  expect(buffer[1], 0.0);
  expect(buffer[2], 1.0);
  expect(buffer[3], 2.0);
  expect(buffer[4], 3.0);
  expect(buffer[5], 4.0);
  expect(buffer[6], 0.0);
  expect(buffer[7], 5.0);
  expect(buffer[8], 6.0);
  expect(buffer[9], 7.0);
  expect(buffer[10], 8.0);
  expect(buffer[11], 0.0);
}

void testVector4ListFromList() {
  final input = [
    Vector4(1.0, 2.0, 3.0, 4.0),
    Vector4(5.0, 6.0, 7.0, 8.0),
    Vector4(9.0, 10.0, 11.0, 12.0),
  ];
  final list = Vector4List.fromList(input, 2, 5);
  expect(list.buffer.length, 17);
  expect(list.buffer[0], 0.0);
  expect(list.buffer[1], 0.0);
  expect(list.buffer[2], 1.0);
  expect(list.buffer[3], 2.0);
  expect(list.buffer[4], 3.0);
  expect(list.buffer[5], 4.0);
  expect(list.buffer[6], 0.0);
  expect(list.buffer[7], 5.0);
  expect(list.buffer[8], 6.0);
  expect(list.buffer[9], 7.0);
  expect(list.buffer[10], 8.0);
  expect(list.buffer[11], 0.0);
  expect(list.buffer[12], 9.0);
  expect(list.buffer[13], 10.0);
  expect(list.buffer[14], 11.0);
  expect(list.buffer[15], 12.0);
  expect(list.buffer[16], 0.0);
}

void testVector4ListSetValue() {
  final list = Vector4List(2);

  list.setValues(1, 1.0, 2.0, 3.0, 4.0);

  expect(list.buffer[0], 0.0);
  expect(list.buffer[1], 0.0);
  expect(list.buffer[2], 0.0);
  expect(list.buffer[3], 0.0);
  expect(list.buffer[4], 1.0);
  expect(list.buffer[5], 2.0);
  expect(list.buffer[6], 3.0);
  expect(list.buffer[7], 4.0);
}

void testVector4ListSetZero() {
  final list = Vector4List.view(
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]));

  list.setZero(1);

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 3.0);
  expect(list.buffer[3], 4.0);
  expect(list.buffer[4], 0.0);
  expect(list.buffer[5], 0.0);
  expect(list.buffer[6], 0.0);
  expect(list.buffer[7], 0.0);
}

void testVector4ListAdd() {
  final list = Vector4List.view(
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]));

  list.add(1, $v4(2.0, 2.0, 2.0, 2.0));

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 3.0);
  expect(list.buffer[3], 4.0);
  expect(list.buffer[4], 7.0);
  expect(list.buffer[5], 8.0);
  expect(list.buffer[6], 9.0);
  expect(list.buffer[7], 10.0);
}

void testVector4ListAddScaled() {
  final list = Vector4List.view(
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]));

  list.addScaled(1, $v4(2.0, 2.0, 2.0, 2.0), 2.0);

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 3.0);
  expect(list.buffer[3], 4.0);
  expect(list.buffer[4], 9.0);
  expect(list.buffer[5], 10.0);
  expect(list.buffer[6], 11.0);
  expect(list.buffer[7], 12.0);
}

void testVector4ListSub() {
  final list = Vector4List.view(
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]));

  list.sub(1, $v4(2.0, 2.0, 2.0, 2.0));

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 3.0);
  expect(list.buffer[3], 4.0);
  expect(list.buffer[4], 3.0);
  expect(list.buffer[5], 4.0);
  expect(list.buffer[6], 5.0);
  expect(list.buffer[7], 6.0);
}

void testVector4ListMultiply() {
  final list = Vector4List.view(
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]));

  list.multiply(1, $v4(2.0, 3.0, 4.0, 5.0));

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 3.0);
  expect(list.buffer[3], 4.0);
  expect(list.buffer[4], 10.0);
  expect(list.buffer[5], 18.0);
  expect(list.buffer[6], 28.0);
  expect(list.buffer[7], 40.0);
}

void testVector4ListScale() {
  final list = Vector4List.view(
      Float32List.fromList([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]));

  list.scale(1, 2.0);

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 3.0);
  expect(list.buffer[3], 4.0);
  expect(list.buffer[4], 10.0);
  expect(list.buffer[5], 12.0);
  expect(list.buffer[6], 14.0);
  expect(list.buffer[7], 16.0);
}

void main() {
  group('Vector4List', () {
    test('with offset', testVector4ListWithOffset);
    test('view', testVector4ListView);
    test('view tight fit', testVector4ListViewTightFit);
    test('fromList', testVector4ListFromList);
    test('setValue', testVector4ListSetValue);
    test('setZero', testVector4ListSetZero);
    test('add', testVector4ListAdd);
    test('addScaled', testVector4ListAddScaled);
    test('sub', testVector4ListSub);
    test('multiply', testVector4ListMultiply);
    test('scale', testVector4ListScale);
  });
}
