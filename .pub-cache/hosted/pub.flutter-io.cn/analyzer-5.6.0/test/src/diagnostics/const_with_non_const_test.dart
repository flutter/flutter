// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithNonConstTest);
  });
}

@reflectiveTest
class ConstWithNonConstTest extends PubPackageResolutionTest {
  test_inConstContext() async {
    await assertErrorsInCode(r'''
class A {
  const A(x);
}
class B {
}
main() {
  const A(B());
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 57, 3),
    ]);
  }

  test_mixinApplication_constSuperConstructor() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class A {
  const A();
}
class B = A with M;
const b = const B();
''');
  }

  test_mixinApplication_constSuperConstructor_field() async {
    await assertErrorsInCode(r'''
mixin M {
  int i = 0;
}
class A {
  const A();
}
class B = A with M;
var b = const B();
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 78, 5),
    ]);
  }

  test_mixinApplication_constSuperConstructor_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get i => 0;
}
class A {
  const A();
}
class B = A with M;
var b = const B();
''');
  }

  test_mixinApplication_constSuperConstructor_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  set(int i) {}
}
class A {
  const A();
}
class B = A with M;
var b = const B();
''');
  }

  test_nonConst() async {
    await assertErrorsInCode(r'''
class T {
  T(a, b, {c, d}) {}
}
f() { return const T(0, 1, c: 2, d: 3); }
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 46, 5),
    ]);
  }
}
