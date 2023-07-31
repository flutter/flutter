// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalNotInitializedTest);
    defineReflectiveTests(FinalNotInitializedWithoutNullSafetyTest);
  });
}

@reflectiveTest
class FinalNotInitializedTest extends PubPackageResolutionTest {
  test_class_field_abstract() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
}
''');
  }

  test_class_field_abstract_with_constructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
  A();
}
''');
  }

  test_class_field_external() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
}
''');
  }

  test_class_field_external_static() async {
    await assertNoErrorsInCode('''
class A {
  external static final int x;
}
''');
  }

  test_class_field_external_with_constructor() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
  A();
}
''');
  }

  test_class_field_late_noConstructor_noInitializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f;
}
''');
  }

  test_class_field_late_unnamedConstructor_noInitializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f;
  C();
}
''');
  }

  test_class_field_noConstructor_initializer() async {
    await assertNoErrorsInCode('''
class C {
  final f = 1;
}
''');
  }

  test_class_field_noConstructor_noInitializer() async {
    await assertErrorsInCode('''
abstract class A {
  final int x;
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 31, 1),
    ]);
  }

  test_class_field_unnamedConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class C {
  final f;
  C() : f = 2;
}
''');
  }

  test_class_field_unnamedConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
class C {
  final f;
  C(this.f);
}
''');
  }

  test_class_field_unnamedConstructor_initializer() async {
    await assertNoErrorsInCode('''
class C {
  final f = 1;
  C();
}
''');
  }

  test_enum_field_constructorFieldInitializer() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  final int x;
  const E() : x = 0;
}
''');
  }

  test_enum_field_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
enum E {
  v(0);
  final int x;
  const E(this.x);
}
''');
  }

  test_enum_field_hasInitializer() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  final int x = 0;
}
''');
  }

  test_enum_field_noConstructor_noInitializer() async {
    await assertErrorsInCode('''
enum E {
  v;
  final int x;
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 26, 1),
    ]);
  }

  test_localVariable_initializer() async {
    await assertErrorsInCode('''
f() {
  late final x = 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
  }

  test_localVariable_noInitializer() async {
    await assertErrorsInCode('''
f() {
  late final x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
  }

  test_topLevel_external() async {
    await assertNoErrorsInCode('''
external final int x;
''');
  }

  test_topLevel_final() async {
    await assertErrorsInCode('''
final int x;
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 10, 1),
    ]);
  }
}

@reflectiveTest
class FinalNotInitializedWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_class_instanceField_final_factoryConstructor_only() async {
    await assertNoErrorsInCode('''
class A {
  final int x;

  factory A() => throw 0;
}''');
  }

  test_extension_static() async {
    await assertErrorsInCode('''
extension E on String {
  static final F;
}''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 39, 1),
    ]);
  }

  test_instanceField_final() async {
    await assertErrorsInCode('''
class A {
  final F;
}''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_instanceField_final_static() async {
    await assertErrorsInCode('''
class A {
  static final F;
}''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 25, 1),
    ]);
  }

  test_library_final() async {
    await assertErrorsInCode('''
final F;
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 6, 1),
    ]);
  }

  test_local_final() async {
    await assertErrorsInCode('''
f() {
  final int x;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_mixin() async {
    await assertErrorsInCode('''
mixin M {
  final int x;
}
''', [
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 22, 1),
    ]);
  }

  test_mixin_OK() async {
    await assertNoErrorsInCode(r'''
mixin M {
  final int f = 0;
}
''');
  }
}
