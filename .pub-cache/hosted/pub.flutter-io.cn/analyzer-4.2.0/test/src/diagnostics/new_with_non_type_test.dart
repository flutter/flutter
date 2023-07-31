// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithNonTypeTest);
  });
}

@reflectiveTest
class NewWithNonTypeTest extends PubPackageResolutionTest {
  test_functionTypeAlias() async {
    await assertErrorsInCode('''
typedef F = void Function();

void foo() {
  new F();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 49, 1),
    ]);
  }

  test_imported() async {
    newFile('$testPackageLibPath/lib.dart', '''
class B {}
''');
    await assertErrorsInCode('''
import 'lib.dart' as lib;
void f() {
  new lib.A();
}
lib.B b = lib.B();
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 47, 1),
    ]);
  }

  test_local() async {
    await assertErrorsInCode('''
var A = 0;
void f() {
  new A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 28, 1),
    ]);
  }

  test_malformed_constructor_call() async {
    await assertErrorsInCode('''
class C {
  C.x();
}
main() {
  new C.x.y();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 36, 3),
    ]);
  }

  test_typeParameter() async {
    await assertErrorsInCode('''
void foo<T>() {
  new T();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 22, 1),
    ]);
  }
}
