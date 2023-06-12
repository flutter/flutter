// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstSetElementTypeImplementsEqualsTest);
  });
}

@reflectiveTest
class ConstSetElementTypeImplementsEqualsTest extends PubPackageResolutionTest
    with ConstSetElementTypeImplementsEqualsTestCases {}

mixin ConstSetElementTypeImplementsEqualsTestCases on PubPackageResolutionTest {
  test_constField() async {
    await assertErrorsInCode(r'''
class A {
  static const a = const A();
  const A();
  operator ==(other) => false;
}
main() {
  const {A.a};
}
''', [
      error(CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 104,
          3),
    ]);
  }

  test_direct() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}
main() {
  const {const A()};
}
''', [
      error(
          CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 74, 9),
    ]);
  }

  test_dynamic() async {
    // Note: static type of B.a is "dynamic", but actual type of the const
    // object is A.  We need to make sure we examine the actual type when
    // deciding whether there is a problem with operator==.
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B {
  static const a = const A();
}
main() {
  const {B.a};
}
''', [
      error(CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 116,
          3),
    ]);
  }

  test_factory() async {
    await assertErrorsInCode(r'''
class A { const factory A() = B; }

class B implements A {
  const B();

  operator ==(o) => true;
}

main() {
  var m = const {const A()};
  print(m);
}
''', [
      error(CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 128,
          9),
    ]);
  }

  test_nestedIn_instanceCreation() async {
    await assertErrorsInCode(r'''
class A {
  const A();

  bool operator ==(other) => false;
}

class B {
  const B(_);
}

main() {
  const B({A()});
}
''', [
      error(CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 110,
          3),
    ]);
  }

  test_spread_intoList_list() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const [...[A()]];
}
''');
  }

  test_spread_intoList_set() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const [...{A()}];
}
''', [
      error(
          CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 79, 3),
    ]);
  }

  test_spread_intoSet_list() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const {...[A()]};
}
''', [
      error(
          CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 75, 8),
    ]);
  }

  test_spread_intoSet_set() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const {...{A()}};
}
''', [
      error(
          CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 79, 3),
    ]);
  }

  test_super() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B extends A {
  const B();
}
main() {
  const {const B()};
}
''', [
      error(CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS, 109,
          9),
    ]);
  }
}
