#!/usr/bin/env dart
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/bytes.pb.dart';

void main() {
  test('Does not reuse input buffer for bytes fields', () {
    var message = BytesEntity()..value = [1, 2, 3];
    var bytes = message.writeToBuffer();
    var deserialized1 = BytesEntity()..mergeFromBuffer(bytes);
    var deserialized2 = BytesEntity()..mergeFromBuffer(bytes);
    deserialized1.value[0] = 100;
    expect(deserialized1.value[0], 100);
    expect(deserialized2.value[0], 1);
  });

  test('Does not reuse input buffer for repeated bytes fields', () {
    var message = BytesEntity()..values.add([1, 2, 3]);
    var bytes = message.writeToBuffer();
    var deserialized1 = BytesEntity()..mergeFromBuffer(bytes);
    var deserialized2 = BytesEntity()..mergeFromBuffer(bytes);
    deserialized1.values.first[0] = 100;
    expect(deserialized1.values.first[0], 100);
    expect(deserialized2.values.first[0], 1);
  });
}
