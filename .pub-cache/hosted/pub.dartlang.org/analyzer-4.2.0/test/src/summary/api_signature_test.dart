// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/api_signature.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApiSignatureTest);
  });
}

@reflectiveTest
class ApiSignatureTest {
  ApiSignature sig = ApiSignature.unversioned();

  void checkBytes(List<int> bytes) {
    expect(sig.getBytes_forDebug(), bytes);
    expect(sig.toHex(), hex.encode(md5.convert(bytes).bytes));
  }

  void test_addBool() {
    sig.addBool(true);
    sig.addBool(true);
    sig.addBool(false);
    sig.addBool(true);
    sig.addBool(false);
    sig.addBool(false);
    sig.addBool(true);
    sig.addBool(false);
    checkBytes([1, 1, 0, 1, 0, 0, 1, 0]);
  }

  void test_addBytes() {
    // Check that offset works correctly by adding bytes in 2 chunks.
    sig.addBytes([1, 2, 3, 4, 5]);
    sig.addBytes([0xff, 0xfe, 0xfd, 0xfc, 0xfb]);
    checkBytes([1, 2, 3, 4, 5, 0xff, 0xfe, 0xfd, 0xfc, 0xfb]);
  }

  void test_addDouble() {
    sig.addDouble(1.0 / 3.0);
    sig.addDouble(-1.0);
    checkBytes([85, 85, 85, 85, 85, 85, 213, 63, 0, 0, 0, 0, 0, 0, 240, 191]);
  }

  void test_addInt() {
    sig.addInt(1);
    sig.addInt(1000);
    sig.addInt(1000000);
    sig.addInt(1000000000);
    checkBytes(
        [1, 0, 0, 0, 0xe8, 3, 0, 0, 0x40, 0x42, 0xf, 0, 0, 0xca, 0x9a, 0x3b]);
  }

  void test_addString() {
    sig.addString('abc');
    sig.addString('\u00f8');
    checkBytes([3, 0, 0, 0, 0x61, 0x62, 0x63, 2, 0, 0, 0, 0xc3, 0xb8]);
  }

  void test_manyInts() {
    // This verifies that the logic to extend the internal buffer works
    // properly.
    List<int> expectedResult = [];
    for (int i = 0; i < 100000; i++) {
      sig.addInt(i);
      expectedResult.add(i % 0x100);
      expectedResult.add((i ~/ 0x100) % 0x100);
      expectedResult.add((i ~/ 0x10000) % 0x100);
      expectedResult.add((i ~/ 0x1000000) % 0x100);
    }
    checkBytes(expectedResult);
  }
}
