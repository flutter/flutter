// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstMapKeyNotPrimitiveEqualityTest);
  });
}

@reflectiveTest
class ConstMapKeyNotPrimitiveEqualityTest extends PubPackageResolutionTest {
  test_declaresEqEq_abstract() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  bool operator==(Object other);
}

main() {
  const {const A(): 0};
}
''');
  }

  test_implementsEqEq_direct() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

main() {
  const {const A() : 0};
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 75, 9),
    ]);
  }

  test_implementsEqEq_double() async {
    await assertErrorsInCode(r'''
main() {
  const {double.infinity: 0};
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 18, 15),
    ]);
  }

  test_implementsEqEq_dynamic() async {
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
  const {B.a : 0};
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 118, 3),
    ]);
  }

  test_implementsEqEq_factory() async {
    await assertErrorsInCode(r'''
class A {
  const factory A() = B;
}

class B implements A {
  const B();
  operator ==(o) => true;
}

main() {
  const {const A(): 42};
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 121, 9),
    ]);
  }

  test_implementsEqEq_nestedIn_instanceCreation() async {
    await assertErrorsInCode(r'''
class A {
  const A();

  bool operator ==(other) => false;
}

class B {
  const B(_);
}

main() {
  const B({A(): 0});
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 110, 3),
    ]);
  }

  test_implementsEqEq_record_named() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

const x = {
  (a: 0, b: const A()): 0,
};
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 71, 20),
    ]);
  }

  test_implementsEqEq_record_positional() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

const x = {
  (0, const A()): 0,
};
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 71, 14),
    ]);
  }

  test_implementsEqEq_super() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  operator ==(other) => false;
}

class B extends A {
  const B();
}

main() {
  const {const B() : 0};
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 111, 9),
    ]);
  }

  test_implementsHashCode_direct() async {
    await assertErrorsInCode(r'''
const v = {A(): 0};

class A {
  const A();
  int get hashCode => 0;
}
''', [
      error(CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY, 11, 3),
    ]);
  }

  test_implementsNone_record_named() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const x = {
  (a: 0, b: const A()): 0,
};
''');
  }

  test_implementsNone_record_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const x = {
  (0, const A()): 0,
};
''');
  }
}
