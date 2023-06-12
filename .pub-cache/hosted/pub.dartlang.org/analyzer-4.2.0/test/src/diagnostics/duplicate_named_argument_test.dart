// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateNamedArgumentTest);
  });
}

@reflectiveTest
class DuplicateNamedArgumentTest extends PubPackageResolutionTest {
  test_constructor() async {
    await assertErrorsInCode(r'''
class C {
  C({int? a, int? b});
}
main() {
  C(a: 1, a: 2);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 54, 1),
    ]);
  }

  test_constructor_nonFunctionTypedef() async {
    await assertErrorsInCode(r'''
class C {
  C({int? a, int? b});
}
typedef D = C;
main() {
  D(a: 1, a: 2);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 69, 1),
    ]);
  }

  test_constructor_superParameter() async {
    await assertErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a}) : super(a: 0);
}
''', [error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 88, 1)]);
  }

  test_enumConstant() async {
    await assertErrorsInCode(r'''
enum E {
  v(a: 0, a: 1);
  const E({required int a});
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 19, 1),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 32, 1),
    ]);
  }
}
