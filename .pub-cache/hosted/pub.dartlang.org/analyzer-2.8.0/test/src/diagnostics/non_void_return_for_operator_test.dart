// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonVoidReturnForOperatorTest);
  });
}

@reflectiveTest
class NonVoidReturnForOperatorTest extends PubPackageResolutionTest {
  test_indexSetter() async {
    await assertErrorsInCode('''
class A {
  int operator []=(a, b) { return a; }
}''', [
      error(CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR, 12, 3),
    ]);
  }

  test_no_return() async {
    await assertNoErrorsInCode(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_void() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator []=(a, b) {}
}
''');
  }
}
