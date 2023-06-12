// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';
import 'package:test/test.dart' show test, expect, throwsArgumentError;

import 'test_utils.dart';

void main() {
  test('anyOf', () {
    // with a list
    shouldFail(
        0, anyOf([equals(1), equals(2)]), 'Expected: (<1> or <2>) Actual: <0>');
    shouldPass(1, anyOf([equals(1), equals(2)]));

    // with individual items
    shouldFail(
        0, anyOf(equals(1), equals(2)), 'Expected: (<1> or <2>) Actual: <0>');
    shouldPass(1, anyOf(equals(1), equals(2)));
  });

  test('allOf', () {
    // with a list
    shouldPass(1, allOf([lessThan(10), greaterThan(0)]));
    shouldFail(
        -1,
        allOf([lessThan(10), greaterThan(0)]),
        'Expected: (a value less than <10> and a value greater than <0>) '
        'Actual: <-1> '
        'Which: is not a value greater than <0>');

    // with individual items
    shouldPass(1, allOf(lessThan(10), greaterThan(0)));
    shouldFail(
        -1,
        allOf(lessThan(10), greaterThan(0)),
        'Expected: (a value less than <10> and a value greater than <0>) '
        'Actual: <-1> '
        'Which: is not a value greater than <0>');

    // with maximum items
    shouldPass(
        1,
        allOf(lessThan(10), lessThan(9), lessThan(8), lessThan(7), lessThan(6),
            lessThan(5), lessThan(4)));
    shouldFail(
        4,
        allOf(lessThan(10), lessThan(9), lessThan(8), lessThan(7), lessThan(6),
            lessThan(5), lessThan(4)),
        'Expected: (a value less than <10> and a value less than <9> and a '
        'value less than <8> and a value less than <7> and a value less than '
        '<6> and a value less than <5> and a value less than <4>) '
        'Actual: <4> '
        'Which: is not a value less than <4>');
  });

  test('If the first argument is a List, the rest must be null', () {
    expect(() => allOf([], 5), throwsArgumentError);
    expect(
        () => anyOf([], null, null, null, null, null, 42), throwsArgumentError);
  });
}
