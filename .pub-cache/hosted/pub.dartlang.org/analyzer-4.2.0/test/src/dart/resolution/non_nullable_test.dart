// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableTest);
    defineReflectiveTests(NullableTest);
  });
}

@reflectiveTest
class NonNullableTest extends PubPackageResolutionTest {
  test_class_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');

    assertType(findNode.namedType('A {} // 1'), 'A');
    assertType(findNode.namedType('A {} // 2'), 'A');
    assertType(findNode.namedType('A {} // 3'), 'A');
  }

  test_classTypeAlias_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');

    assertType(findNode.namedType('A with'), 'A');
    assertType(findNode.namedType('B implements'), 'B');
    assertType(findNode.namedType('C;'), 'C');
  }

  test_field_functionTypeAlias() async {
    await assertNoErrorsInCode('''
typedef F = T Function<T>(int, T);

class C {
  F? f;
}
''');
    assertType(findElement.field('f').type, 'T Function<T>(int, T)?');
  }

  test_library_typeProvider_typeSystem() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await resolveTestCode(r'''
// @dart = 2.5
import 'a.dart';
''');
    var testLibrary = result.libraryElement;
    var testTypeSystem = testLibrary.typeSystem as TypeSystemImpl;
    assertType(testLibrary.typeProvider.intType, 'int*');
    expect(testTypeSystem.isNonNullableByDefault, isFalse);

    var aImport = findElement.importFind('package:test/a.dart');
    var aLibrary = aImport.importedLibrary;
    var aTypeSystem = aLibrary.typeSystem as TypeSystemImpl;
    assertType(aLibrary.typeProvider.intType, 'int');
    expect(aTypeSystem.isNonNullableByDefault, isTrue);
  }

  test_local_getterNullAwareAccess_interfaceType() async {
    await assertNoErrorsInCode(r'''
main() {
  int? x;
  return x?.isEven;
}
''');

    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_local_interfaceType() async {
    await assertErrorsInCode('''
main() {
  int? a = 0;
  int b = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
    ]);

    assertType(findNode.namedType('int? a'), 'int?');
    assertType(findNode.namedType('int b'), 'int');
  }

  test_local_interfaceType_generic() async {
    await assertErrorsInCode('''
main() {
  List<int?>? a = [];
  List<int>? b = [];
  List<int?> c = [];
  List<int> d = [];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 23, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 65, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 85, 1),
    ]);

    assertType(findNode.namedType('List<int?>? a'), 'List<int?>?');
    assertType(findNode.namedType('List<int>? b'), 'List<int>?');
    assertType(findNode.namedType('List<int?> c'), 'List<int?>');
    assertType(findNode.namedType('List<int> d'), 'List<int>');
  }

  test_local_methodNullAwareCall_interfaceType() async {
    await assertNoErrorsInCode(r'''
class C {
  bool x() => true;
}

main() {
  C? c;
  return c?.x();
}
''');

    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_local_nullCoalesceAssign_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
main() {
  int? x;
  int y = 0;
  x ??= y;
}
''');
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_local_nullCoalesceAssign_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
main() {
  int? x;
  x ??= x;
}
''');
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_local_typeParameter() async {
    await assertErrorsInCode('''
void f<T>(T a) {
  T x = a;
  T? y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);

    assertType(findNode.namedType('T x'), 'T');
    assertType(findNode.namedType('T? y'), 'T?');
  }

  test_local_variable_genericFunctionType() async {
    await assertErrorsInCode('''
main() {
  int? Function(bool, String?)? a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);

    assertType(
      findNode.genericFunctionType('Function('),
      'int? Function(bool, String?)?',
    );
  }

  test_localFunction_parameter_interfaceType() async {
    await assertErrorsInCode('''
main() {
  f(int? a, int b) {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 11, 1),
    ]);

    assertType(findNode.namedType('int? a'), 'int?');
    assertType(findNode.namedType('int b'), 'int');
  }

  test_localFunction_returnType_interfaceType() async {
    await assertErrorsInCode('''
main() {
  int? f() => 0;
  int g() => 0;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 1),
      error(HintCode.UNUSED_ELEMENT, 32, 1),
    ]);

    assertType(findNode.namedType('int? f'), 'int?');
    assertType(findNode.namedType('int g'), 'int');
  }

  test_member_potentiallyNullable_called() async {
    await resolveTestCode(r'''
m<T extends Function>() {
  List<T?> x;
  x.first();
}
''');
// Do not assert no test errors. Deliberately invokes nullable type.
    var invocation = findNode.functionExpressionInvocation('first()');
    assertType(invocation.function, 'Function?');
  }

  test_mixin_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');

    assertType(findNode.namedType('A {} // 1'), 'A');
    assertType(findNode.namedType('A {} // 2'), 'A');
  }

  test_parameter_functionTyped() async {
    await assertNoErrorsInCode('''
void f1(void p1()) {}
void f2(void p2()?) {}
void f3({void p3()?}) {}
''');
    assertType(findElement.parameter('p1').type, 'void Function()');
    assertType(findElement.parameter('p2').type, 'void Function()?');
    assertType(findElement.parameter('p3').type, 'void Function()?');
  }

  test_parameter_functionTyped_fieldFormal() async {
    await assertNoErrorsInCode('''
class A {
  var f1;
  var f2;
  var f3;
  A.f1(void this.f1());
  A.f2(void this.f2()?);
  A.f3({void this.f3()?});
}
''');
    assertType(findElement.parameter('f1').type, 'void Function()');
    assertType(findElement.parameter('f2').type, 'void Function()?');
    assertType(findElement.parameter('f3').type, 'void Function()?');
  }

  test_parameter_functionTyped_local() async {
    await assertErrorsInCode('''
f() {
  void f1(void p1()) {}
  void f2(void p2()?) {}
  void f3({void p3()?}) {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 13, 2),
      error(HintCode.UNUSED_ELEMENT, 37, 2),
      error(HintCode.UNUSED_ELEMENT, 62, 2),
    ]);
    assertType(findElement.parameter('p1').type, 'void Function()');
    assertType(findElement.parameter('p2').type, 'void Function()?');
    assertType(findElement.parameter('p3').type, 'void Function()?');
  }

  test_parameter_genericFunctionType() async {
    await assertNoErrorsInCode('''
void f(int? Function(bool, String?)? a) {
}
''');

    assertType(
      findNode.genericFunctionType('Function('),
      'int? Function(bool, String?)?',
    );
  }

  test_parameter_getterNullAwareAccess_interfaceType() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x?.isEven;
}
''');

    assertType(findNode.propertyAccess('x?.isEven'), 'bool?');
  }

  test_parameter_interfaceType() async {
    await assertNoErrorsInCode('''
void f(int? a, int b) {
}
''');

    assertType(findNode.namedType('int? a'), 'int?');
    assertType(findNode.namedType('int b'), 'int');
  }

  test_parameter_interfaceType_generic() async {
    await assertNoErrorsInCode('''
void f(List<int?>? a, List<int>? b, List<int?> c, List<int> d) {
}
''');

    assertType(findNode.namedType('List<int?>? a'), 'List<int?>?');
    assertType(findNode.namedType('List<int>? b'), 'List<int>?');
    assertType(findNode.namedType('List<int?> c'), 'List<int?>');
    assertType(findNode.namedType('List<int> d'), 'List<int>');
  }

  test_parameter_methodNullAwareCall_interfaceType() async {
    await assertNoErrorsInCode(r'''
class C {
  bool x() => true;
}

void f(C? c) {
  c?.x();
}
''');

    assertType(findNode.methodInvocation('c?.x()'), 'bool?');
  }

  test_parameter_nullCoalesceAssign_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
