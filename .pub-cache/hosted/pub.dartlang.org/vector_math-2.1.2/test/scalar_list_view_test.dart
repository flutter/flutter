// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:vector_math/vector_math_lists.dart';

void testScalarListViewWithOffset() {
  final list = ScalarListView(10, 1);
  list[0] = 1.0;
  expect(list[0], equals(1.0));
  expect(list.buffer[0], equals(0.0)); // unset
  expect(list.buffer[1], equals(1.0));
  expect(list.buffer[2], equals(0.0)); // unset
  expect(list.buffer[3], equals(0.0));
  expect(list.buffer[4], equals(0.0));
}

void testScalarListView() {
  final buffer = Float32List(10);
  final list = ScalarListView.view(buffer, 1, 4);
  expect(list.length, 2);
  list[0] = 1.0;
  list[1] = 4.0;
  expect(buffer[0], equals(0.0));
  expect(buffer[1], equals(1.0));
  expect(buffer[2], equals(0.0));
  expect(buffer[3], equals(0.0));
  expect(buffer[4], equals(0.0));
  expect(buffer[5], equals(4.0));
  expect(buffer[6], equals(0.0));
  expect(buffer[7], equals(0.0));
  expect(buffer[8], equals(0.0));
  expect(buffer[9], equals(0.0));
}

void testScalarListViewFromList() {
  final input = [
    1.0,
    4.0,
    7.0,
  ];
  final list = ScalarListView.fromList(input, 2, 3);
  expect(list.buffer.length, 11);
  expect(list.buffer[0], 0.0);
  expect(list.buffer[1], 0.0);
  expect(list.buffer[2], 1.0);
  expect(list.buffer[3], 0.0);
  expect(list.buffer[4], 0.0);
  expect(list.buffer[5], 4.0);
  expect(list.buffer[6], 0.0);
  expect(list.buffer[7], 0.0);
  expect(list.buffer[8], 7.0);
  expect(list.buffer[9], 0.0);
  expect(list.buffer[10], 0.0);
}

void main() {
  group('ScalarListView', () {
    test('with offset', testScalarListViewWithOffset);
    test('view', testScalarListView);
    test('fromList', testScalarListViewFromList);
  });
}
