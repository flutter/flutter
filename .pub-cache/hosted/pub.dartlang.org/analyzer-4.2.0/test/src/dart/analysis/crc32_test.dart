// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/src/dart/analysis/crc32.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Crc32Test);
  });
}

@reflectiveTest
class Crc32Test {
  test_bytes_0() {
    expect(getCrc32([]), 0x00000000);
  }

  test_bytes_1() {
    expect(getCrc32([0x00]), 0xD202EF8D);
  }

  test_bytes_2() {
    expect(getCrc32([0x01]), 0xA505DF1B);
  }

  test_bytes_3() {
    expect(getCrc32([0x01, 0x02]), 0xB6CC4292);
  }

  test_string() {
    expect(getCrc32(utf8.encode('My very long test string.')), 0x88B8252E);
  }
}
