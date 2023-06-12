// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/fletcher16.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Fletcher16Test);
  });
}

@reflectiveTest
class Fletcher16Test {
  test_1() {
    expect(fletcher16("abcde".codeUnits), 0xC8F0);
  }

  test_2() {
    expect(fletcher16("abcdef".codeUnits), 0x2057);
  }

  test_3() {
    expect(fletcher16("abcdefgh".codeUnits), 0x0627);
  }

  test_long() {
    List<int> data = List.generate(6000, (i) => i);
    expect(fletcher16(data), 0x0178);
  }
}
