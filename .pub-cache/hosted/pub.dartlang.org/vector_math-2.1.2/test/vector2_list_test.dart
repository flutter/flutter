// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:vector_math/vector_math.dart';
import 'package:vector_math/vector_math_lists.dart';

import 'test_utils.dart';

void testVector2ListWithOffset() {
  final list = Vector2List(10, 1);
  list[0] = Vector2(1.0, 2.0);
  relativeTest(list[0].x, 1.0);
  relativeTest(list[0].y, 2.0);
  relativeTest(list.buffer[0], 0.0); // unset
  relativeTest(list.buffer[1], 1.0);
  relativeTest(list.buffer[2], 2.0);
  relativeTest(list.buffer[3], 0.0); // unset
}

void testVector2ListView() {
  final buffer = Float32List(8);
  final list = Vector2List.view(buffer, 1, 3);
  // The list length should be (8 - 1) ~/ 3 == 2.
  expect(list.length, 2);
  list[0] = Vector2(1.0, 2.0);
  list[1] = Vector2(3.0, 4.0);
  expect(buffer[0], 0.0);
  expect(buffer[1], 1.0);
  expect(buffer[2], 2.0);
  expect(buffer[3], 0.0);
  expect(buffer[4], 3.0);
  expect(buffer[5], 4.0);
  expect(buffer[6], 0.0);
  expect(buffer[7], 0.0);
}

void testVector2ListViewTightFit() {
  final buffer = Float32List(8);
  final list = Vector2List.view(buffer, 2, 4);
  // The list length should be (8 - 2) ~/ 2 == 2 as the stride of the last
  // element is negligible.
  expect(list.length, 2);
  list[0] = Vector2(1.0, 2.0);
  list[1] = Vector2(3.0, 4.0);
  expect(buffer[0], 0.0);
  expect(buffer[1], 0.0);
  expect(buffer[2], 1.0);
  expect(buffer[3], 2.0);
  expect(buffer[4], 0.0);
  expect(buffer[5], 0.0);
  expect(buffer[6], 3.0);
  expect(buffer[7], 4.0);
}

void testVector2ListFromList() {
  final input = [
    Vector2(1.0, 2.0),
    Vector2(3.0, 4.0),
    Vector2(5.0, 6.0),
  ];
  final list = Vector2List.fromList(input, 2, 5);
  expect(list.buffer.length, 17);
  expect(list.buffer[0], 0.0);
  expect(list.buffer[1], 0.0);
  expect(list.buffer[2], 1.0);
  expect(list.buffer[3], 2.0);
  expect(list.buffer[4], 0.0);
  expect(list.buffer[5], 0.0);
  expect(list.buffer[6], 0.0);
  expect(list.buffer[7], 3.0);
  expect(list.buffer[8], 4.0);
  expect(list.buffer[9], 0.0);
  expect(list.buffer[10], 0.0);
  expect(list.buffer[11], 0.0);
  expect(list.buffer[12], 5.0);
  expect(list.buffer[13], 6.0);
  expect(list.buffer[14], 0.0);
  expect(list.buffer[15], 0.0);
  expect(list.buffer[16], 0.0);
}

void testVector2ListSetValue() {
  final list = Vector2List(2);

  list.setValues(1, 1.0, 2.0);

  expect(list.buffer[0], 0.0);
  expect(list.buffer[1], 0.0);
  expect(list.buffer[2], 1.0);
  expect(list.buffer[3], 2.0);
}

void testVector2ListSetZero() {
  final list = Vector2List.view(Float32List.fromList([1.0, 2.0, 3.0, 4.0]));

  list.setZero(1);

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 0.0);
  expect(list.buffer[3], 0.0);
}

void testVector2ListAdd() {
  final list = Vector2List.view(Float32List.fromList([1.0, 2.0, 3.0, 4.0]));

  list.add(1, $v2(2.0, 2.0));

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 5.0);
  expect(list.buffer[3], 6.0);
}

void testVector2ListAddScaled() {
  final list = Vector2List.view(Float32List.fromList([1.0, 2.0, 3.0, 4.0]));

  list.addScaled(1, $v2(2.0, 2.0), 2.0);

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 7.0);
  expect(list.buffer[3], 8.0);
}

void testVector2ListSub() {
  final list = Vector2List.view(Float32List.fromList([1.0, 2.0, 3.0, 4.0]));

  list.sub(1, $v2(2.0, 2.0));

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 1.0);
  expect(list.buffer[3], 2.0);
}

void testVector2ListMultiply() {
  final list = Vector2List.view(Float32List.fromList([1.0, 2.0, 3.0, 4.0]));

  list.multiply(1, $v2(2.0, 3.0));

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 6.0);
  expect(list.buffer[3], 12.0);
}

void testVector2ListScale() {
  final list = Vector2List.view(Float32List.fromList([1.0, 2.0, 3.0, 4.0]));

  list.scale(1, 2.0);

  expect(list.buffer[0], 1.0);
  expect(list.buffer[1], 2.0);
  expect(list.buffer[2], 6.0);
  expect(list.buffer[3], 8.0);
}

void main() {
  group('Vector2List', () {
    test('with offset', testVector2ListWithOffset);
    test('view', testVector2ListView);
    test('view tight fit', testVector2ListViewTightFit);
    test('fromList', testVector2ListFromList);
    test('setValue', testVector2ListSetValue);
    test('setZero', testVector2ListSetZero);
    test('add', testVector2ListAdd);
    test('addScaled', testVector2ListAddScaled);
    test('sub', testVector2ListSub);
    test('multiply', testVector2ListMultiply);
    test('scale', testVector2ListScale);
  });
}
