// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferenceClassTest);
  });
}

@reflectiveTest
class InstanceMemberInferenceClassTest extends PubPackageResolutionTest {
  test_field_covariant_fromField() async {
    await resolveTestCode('''
class A {
  covariant num foo = 0;
}

class B implements A {
  int foo = 0;
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int', isCovariant: true);
  }

  test_field_covariant_fromSetter() async {
    await resolveTestCode('''
class A {
  set foo(covariant num _) {}
}

class B implements A {
  int foo = 0;
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int', isCovariant: true);
  }

  test_field_fromInitializer_inherited() async {
    await resolveTestCode('''
class A {
  var foo = 0;
}

class B implements A {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int');
  }

  test_field_fromInitializer_preferSuper() async {
    await resolveTestCode('''
class A {
  num foo;
}

class B implements A {
  var foo = 0;
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'num');
  }

  test_field_multiple_fields_incompatible() async {
    await resolveTestCode('''
class A {
  int foo = throw 0;
}
class B {
  String foo = throw 0;
}
class C implements A, B {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'C');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_getters_combined() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'C');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_getters_incompatible() async {
    await resolveTestCode('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'C');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_final_combined() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
  final foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_gettersSetters_final_incompatible() async {
    await resolveTestCode('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
  final foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_final_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  int get foo;
}
abstract class B {
  set foo(num _);
}
''');

    await resolveTestCode('''
import 'a.dart';

class X implements A, B {
  final foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_gettersSetters_notFinal_combined_notSame() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
    // TODO(scheglov) error?
  }

  test_field_multiple_gettersSetters_notFinal_combined_same() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(int _) {}
}
class X implements A, B, C {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_gettersSetters_notFinal_incompatible_getters() async {
    await resolveTestCode('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(int _) {}
}
class X implements A, B, C {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_notFinal_incompatible_setters() async {
    await resolveTestCode('''
class A {
  int get foo => throw 0;
}
class B {
  set foo(String _) {}
}
class C {
  set foo(int _) {}
}
class X implements A, B, C {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldTypeDynamic(foo);
  }

  test_field_multiple_gettersSetters_notFinal_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  int get foo;
}
abstract class B {
  set foo(int _);
}
''');

    await resolveTestCode('''
import 'a.dart';

class X implements A, B {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'X');
    _assertFieldType(foo, 'int');
  }

  test_field_multiple_setters_combined() async {
    await resolveTestCode('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'C');
    _assertFieldType(foo, 'num');
  }

  test_field_multiple_setters_incompatible() async {
    await resolveTestCode('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'C');
    _assertFieldTypeDynamic(foo);
  }

  test_field_single_getter_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  int get foo;
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int');
  }

  test_field_single_setter_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  set foo(int _);
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  var foo;
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'int');
  }

  test_getter_multiple_getters_combined() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'C');
    _assertGetterType(foo, 'int');
  }

