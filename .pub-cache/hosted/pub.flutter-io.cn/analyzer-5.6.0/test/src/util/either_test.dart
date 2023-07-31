// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/either.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Either2Test);
  });
}

@reflectiveTest
class Either2Test {
  void test_map_t1() {
    var either = Either2<int, String>.t1(1);
    expect(either.map((x) => x + 2, (_) => throw 'unexpected'), 3);
  }

  void test_map_t2() {
    var either = Either2<int, String>.t2('hello');
    expect(either.map((_) => throw 'unexpected', (x) => x.length), 5);
  }

  void test_toString_t1() {
    var either = Either2<int, String>.t1(42);
    expect(either.toString(), '42');
  }

  void test_toString_t2() {
    var either = Either2<int, String>.t2('hello');
    expect(either.toString(), 'hello');
  }
}
