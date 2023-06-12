// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedNamedParameterTest);
  });
}

@reflectiveTest
class UndefinedNamedParameterTest extends PubPackageResolutionTest {
  test_constConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
main() {
  const A(p: 0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 44, 1),
    ]);
  }

  test_constructor() async {
    await assertErrorsInCode(r'''
class A {
  A();
}
main() {
  A(p: 0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 32, 1),
    ]);
  }

  test_enumConstant() async {
    await assertErrorsInCode(r'''
enum E {
  v(a: 0);
  const E();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 13, 1),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
f({a, b}) {}
main() {
  f(c: 1);
}''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 26, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
}
main() {
  A().m(p: 0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 38, 1),
    ]);
  }
}
