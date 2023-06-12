// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidElementTypeTest);
  });
}

@reflectiveTest
class ForInOfInvalidElementTypeTest extends PubPackageResolutionTest {
  test_await_declaredVariable_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic a) async {
  await for (int i in a) {
    i;
  }
}
''');
  }

  test_await_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f(Stream<String> stream) async {
  await for (int i in stream) {
    i;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 55, 6),
    ]);
  }

  test_await_existingVariableWrongType() async {
    await assertErrorsInCode('''
f(Stream<String> stream) async {
  int i;
  await for (i in stream) {
    i;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 60, 6),
    ]);
  }

  test_bad_type_bound() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {
      i;
    }
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 86, 8),
    ]);
  }

  test_declaredVariable_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic a) {
  for (int i in a) {
    i;
  }
}
''');
  }

  test_declaredVariable_implicitCallReference() async {
    await assertNoErrorsInCode('''
class C {
  void call() {}
}
void foo(C c) {
  for (void Function() f in [c]) {
    f;
  }
}
''');
  }

  test_declaredVariable_implicitCallReference_genericFunctionInstantiation() async {
    await assertNoErrorsInCode('''
class C {
  void call<T>(T p) {}
}
void foo(C c) {
  for (void Function(int) f in [c]) {
    f;
  }
}
''');
  }

  test_declaredVariable_interfaceTypeTypedef_ok() async {
    await assertNoErrorsInCode('''
typedef S = String;
f() {
  for (S i in <String>[]) {
    i;
  }
}
''');
  }

  test_declaredVariable_ok() async {
    await assertNoErrorsInCode('''
f() {
  for (String i in <String>[]) {
    i;
  }
}
''');
  }

  test_declaredVariable_wrongType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <String>[]) {
    i;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 22, 10),
    ]);
  }

  test_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <String>[]) {
    i;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 27, 10),
    ]);
  }

  test_implicitCallReference() async {
    await assertNoErrorsInCode('''
class C {
  void call(int a) {}
}
void foo(Iterable<C> iterable) {
  void Function(int) f;
  for (f in iterable) {
    f;
  }
}
''');
  }

  test_implicitCallReference_genericFunctionInstantiation() async {
    await assertNoErrorsInCode('''
class C {
  void call<T>(T p) {}
}
void foo(Iterable<C> iterable) {
  void Function(int) f;
  for (f in iterable) {
    f;
  }
}
''');
  }

  test_implicitCallReference_unassignableFunctionType() async {
    await assertErrorsInCode('''
class C {
  void call(int a) {}
}
void foo(Iterable<C> iterable) {
  void Function(String) f;
  for (f in iterable) {
    f;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 106, 8),
    ]);
  }
}
