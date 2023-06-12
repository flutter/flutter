// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConcreteClassWithAbstractMemberTest);
    defineReflectiveTests(ConcreteClassWithAbstractMemberWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConcreteClassWithAbstractMemberTest extends PubPackageResolutionTest
    with ConcreteClassWithAbstractMemberTestCases {
  test_abstract_field() async {
    await assertErrorsInCode('''
class A {
  abstract int? x;
}
''', [
      error(CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 12, 16,
          text: "'x' must have a method body because 'A' isn't abstract."),
    ]);
  }

  test_abstract_field_final() async {
    await assertErrorsInCode('''
class A {
  abstract final int? x;
}
''', [
      error(CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 12, 22,
          text: "'x' must have a method body because 'A' isn't abstract."),
    ]);
  }

  test_external_field() async {
    await assertNoErrorsInCode('''
class A {
  external int? x;
}
''');
  }

  test_external_field_final() async {
    await assertNoErrorsInCode('''
class A {
  external final int? x;
}
''');
  }

  test_setter() async {
    await assertErrorsInCode('''
class A {
  set s(int i);
}
''', [
      error(CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 12, 13,
          text: "'s' must have a method body because 'A' isn't abstract."),
    ]);
  }
}

mixin ConcreteClassWithAbstractMemberTestCases on PubPackageResolutionTest {
  test_direct() async {
    await assertErrorsInCode('''
class A {
  m();
}''', [
      error(CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 12, 4),
    ]);
  }

  test_noSuchMethod_interface() async {
    await assertErrorsInCode('''
class I {
  noSuchMethod(v) => '';
}
class A implements I {
  m();
}''', [
      error(CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 62, 4),
    ]);
  }
}

@reflectiveTest
class ConcreteClassWithAbstractMemberWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, ConcreteClassWithAbstractMemberTestCases {}
