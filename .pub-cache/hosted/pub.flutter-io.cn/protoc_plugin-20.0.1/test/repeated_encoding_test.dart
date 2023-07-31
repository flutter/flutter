#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/proto2_repeated.pb.dart';
import '../out/protos/proto3_repeated.pb.dart';

void main() {
  test('check proto2 and proto3 repeated field encodings', () {
    final proto2 = Proto2Repeated(
        intsDefault: [1, 2], intsPacked: [1, 2], intsNotPacked: [1, 2]);
    final proto2Encoded = proto2.writeToBuffer();
    expect(
        proto2Encoded.toList(),
        equals([
          8, // field = 1, type = varint
          1, // value = 1
          8, // field = 1, type = varint
          2, // value = 2
          18, // field = 2, type = length delimited
          2, // length = 2
          1, 2, // values = [1, 2]
          24, // field = 3, type = varint
          1, // value = 1
          24, // field = 3, type = varint
          2, // value = 2
        ]));

    final proto3 = Proto3Repeated(
        intsDefault: [1, 2], intsPacked: [1, 2], intsNotPacked: [1, 2]);
    final proto3Encoded = proto3.writeToBuffer();
    expect(
        proto3Encoded.toList(),
        equals([
          10, // field = 1, type = length delimited
          2, // length = 2
          1, 2, // values = [1, 2]
          18, // field = 2, type = length delimited
          2, // length = 2
          1, 2, // values = [1, 2]
          24, // field = 3, type = varint
          1, // value = 1
          24, // field = 3, type = varint
          2, // value = 2
        ]));
  });
}
