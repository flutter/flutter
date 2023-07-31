// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullNeverNotNullTest);
  });
}

@reflectiveTest
class NullNeverNotNullTest extends PubPackageResolutionTest {
  test_nullable() async {
    await assertNoErrorsInCode(r'''
void f(int? i) {
  i!;
}
''');
  }

  test_nullLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  null!;
}
''', [
      error(HintCode.NULL_CHECK_ALWAYS_FAILS, 13, 5),
    ]);
  }

  test_nullLiteral_parenthesized() async {
    await assertErrorsInCode(r'''
void f() {
  (null)!;
}
''', [
      error(HintCode.NULL_CHECK_ALWAYS_FAILS, 13, 7),
    ]);
  }

  test_nullType() async {
    await assertErrorsInCode(r'''
void f() {
  g()!;
}
Null g() => null;
''', [
      error(HintCode.NULL_CHECK_ALWAYS_FAILS, 13, 4),
    ]);
  }

  test_nullType_awaited() async {
    await assertErrorsInCode(r'''
void f() async {
  (await g())!;
}
Future<Null> g() async => null;
''', [
      error(HintCode.NULL_CHECK_ALWAYS_FAILS, 19, 12),
    ]);
  }

  test_potentiallyNullableTypeVariable() async {
    await assertNoErrorsInCode(r'''
void f<T>(T i) {
  i!;
}
''');
  }
}
