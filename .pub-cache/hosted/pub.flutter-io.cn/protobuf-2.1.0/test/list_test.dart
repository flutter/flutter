#!/usr/bin/env dart
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

// [ArgumentError] in production mode, [TypeError] in checked.
final invalidArgumentException =
    predicate((e) => e is ArgumentError || e is TypeError);
final badArgument = throwsA(invalidArgumentException);

// Suppress an analyzer warning for a deliberate type mismatch.
T cast<T>(x) => x;

void main() {
  test('testPbList handles basic operations', () {
    var lb1 = PbList<int>();
    expect(lb1, []);

    lb1.add(1);
    expect(lb1, [1]);

    lb1.addAll([0, 2, 4, 6, 99]);
    expect(lb1, [1, 0, 2, 4, 6, 99]);

    expect(lb1[3], 4);
    expect(lb1.contains(4), isTrue);

    lb1[3] = 99;
    expect(lb1, [1, 0, 2, 99, 6, 99]);

    expect(lb1.indexOf(99), 3);

    expect(lb1.lastIndexOf(99), 5);

    expect(lb1.firstWhere((e) => e % 2 == 0), 0);

    expect(lb1.last, 99);
    var last = lb1.removeLast();
    expect(last, 99);
    expect(lb1.last, 6);

    var count = 0;
    for (var i in lb1) {
      count += i;
    }
    expect(count, 108);

    bool isEven(int i) => i % 2 == 0;
    var evens = List<int>.from(lb1.where(isEven));
    expect(evens, [0, 2, 6]);

    expect(lb1.any(isEven), isTrue);

    bool isNonNegative(int i) => i >= 0;
    expect(lb1.every(isNonNegative), isTrue);

    lb1.clear();
    expect(lb1, []);
  });

  test('PbList handles range operations', () {
    var lb2 = PbList<int>();

    lb2.addAll([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(lb2.sublist(3, 7), [4, 5, 6, 7]);

    lb2.setRange(3, 7, [9, 8, 7, 6]);
    expect(lb2, [1, 2, 3, 9, 8, 7, 6, 8, 9]);

    lb2.removeRange(5, 8);
    expect(lb2, [1, 2, 3, 9, 8, 9]);

    expect(() => lb2.setRange(5, 7, [88, 99].take(2)), throwsRangeError);
    expect(lb2, [1, 2, 3, 9, 8, 9]);

    expect(() => lb2.setRange(5, 7, [88, 99].take(2), 1), throwsRangeError);
    expect(lb2, [1, 2, 3, 9, 8, 9]);

    expect(() => lb2.setRange(4, 6, [88, 99].take(1), 1), throwsStateError);
    expect(lb2, [1, 2, 3, 9, 8, 9]);

    lb2.setRange(5, 6, [88, 99].take(2));
    expect(lb2, [1, 2, 3, 9, 8, 88]);

    lb2.setRange(5, 6, [88, 99].take(2), 1);
    expect(lb2, [1, 2, 3, 9, 8, 99]);
  });

  test('PbList validates items', () {
    expect(() {
      (PbList<int>() as dynamic).add('hello');
    }, throwsA(TypeMatcher<TypeError>()));
  });

  test('PbList for signed int32 validates items', () {
    List<int> list = PbList(check: getCheckFunction(PbFieldType.P3));

    expect(() {
      list.add(-2147483649);
    }, throwsArgumentError);

    expect(() {
      list.add(-2147483648);
    }, returnsNormally, reason: 'could not add min signed int32 to a PbList');

    expect(() {
      list.add(2147483648);
    }, throwsArgumentError);

    expect(() {
      list.add(2147483647);
    }, returnsNormally, reason: 'could not add max signed int32 to a PbList');
  });

  test('PBList for unsigned int32 validates items', () {
    List<int> list = PbList(check: getCheckFunction(PbFieldType.PU3));

    expect(() {
      list.add(-1);
    }, throwsArgumentError);

    expect(() {
      list.add(0);
    }, returnsNormally, reason: 'could not add zero to a PbList');

    expect(() {
      list.add(4294967296);
    }, throwsArgumentError);

    expect(() {
      list.add(4294967295);
    }, returnsNormally, reason: 'could not add max unsigned int32 to a PbList');
  });

  test('PbList for float validates items', () {
    List<double> list = PbList(check: getCheckFunction(PbFieldType.PF));

    expect(() {
      list.add(3.4028234663852886E39);
    }, throwsArgumentError);

    expect(() {
      list.add(-3.4028234663852886E39);
    }, throwsArgumentError);

    expect(() {
      list.add(3.4028234663852886E38);
    }, returnsNormally, reason: 'could not add max float to a PbList');

    expect(() {
      list.add(-3.4028234663852886E38);
    }, returnsNormally, reason: 'could not add min float to a PbList');
  });

  test('PbList for signed Int64 validates items', () {
    List<Int64> list = PbList();
    expect(() {
      list.add(cast(0)); // not an Int64
    }, badArgument);

    expect(() {
      list.add(Int64(0));
    }, returnsNormally, reason: 'could not add Int64(0) to a PbList');

    expect(() {
      list.add(Int64.MAX_VALUE);
    }, returnsNormally, reason: 'could not add max Int64 to a PbList');

    expect(() {
      list.add(Int64.MIN_VALUE);
    }, returnsNormally, reason: 'could not add min Int64 to PbList');
  });

  test('PbList for unsigned Int64 validates items', () {
    List<Int64> list = PbList();
    expect(() {
      list.add(cast(0)); // not an Int64
    }, badArgument);

    expect(() {
      list.add(Int64(0));
    }, returnsNormally, reason: 'could not add Int64(0) to a PbList');

    // Adding -1 should work because we are storing the bits as-is.
    // (It will be interpreted as a positive number.)
    // See: https://github.com/google/protobuf.dart/issues/44
    expect(() {
      list.add(Int64(-1));
    }, returnsNormally, reason: 'could not add Int64(-1) to a PbList');

    expect(() {
      list.add(Int64.MAX_VALUE);
    }, returnsNormally, reason: 'could not add max Int64 to a PbList');

    expect(() {
      list.add(Int64.MIN_VALUE);
    }, returnsNormally, reason: 'could not add min Int64 to a PbList');
  });
}
