// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticWarningCodeTest);
  });
}

@reflectiveTest
class StaticWarningCodeTest extends PubPackageResolutionTest {
  // TODO(brianwilkerson) Figure out what to do with the rest of these tests.
  //  The names do not correspond to diagnostic codes, so it isn't clear what
  //  they're testing.
  test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() async {
    // 15028
    await assertErrorsInCode('''
class C {
  foo(int x) => x;
}
abstract class D {
  foo(x, [y]);
}
class E extends C implements D {}''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 73, 1),
    ]);
  }

  test_typePromotion_functionType_arg_InterToDyn() async {
    await assertNoErrorsInCode('''
typedef FuncDyn(x);
typedef FuncA(A a);
class A {}
class B {}
f(FuncA f) {
  if (f is FuncDyn) {
    f(new B());
  }
}''');
  }

  test_voidReturnForGetter() async {
    await assertNoErrorsInCode('''
class S {
  void get value {}
}''');
  }
}
