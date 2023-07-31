#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import '../out/protos/google/protobuf/unittest.pb.dart';

// Suppress an analyzer warning for a deliberate type mismatch.
dynamic cast(x) => x;

void main() {
  test('check properties are initialized for repeated fields', () {
    var msg = TestAllTypes();
    expect(
        (msg.info_.byName['repeatedNestedMessage']
                as FieldInfo<TestAllTypes_NestedMessage>)
            .check,
        isNotNull);

    expect(
        (msg.info_.byName['repeatedgroup']
                as FieldInfo<TestAllTypes_RepeatedGroup>)
            .check,
        isNotNull);

    expect(
        (msg.info_.byName['repeatedNestedEnum']
                as FieldInfo<TestAllTypes_NestedEnum>)
            .check,
        isNotNull);
  });

  test('check read-only default list type', () {
    final msg = TestAllTypes()..freeze();
    final list = msg.repeatedInt32;
    expect(
      list.firstWhere(
        (_msg) => false,
        orElse: () => 123,
      ),
      123,
    );
  });
}
