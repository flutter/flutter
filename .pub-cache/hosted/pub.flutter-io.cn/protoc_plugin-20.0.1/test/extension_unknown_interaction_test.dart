#!/usr/bin/env dart
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import '../out/protos/google/protobuf/unittest.pb.dart';

void main() {
  test('setExtension clears unknown field with same tag number', () {
    final m = TestAllExtensions();
    m.unknownFields.addField(Unittest.optionalInt32Extension.tagNumber,
        UnknownFieldSetField()..addFixed32(33));
    expect(m.unknownFields.hasField(Unittest.optionalInt32Extension.tagNumber),
        isTrue);
    m.setExtension(Unittest.optionalInt32Extension, 42);
    expect(m.getExtension(Unittest.optionalInt32Extension), 42);
    expect(m.unknownFields.hasField(Unittest.optionalInt32Extension.tagNumber),
        isFalse);
  });
}