  test_getter_multiple_getters_incompatible() async {
    await resolveTestCode('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'C');
    _assertGetterTypeDynamic(foo);
  }

  test_getter_multiple_getters_same() async {
    await resolveTestCode('''
class A {
  int get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'C');
    _assertGetterType(foo, 'int');
  }

  test_getter_multiple_gettersSetters_combined() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'X');
    _assertGetterType(foo, 'int');
  }

  test_getter_multiple_gettersSetters_incompatible() async {
    await resolveTestCode('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C {
  set foo(String _) {}
}
class X implements A, B, C {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'X');
    _assertGetterTypeDynamic(foo);
  }

  test_getter_multiple_setters_combined() async {
    await resolveTestCode('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'C');
    _assertGetterType(foo, 'num');
  }

  test_getter_multiple_setters_incompatible() async {
    await resolveTestCode('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  get foo => throw 0;
}
''');
    var foo = findElement.getter('foo', of: 'C');
    _assertGetterTypeDynamic(foo);
  }

  test_getter_single_getter_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  int get foo;
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  get foo;
}
''');
    var foo = findElement.getter('foo', of: 'B');
    _assertGetterType(foo, 'int');
  }

  test_getter_single_setter_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  set foo(int _);
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  get foo;
}
''');
    var foo = findElement.getter('foo', of: 'B');
    _assertGetterType(foo, 'int');
  }

  test_invalid_field_overrides_method() async {
    await resolveTestCode('''
abstract class A {
  List<T> foo<T>() {}
}

class B implements A {
  var foo = <String, int>{};
}
''');
    var foo = findElement.field('foo', of: 'B');
    _assertFieldType(foo, 'Map<String, int>');
  }

  test_invalid_inheritanceCycle() async {
    await resolveTestCode('''
class A extends C {}
class B extends A {}
class C extends B {}
''');
  }

  test_method_parameter_covariant_named() async {
    await resolveTestCode('''
class A {
  void foo({num p}) {}
}
class B {
  void foo({covariant num p}) {}
}
class C implements A, B {
  void foo({int p}) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    _assertParameter(p, type: 'int', isCovariant: true);
  }

  test_method_parameter_covariant_positional() async {
    await resolveTestCode('''
class A {
  void foo([num p]) {}
}
class B {
  void foo([covariant num p]) {}
}
class C implements A, B {
  void foo([int p]) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    _assertParameter(p, type: 'int', isCovariant: true);
  }

  test_method_parameter_covariant_required() async {
    await resolveTestCode('''
class A {
  void foo(num p) {}
}
class B {
  void foo(covariant num p) {}
}
class C implements A, B {
  void foo(int p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    _assertParameter(p, type: 'int', isCovariant: true);
  }

  test_method_parameter_named_multiple_combined() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo({num p}) {}
}
class C implements A, B {
  void foo({p}) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'num');
  }

  test_method_parameter_named_multiple_incompatible() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo({int q}) {}
}
class C implements A, B {
  void foo({p}) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_named_multiple_same() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo({int p}) {}
}
class C implements A, B {
  void foo({p}) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_namedAndRequired() async {
    await resolveTestCode('''
class A {
  void foo({int p}) {}
}
class B {
  void foo(int p) {}
}
class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_required_multiple_combined() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo(num p) {}
}
class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'num');
  }

  test_method_parameter_required_multiple_different_merge() async {
    await resolveTestCode('''
class A {
  void foo(Object? p) {}
}

class B {
  void foo(dynamic p) {}
}

class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'Object?');
  }

  test_method_parameter_required_multiple_incompatible() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo(double p) {}
}
class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertTypeDynamic(p.type);
  }

  test_method_parameter_required_multiple_same() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo(int p) {}
}
class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_required_single_generic() async {
    await resolveTestCode('''
class A<E> {
  void foo(E p) {}
}
class C<T> implements A<T> {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'T');
  }

  test_method_parameter_required_single_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
class A {
  void foo(int p) {}
}
''');
    await resolveTestCode('''
import 'a.dart';

class B implements A {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'B').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_parameter_requiredAndPositional() async {
    await resolveTestCode('''
class A {
  void foo(int p) {}
}
class B {
  void foo([int p]) {}
}
class C implements A, B {
  void foo(p) {}
}
''');
    var p = findElement.method('foo', of: 'C').parameters[0];
    assertType(p.type, 'int');
  }

  test_method_return_multiple_different_combined() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  num foo() => 0.0;
}
class C implements A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_different_dynamic() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  foo() => 0;
}
class C implements A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_different_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => throw 0;
}
class B<E> {
  E foo() => throw 0;
}
class C implements A<int>, B<double> {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_incompatible() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  double foo() => 0.0;
}
class C implements A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertTypeDynamic(foo.returnType);
  }

  test_method_return_multiple_different_merge() async {
    await resolveTestCode('''
class A {
  Object? foo() => throw 0;
}

class B {
  dynamic foo() => throw 0;
}

class C implements A, B {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'Object?');
  }

  test_method_return_multiple_different_void() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  void foo() => 0;
}
class C implements A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => 0;
}
class B<E> {
  E foo() => 0;
}
class C<T> implements A<T>, B<T> {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'T');
  }

  test_method_return_multiple_same_nonVoid() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B {
  int foo() => 0;
}
class C implements A, B {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'int');
  }

  test_method_return_multiple_same_void() async {
    await resolveTestCode('''
class A {
  void foo() {};
}
class B {
  void foo() {};
}
class C implements A, B {
  foo() {};
}
''');
    var foo = findElement.method('foo', of: 'C');
    assertType(foo.returnType, 'void');
  }

  test_method_return_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  int foo();
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  foo();
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'int');
  }

  test_method_return_single() async {
    await resolveTestCode('''
class A {
  int foo() => 0;
}
class B extends A {
  foo() => 0;
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'int');
  }

  test_method_return_single_generic() async {
    await resolveTestCode('''
class A<E> {
  E foo() => throw 0;
}
class B<T> extends A<T> {
  foo() => throw 0;
}
''');
    var foo = findElement.method('foo', of: 'B');
    assertType(foo.returnType, 'T');
  }

  test_setter_covariant_fromSetter() async {
    await resolveTestCode('''
class A {
  set foo(num _) {}
}
class B {
  set foo(covariant num _) {}
}
class C implements A, B {
  set foo(int x) {}
}
''');
    var foo = findElement.setter('foo', of: 'C');
    _assertSetterType(foo, 'int', isCovariant: true);
  }

  test_setter_multiple_getters_combined() async {
    await resolveTestCode('''
class A {
  num get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'C');
    _assertSetterType(foo, 'int');
  }

  test_setter_multiple_getters_incompatible() async {
    await resolveTestCode('''
class A {
  String get foo => throw 0;
}
class B {
  int get foo => throw 0;
}
class C implements A, B {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'C');
    _assertSetterTypeDynamic(foo);
  }

  test_setter_multiple_gettersSetters_combined() async {
    await resolveTestCode('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C {
  String get foo => throw 0;
}
class X implements A, B, C {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'X');
    _assertSetterType(foo, 'num');
  }

  test_setter_multiple_gettersSetters_incompatible() async {
    await resolveTestCode('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C {
  int get foo => throw 0;
}
class X implements A, B, C {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'X');
    _assertSetterTypeDynamic(foo);
  }

  test_setter_multiple_setters_combined() async {
    await resolveTestCode('''
class A {
  set foo(num _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'C');
    _assertSetterType(foo, 'num');
  }

  test_setter_multiple_setters_incompatible() async {
    await resolveTestCode('''
class A {
  set foo(String _) {}
}
class B {
  set foo(int _) {}
}
class C implements A, B {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'C');
    _assertSetterTypeDynamic(foo);
  }

  test_setter_single_getter_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  int get foo;
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  set foo(_);
}
''');
    var foo = findElement.setter('foo', of: 'B');
    _assertSetterType(foo, 'int');
  }

  test_setter_single_setter_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
abstract class A {
  set foo(int _);
}
''');
    await resolveTestCode('''
import 'a.dart';

abstract class B implements A {
  set foo(_);
}
''');
    var foo = findElement.setter('foo', of: 'B');
    _assertSetterType(foo, 'int');
  }

  test_setter_single_setter_withoutParameter() async {
    await resolveTestCode('''
class A {
  set foo() {}
}
class B implements A {
  set foo(x) {}
}
''');
    var foo = findElement.setter('foo', of: 'B');
    _assertSetterType(foo, 'dynamic');
  }

  void _assertFieldType(
    FieldElement field,
    String type, {
    bool isCovariant = false,
  }) {
    expect(field.isSynthetic, isFalse);

    _assertGetterType(field.getter, type);

    var setter = field.setter;
    if (setter != null) {
      _assertSetterType(setter, type, isCovariant: isCovariant);
    }
  }

  void _assertFieldTypeDynamic(FieldElement field) {
    expect(field.isSynthetic, isFalse);

    _assertGetterTypeDynamic(field.getter);

    if (!field.isFinal) {
      _assertSetterTypeDynamic(field.setter);
    }
  }

  void _assertGetterType(PropertyAccessorElement? accessor, String expected) {
    accessor!;
    assertType(accessor.returnType, expected);
  }

  void _assertGetterTypeDynamic(PropertyAccessorElement? accessor) {
    accessor!;
    assertTypeDynamic(accessor.returnType);
  }

  void _assertParameter(
    ParameterElement element, {
    String? type,
    bool isCovariant = false,
  }) {
    assertType(element.type, type);
    expect(element.isCovariant, isCovariant);
  }

  void _assertSetterType(
    PropertyAccessorElement accessor,
    String expected, {
    bool isCovariant = false,
  }) {
    var parameter = accessor.parameters.single;
    assertType(parameter.type, expected);
    expect(parameter.isCovariant, isCovariant);
  }

  void _assertSetterTypeDynamic(PropertyAccessorElement? accessor) {
    accessor!;
    assertTypeDynamic(accessor.parameters.single.type);
  }
}
