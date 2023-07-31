// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryOperatorWrittenOutTest);
  });
}

@reflectiveTest
class BinaryOperatorWrittenOutTest extends PubPackageResolutionTest {
  test_using_and() async {
    await assertErrorsInCode(r'''
f(var x, var y) {
  return x and y;
}
''', [
      error(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 29, 3),
    ]);
  }

  test_using_and_no_error() async {
    await assertNoErrorsInCode(r'''
f(var x, var y) {
  return x & y;
}
''');
  }

  test_using_or() async {
    await assertErrorsInCode(r'''
f(var x, var y) {
  return x or y;
}
''', [
      error(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 29, 2),
    ]);
  }

  test_using_or_no_error() async {
    await assertNoErrorsInCode(r'''
f(var x, var y) {
  return x | y;
}
''');
  }

  test_using_shl() async {
    await assertErrorsInCode(r'''
f(var x) {
  return x shl 2;
}
''', [
      error(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 22, 3),
    ]);
  }

  test_using_shl_no_error() async {
    await assertNoErrorsInCode(r'''
f(var x) {
  return x << 2;
}
''');
  }

  test_using_shr() async {
    await assertErrorsInCode(r'''
f(var x) {
  return x shr 2;
}
''', [
      error(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 22, 3),
    ]);
  }

  test_using_shr_no_error() async {
    await assertNoErrorsInCode(r'''
f(var x) {
  return x >> 2;
}
''');
  }

  test_using_xor() async {
    await assertErrorsInCode(r'''
f(var x, var y) {
  return x xor y;
}
''', [
      error(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 29, 3),
    ]);
  }

  test_using_xor_no_error() async {
    await assertNoErrorsInCode(r'''
f(var x, var y) {
  return x ^ y;
}
''');
  }
}
