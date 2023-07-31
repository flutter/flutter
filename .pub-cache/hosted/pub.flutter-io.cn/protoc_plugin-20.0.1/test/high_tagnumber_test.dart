// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

import '../out/protos/google/protobuf/empty.pb.dart';
import '../out/protos/high_tagnumber.pb.dart';

void main() {
  test('round trip 29 bit tag number, binary encoding', () {
    expect(M.fromBuffer((M()..a = 42).writeToBuffer()), M()..a = 42);
    expect(M.fromBuffer((M()..b = 42).writeToBuffer()), M()..b = 42);
  });
  test('round trip 29 bit tag number, jspblite2', () {
    expect(M.fromJson((M()..a = 43).writeToJson()), M()..a = 43);
    expect(M.fromJson((M()..b = 43).writeToJson()), M()..b = 43);
  });
  test('unknown fields', () {
    final empty = Empty.fromBuffer((M()..a = 44).writeToBuffer());
    expect(empty.unknownFields.isEmpty, false);
    expect(empty.unknownFields.getField(M().info_.tagNumber('a')!)!.varints,
        [Int64(44)]);
    expect(M.fromBuffer(empty.writeToBuffer()).a, 44);
  });
}