void f(int? x, int y) {
  x ??= y;
}
''');
    assertType(findNode.assignment('x ??= y'), 'int');
  }

  test_parameter_nullCoalesceAssign_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x ??= x;
}
''');
    assertType(findNode.assignment('x ??= x'), 'int?');
  }

  test_parameter_typeParameter() async {
    await assertNoErrorsInCode('''
void f<T>(T a, T? b) {
}
''');

    assertType(findNode.namedType('T a'), 'T');
    assertType(findNode.namedType('T? b'), 'T?');
  }

  test_typedef_classic() async {
    await assertErrorsInCode('''
typedef int? F(bool a, String? b);

main() {
  F? a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 1),
    ]);

    assertType(findNode.namedType('F? a'), 'int? Function(bool, String?)?');
  }

  test_typedef_function() async {
    await assertErrorsInCode('''
typedef F<T> = int? Function(bool, T, T?);

main() {
  F<String>? a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
    ]);

    assertType(
      findNode.namedType('F<String>'),
      'int? Function(bool, String, String?)?',
    );
  }

  test_typedef_function_nullable_element() async {
    await assertNoErrorsInCode('''
typedef F<T> = int Function(T)?;

void f(F<int> a, F<double>? b) {}
''');

    assertType(findNode.namedType('F<int>'), 'int Function(int)?');
    assertType(findNode.namedType('F<double>?'), 'int Function(double)?');
  }

  test_typedef_function_nullable_local() async {
    await assertErrorsInCode('''
typedef F<T> = int Function(T)?;

main() {
  F<int> a;
  F<double>? b;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 68, 1),
    ]);

    assertType(findNode.namedType('F<int>'), 'int Function(int)?');
    assertType(findNode.namedType('F<double>?'), 'int Function(double)?');
  }
}

@reflectiveTest
class NullableTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  @override
  bool get isNullSafetyEnabled => true;

  test_class_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}

class X1 extends A {} // 1
class X2 implements A {} // 2
class X3 with A {} // 3
''');

    assertType(findNode.namedType('A {} // 1'), 'A*');
    assertType(findNode.namedType('A {} // 2'), 'A*');
    assertType(findNode.namedType('A {} // 3'), 'A*');
  }

  test_classTypeAlias_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}

class X = A with B implements C;
''');

    assertType(findNode.namedType('A with'), 'A*');
    assertType(findNode.namedType('B implements'), 'B*');
    assertType(findNode.namedType('C;'), 'C*');
  }

  test_local_variable_interfaceType_notMigrated() async {
    await assertErrorsInCode('''
main() {
  int? a = 0;
  int b = 0;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 14, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
    ]);

    assertType(findNode.namedType('int? a'), 'int*');
    assertType(findNode.namedType('int b'), 'int*');
  }

  test_mixin_hierarchy() async {
    await assertNoErrorsInCode('''
class A {}

mixin X1 on A {} // 1
mixin X2 implements A {} // 2
''');

    assertType(findNode.namedType('A {} // 1'), 'A*');
    assertType(findNode.namedType('A {} // 2'), 'A*');
  }
}
