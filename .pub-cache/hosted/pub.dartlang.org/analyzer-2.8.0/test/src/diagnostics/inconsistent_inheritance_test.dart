// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritanceTest);
  });
}

@reflectiveTest
class InconsistentInheritanceTest extends PubPackageResolutionTest {
  /// https://github.com/dart-lang/sdk/issues/47026
  test_class_covariantInSuper_withTwoUnrelated() async {
    await assertErrorsInCode('''
class D1 {}
class D2 {}
class D implements D1, D2 {}

class A { void m(covariant D d) {} }
abstract class B1 { void m(D1 d1); }
abstract class B2 { void m(D2 d2); }
class C extends A implements B1, B2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 171, 1),
    ]);
  }

  test_class_parameterType() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 94, 1),
    ]);
  }

  test_class_parameterType_inheritedFromBase() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class C extends B implements A {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 94, 1),
    ]);
  }

  test_class_parameterType_inheritedInInterface() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends B {}
abstract class C implements A, B2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 125, 1),
    ]);
  }

  test_class_parameterType_inheritedInInterface_andMixin() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends B {}
abstract class C extends Object with A implements B2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 125, 1),
    ]);
  }

  test_class_parameterType_inheritedInInterface_andMixinApplication() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends B {}
abstract class C = Object with A implements B2;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 125, 1),
    ]);
  }

  test_class_parameterType_mixedIntoInterface() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends Object with B {}
abstract class C implements A, B2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 137, 1),
    ]);
  }

  test_class_parameterType_mixedIntoInterface_andMixin() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends Object with B {}
abstract class C extends Object with A implements B2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 137, 1),
    ]);
  }

  test_class_parameterType_twoConflictingInterfaces() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class C {
  void n(String s);
}
abstract class D implements A, B, C {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 135, 1),
    ]);
  }

  test_class_requiredParameters() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m();
}
abstract class B {
  void m(int y);
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 86, 1),
    ]);
  }

  test_class_returnType() async {
    await assertErrorsInCode(r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 82, 1),
    ]);
  }

  test_mixin_implements_parameterType() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 85, 1),
    ]);
  }

  test_mixin_implements_requiredParameters() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m();
}
abstract class B {
  void m(int y);
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 77, 1),
    ]);
  }

  test_mixin_implements_returnType() async {
    await assertErrorsInCode(r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 73, 1),
    ]);
  }

  test_mixin_on_parameterType() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 85, 1),
    ]);
  }

  test_mixin_on_requiredParameters() async {
    await assertErrorsInCode(r'''
abstract class A {
  void m();
}
abstract class B {
  void m(int y);
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 77, 1),
    ]);
  }

  test_mixin_on_returnType() async {
    await assertErrorsInCode(r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 73, 1),
    ]);
  }

  test_overrideWithDynamicParameterType_inheritsAndInterface() async {
    await assertNoErrorsInCode('''
class B {
  void m(int i) {}
}

class I {
  void m(String s) {}
}

class C extends B implements I {
  void m(dynamic d) {}
}
''');
  }

  test_overrideWithDynamicParameterType_mixinAndInterface() async {
    await assertNoErrorsInCode('''
class B {
  void m(int i) {}
}

class I {
  void m(String s) {}
}

class C extends Object with B implements I {
  void m(dynamic d) {}
}
''');
  }
}
