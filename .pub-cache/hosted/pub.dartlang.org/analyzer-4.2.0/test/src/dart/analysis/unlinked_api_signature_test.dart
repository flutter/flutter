// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../ast/parse_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnitApiSignatureTest);
  });
}

@reflectiveTest
class UnitApiSignatureTest extends ParseBase {
  test_class_annotation() async {
    _assertNotSameSignature(r'''
const a = 0;

class C {}
''', r'''
const a = 0;

@a
class C {}
''');
  }

  test_class_constructor_block_to_empty() {
    _assertSameSignature(r'''
class C {
  C() {
    var v = 1;
  }
}
''', r'''
class C {
  C();
}
''');
  }

  test_class_constructor_body() {
    _assertSameSignature(r'''
class C {
  C() {
    var v = 1;
  }
}
''', r'''
class C {
  C() {
    var v = 2;
  }
}
''');
  }

  test_class_constructor_empty_to_block() {
    _assertSameSignature(r'''
class C {
  C();
}
''', r'''
class C {
  C() {
    var v = 1;
  }
}
''');
  }

  test_class_constructor_initializer_const() {
    _assertNotSameSignature(r'''
class C {
  final int f;
  const C() : f = 1;
}
''', r'''
class C {
  final int f;
  const C() : f = 2;
}
''');
  }

  test_class_constructor_initializer_empty() {
    _assertNotSameSignature(r'''
class C {
  C.foo() : ;
}
''', r'''
class C {
  C.foo() : f;
}
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/46206
  test_class_constructor_initializer_notConst() {
    _assertNotSameSignature(r'''
class C {
  final int f;
  C.foo() : f = 1;
  const C.bar();
}
''', r'''
class C {
  final int f;
  C.foo() : f = 2;
  const C.bar();
}
''');
  }

  test_class_constructor_parameters_add() {
    _assertNotSameSignature(r'''
class C {
  C(int a);
}
''', r'''
class C {
  C(int a, int b);
}
''');
  }

  test_class_constructor_parameters_remove() {
    _assertNotSameSignature(r'''
class C {
  C(int a, int b);
}
''', r'''
class C {
  C(int a);
}
''');
  }

  test_class_constructor_parameters_rename() {
    _assertNotSameSignature(r'''
class C {
  C(int a);
}
''', r'''
class C {
  C(int b);
}
''');
  }

  test_class_constructor_parameters_type() {
    _assertNotSameSignature(r'''
class C {
  C(int p);
}
''', r'''
class C {
  C(double p);
}
''');
  }

  test_class_constructor_redirectedConstructor_const() {
    _assertNotSameSignature(r'''
class A {
  const factory A() = B.foo;
}
class B implements A {
  const B.foo();
  const B.bar();
}
''', r'''
class A {
  const factory A() = B.bar;
}
class B implements A {
  const B.foo();
  const B.bar();
}
''');
  }

  test_class_constructor_redirectedConstructor_notConst() {
    _assertNotSameSignature(r'''
class A {
  factory A() = B.foo;
}
class B implements A {
  B.foo();
  B.bar();
}
''', r'''
class A {
  factory A() = B.bar;
}
class B implements A {
  B.foo();
  B.bar();
}
''');
  }

  test_class_documentation_add() async {
    _assertSameSignature(r'''
class C {}
''', r'''
/// foo
class C {}
''');
  }

  test_class_documentation_change() async {
    _assertSameSignature(r'''
/// foo
class C {}
''', r'''
/// bar bar
class C {}
''');
  }

  test_class_documentation_remove() async {
    _assertSameSignature(r'''
/// foo
class C {}
''', r'''
class C {}
''');
  }

  test_class_extends() {
    _assertNotSameSignature(r'''
class A {}
class B {}
''', r'''
class A {}
class B extends A {}
''');
  }

  /// The code `=;` is parsed as `= <emptyString>;`, and there was a bug that
  /// the absence of the redirecting constructor was encoded as the same
  /// byte sequence as the empty string. But these are different ASTs,
  /// so they should have different signatures.
  test_class_factoryConstructor_addEqNothing() {
    _assertNotSameSignature(r'''
class A {
  factory A();
}
''', r'''
class A {
  factory A() =;
}
''');
  }

  /// The token `static` is moving from the field declaration to the factory
  /// constructor (its redirected constructor), so semantically its meaning
  /// changes. But we had a bug that we put `static` into the signature
  /// at the same position, without any separator, so failed to see the
  /// difference.
  test_class_factoryConstructor_empty_to_eq() {
    _assertNotSameSignature(r'''
class A {
  factory A();
  static void foo<U>() {}
}
''', r'''
class A {
  factory A() =
  static void foo<U>() {}
}
''');
  }

  test_class_field_const_add_outOfOrder() {
    _assertNotSameSignature(r'''
class A {
  static f = Object();
}
''', r'''
class A {
  const
  static f = Object();
}
''');
  }

  test_class_field_withType_final_hasConstConstructor() {
    _assertNotSameSignature(r'''
class C {
  final int a = 1;
  const C();
}
''', r'''
class C {
  final int a = 2;
  const C();
}
''');
  }

  test_class_field_withType_final_noConstConstructor() {
    _assertSameSignature(r'''
final int a = 1;
''', r'''
final int a = 2;
''');
  }

  test_class_field_withType_hasConstConstructor() {
    _assertSameSignature(r'''
class C {
  int a = 1;
  const C();
}
''', r'''
class C {
  int a = 2;
  const C();
}
''');
  }

  test_class_field_withType_static_final_hasConstConstructor() {
    _assertSameSignature(r'''
class C {
  static final int a = 1;
  const C();
}
''', r'''
class C {
  static final int a = 2;
  const C();
}
''');
  }

  test_class_field_withType_static_hasConstConstructor() {
    _assertSameSignature(r'''
class C {
  static int a = 1;
  const C();
}
''', r'''
class C {
  static int a = 2;
  const C();
}
''');
  }

  test_class_implements() {
    _assertNotSameSignature(r'''
class A {}
class B {}
''', r'''
class A {}
class B implements A {}
''');
  }

  test_class_modifier() {
    _assertNotSameSignature(r'''
class C {}
''', r'''
abstract class C {}
''');
  }

  test_class_with() {
    _assertNotSameSignature(r'''
class A {}
class B {}
class C extends A {}
''', r'''
class A {}
class B {}
class C extends A with B {}
''');
  }

  test_classLike_field_const_add_outOfOrder_hasFinal() {
    _assertNotSameSignature_classLike(r'''
static final f = Object();
''', r'''
const
static final f = Object();
''');
  }

  test_classLike_field_final_add() {
    _assertNotSameSignature_classLike(r'''
int a = 0;
''', r'''
final int a = 0;
''');
  }

  test_classLike_field_late_add() {
    _assertNotSameSignature_classLike(r'''
int a;
''', r'''
late int a;
''');
  }

  test_classLike_field_late_remove() {
    _assertNotSameSignature_classLike(r'''
late int a;
''', r'''
int a;
''');
  }

  test_classLike_field_static_add() {
    _assertNotSameSignature_classLike(r'''
int a;
''', r'''
static int a;
''');
  }

  test_classLike_field_withoutType() {
    _assertNotSameSignature_classLike(r'''
var a = 1;
''', r'''
var a = 2;
''');
  }

  test_classLike_field_withoutType2() {
    _assertNotSameSignature_classLike(r'''
var a = 1, b = 2, c, d = 4;
''', r'''
var a = 1, b, c = 3, d = 4;
''');
  }

  test_classLike_field_withType() {
    _assertSameSignature_classLike(r'''
int a = 1;
''', r'''
int a = 2;
''');
  }

  test_classLike_field_withType_const() {
    _assertNotSameSignature_classLike(r'''
static const int a = 1;
''', r'''
static const int a = 2;
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_false_differentName() {
    _assertSameSignature_classLike(r'''
void foo() {
  super.bar();
}
''', r'''
void foo() {
  super.bar2();
}
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_falseToTrue() {
    _assertNotSameSignature_classLike(r'''
void foo() {}
''', r'''
void foo() {
  super.foo();
}
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_trueToFalse_assignmentExpression() {
    _assertNotSameSignature_classLike(r'''
set foo(int _) {
  super.foo = 0;
}
''', r'''
set foo(int _) {}
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_trueToFalse_binaryExpression() {
    _assertNotSameSignature_classLike(r'''
int operator +() {
  super + 2;
  return 0;
}
''', r'''
int operator +() {
  return 0;
}
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_trueToFalse_differentName() {
    _assertNotSameSignature_classLike(r'''
void foo() {
  super.foo();
}
''', r'''
void foo() {
  super.bar();
}
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_trueToFalse_methodInvocation() {
    _assertNotSameSignature_classLike(r'''
void foo() {
  super.foo();
}
''', r'''
void foo() {}
''');
  }

  test_classLike_method_body_block_invokesSuperSelf_trueToFalse_propertyAccess() {
    _assertNotSameSignature_classLike(r'''
void foo() {
  super.foo;
}
''', r'''
void foo() {}
''');
  }

  test_classLike_method_body_block_to_empty() {
    _assertNotSameSignature_classLike(r'''
void foo() {}
''', r'''
void foo();
''');
  }

  test_classLike_method_body_empty_to_block() {
    _assertNotSameSignature_classLike(r'''
void foo();
''', r'''
void foo() {}
''');
  }

  test_classLike_method_body_empty_to_expression() {
    _assertNotSameSignature_classLike(r'''
int foo();
''', r'''
int foo() => 0;
''');
  }

  test_classLike_method_body_expression_invokesSuperSelf_trueToFalse_methodInvocation() {
    _assertNotSameSignature_classLike(r'''
void foo() => super.foo();
''', r'''
void foo() => 0;
''');
  }

  test_classLike_method_getter_body_block_to_empty() {
    _assertNotSameSignature_classLike(r'''
int get foo {
  return 1;
}
''', r'''
int get foo;
''');
  }

  test_classLike_method_getter_body_empty_to_block() {
    _assertNotSameSignature_classLike(r'''
int get foo;
''', r'''
int get foo {
  return 0;
}
''');
  }

  test_classLike_method_getter_body_empty_to_expression() {
    _assertNotSameSignature_classLike(r'''
int get foo;
''', r'''
int get foo => 0;
''');
  }

  test_classLike_method_getter_body_expression_to_empty() {
    _assertNotSameSignature_classLike(r'''
int get foo => 0;
''', r'''
int get foo;
''');
  }

  test_classLike_method_setter_body_block_to_empty() {
    _assertNotSameSignature_classLike(r'''
set foo(_) {}
''', r'''
set foo(_);
''');
  }

  test_classLike_method_setter_body_empty_to_block() {
    _assertNotSameSignature_classLike(r'''
set foo(_);
''', r'''
set foo(_) {}
''');
  }

  test_commentAdd() {
    _assertSameSignature(r'''
var a = 1;
var b = 2;
var c = 3;
''', r'''
var a = 1; // comment

/// comment 1
/// comment 2
var b = 2;

/**
 *  Comment
 */
var c = 3;
''');
  }

  test_commentRemove() {
    _assertSameSignature(r'''
var a = 1; // comment

/// comment 1
/// comment 2
var b = 2;

/**
 *  Comment
 */
var c = 3;
''', r'''
var a = 1;
var b = 2;
var c = 3;
''');
  }

  test_directive_library_add() {
    _assertNotSameSignature(r'''
class A {}
''', r'''
library foo;
class A {}
''');
  }

  test_directive_library_change_name() {
    _assertNotSameSignature(r'''
library foo;
class A {}
''', r'''
library bar;
class A {}
''');
  }

  test_directive_library_change_name_length() {
    _assertSameSignature(r'''
library foo.bar;
class A {}
''', r'''
library foo. bar;
class A {}
''');
  }

  test_directive_library_change_name_offset() {
    _assertSameSignature(r'''
library foo;
class A {}
''', r'''
library  foo;
class A {}
''');
  }

  test_directive_library_remove() {
    _assertNotSameSignature(r'''
library foo;
class A {}
''', r'''
class A {}
''');
  }

  test_enum_enumConstants_add() {
    _assertNotSameSignature(r'''
enum E {
  v
}
''', r'''
enum E {
  v, v2
}
''');
  }

  test_enum_enumConstants_add_hasMethod() {
    _assertNotSameSignature(r'''
enum E {
  v;
  void foo() {}
}
''', r'''
enum E {
  v, v2;
  void foo() {}
}
''');
  }

  test_enum_enumConstants_constructorArguments_add() {
    _assertNotSameSignature(r'''
enum E {
  v;
  E({int? a});
}
''', r'''
enum E {
  v(a: 0);
  E({int? a});
}
''');
  }

  test_enum_enumConstants_constructorArguments_change() {
    _assertNotSameSignature(r'''
enum E {
  v(0);
  E(int a);
}
''', r'''
enum E {
  v(1);
  E(int a);
}
''');
  }

  test_enum_enumConstants_constructorArguments_remove() {
    _assertNotSameSignature(r'''
enum E {
  v(a: 0);
  E({int? a});
}
''', r'''
enum E {
  v;
  E({int? a});
}
''');
  }

  test_enum_enumConstants_remove() {
    _assertNotSameSignature(r'''
enum E {
  v, v2
}
''', r'''
enum E {
  v
}
''');
  }

  test_enum_enumConstants_rename() {
    _assertNotSameSignature(r'''
enum E {
  v
}
''', r'''
enum E {
  v2
}
''');
  }

  test_enum_field_withType_final() {
    _assertNotSameSignature(r'''
enum E {
  v;
  final int a = 1;
}
''', r'''
enum E {
  v;
  final int a = 2;
}
''');
  }

  test_enum_implements_add() {
    _assertNotSameSignature(r'''
class A {}
enum E {
  v
}
''', r'''
class A {}
enum E implements A {
  v
}
''');
  }

  test_enum_implements_change() {
    _assertNotSameSignature(r'''
class A {}
class B {}
enum E implements A {
  v
}
''', r'''
class A {}
class B {}
enum E implements B {
  v
}
''');
  }

  test_enum_implements_remove() {
    _assertNotSameSignature(r'''
class A {}
enum E implements A {
  v
}
''', r'''
class A {}
enum E {
  v
}
''');
  }

  test_enum_metadata_add() {
    _assertNotSameSignature(r'''
enum E {
  v
}
''', r'''
@a
enum E {
  v
}
''');
  }

  test_enum_typeParameters_add() {
    _assertNotSameSignature(r'''
enum E {
  v
}
''', r'''
enum E<T> {
  v
}
''');
  }

  test_enum_typeParameters_remove() {
    _assertNotSameSignature(r'''
enum E<T> {
  v
}
''', r'''
enum E {
  v
}
''');
  }

  test_enum_typeParameters_rename() {
    _assertNotSameSignature(r'''
enum E<T> {
  v
}
''', r'''
enum E<U> {
  v
}
''');
  }

  test_enum_with_add() {
    _assertNotSameSignature(r'''
mixin M {}
enum E {
  v
}
''', r'''
mixin M {}
enum E with M {
  v
}
''');
  }

  test_enum_with_change() {
    _assertNotSameSignature(r'''
mixin M1 {}
mixin M2 {}
enum E with M1 {
  v
}
''', r'''
mixin M1 {}
mixin M2 {}
enum E with M2 {
  v
}
''');
  }

  test_enum_with_remove() {
    _assertNotSameSignature(r'''
mixin M {}
enum E with M {
  v
}
''', r'''
mixin M {}
enum E {
  v
}
''');
  }

  test_executable_annotation() {
    _assertNotSameSignature_executable(r'''
void foo() {}
''', r'''
@a
void foo() {}
''');
  }

  test_executable_body_async_to_asyncStar() {
    _assertNotSameSignature_executable(r'''
foo() async {}
''', r'''
foo() async* {}
''');
  }

  test_executable_body_async_to_sync() {
    _assertNotSameSignature_executable(r'''
foo() async {}
''', r'''
foo() {}
''');
  }

  test_executable_body_asyncStar_to_async() {
    _assertNotSameSignature_executable(r'''
foo() async* {}
''', r'''
foo() async {}
''');
  }

  test_executable_body_asyncStar_to_syncStar() {
    _assertNotSameSignature_executable(r'''
foo() async* {}
''', r'''
foo() sync* {}
''');
  }

  test_executable_body_block() {
    _assertSameSignature_executable(r'''
int foo() {
  return 1;
}
''', r'''
int foo() {
  return 2;
}
''');
  }

  test_executable_body_block_to_expression() {
    _assertSameSignature_executable(r'''
int foo() {
  return 1;
}
''', r'''
int foo() => 2;
''');
  }

  test_executable_body_block_to_native() {
    _assertNotSameSignature_executable(r'''
int foo() {
  return 0;
}
''', r'''
int foo() native;
''');
  }

  test_executable_body_expression() {
    _assertSameSignature_executable(r'''
int foo() => 1;
''', r'''
int foo() => 2;
''');
  }

  test_executable_body_expression_to_block() {
    _assertSameSignature_executable(r'''
int foo() => 1;
''', r'''
int foo() {
  return 2;
}
''');
  }

  test_executable_body_expression_to_native() {
    _assertNotSameSignature_executable(r'''
int foo() => 0;
''', r'''
int foo() native;
''');
  }

  test_executable_body_native_to_block() {
    _assertNotSameSignature_executable(r'''
int foo() native;
''', r'''
int foo() {
  return 0;
}
''');
  }

  test_executable_body_native_to_expression() {
    _assertNotSameSignature_executable(r'''
int foo() native;
''', r'''
int foo() => 0;
''');
  }

  test_executable_body_sync_to_async() {
    _assertNotSameSignature_executable(r'''
foo() {}
''', r'''
foo() async {}
''');
  }

  test_executable_body_sync_to_syncStar() {
    _assertNotSameSignature_executable(r'''
foo() sync* {}
''', r'''
foo() {}
''');
  }

  test_executable_body_syncStar_to_sync() {
    _assertNotSameSignature_executable(r'''
foo() sync* {}
''', r'''
foo() {}
''');
  }

  test_executable_getter_body_block_to_expression() {
    _assertSameSignature_executable(r'''
int get foo {
  return 1;
}
''', r'''
int get foo => 2;
''');
  }

  test_executable_getter_body_expression_to_block() {
    _assertSameSignature_executable(r'''
int get foo => 1;
''', r'''
int get foo {
  return 2;
}
''');
  }

  test_executable_parameters_add() {
    _assertNotSameSignature_executable(r'''
foo(int a) {}
''', r'''
foo(int a, int b) {}
''');
  }

  test_executable_parameters_remove() {
    _assertNotSameSignature_executable(r'''
foo(int a, int b) {}
''', r'''
foo(int a) {}
''');
  }

  test_executable_parameters_rename() {
    _assertNotSameSignature_executable(r'''
void foo(int a) {}
''', r'''
void foo(int b) {}
''');
  }

  test_executable_parameters_type() {
    _assertNotSameSignature_executable(r'''
void foo(int p) {}
''', r'''
void foo(double p) {}
''');
  }

  test_executable_returnType() {
    _assertNotSameSignature_executable(r'''
int foo() => 0;
''', r'''
num foo() => 0;
''');
  }

  test_executable_typeParameters_add() async {
    _assertNotSameSignature_executable(r'''
void foo() {}
''', r'''
void foo<T>() {}
''');
  }

  test_executable_typeParameters_remove() {
    _assertNotSameSignature_executable(r'''
void foo<T>() {}
''', r'''
void foo() {}
''');
  }

  test_executable_typeParameters_rename() {
    _assertNotSameSignature_executable(r'''
void foo<T>() {}
''', r'''
void foo<U>() {}
''');
  }

  test_extension_on() {
    _assertNotSameSignature(r'''
extension E on int {}
''', r'''
extension E on num {}
''');
  }

  test_extension_typeParameter_add() {
    _assertNotSameSignature(r'''
extension E on int {}
''', r'''
extension E<T> on int {}
''');
  }

  test_extension_typeParameter_remove() {
    _assertNotSameSignature(r'''
extension E<T> on int {}
''', r'''
extension E on int {}
''');
  }

  test_extension_typeParameter_rename() {
    _assertNotSameSignature(r'''
extension E<T> on int {}
''', r'''
extension E<U> on int {}
''');
  }

  test_featureSet_add() async {
    _assertNotSameSignature(r'''
class A {}
''', r'''
// @dart = 2.5
class A {}
''');
  }

  test_featureSet_change() async {
    _assertNotSameSignature(r'''
// @dart = 2.6
class A {}
''', r'''
// @dart = 2.2
class A {}
''');
  }

  test_featureSet_remove() async {
    _assertNotSameSignature(r'''
// @dart = 2.5
class A {}
''', r'''
class A {}
''');
  }

  test_issue34850() {
    _assertNotSameSignature(r'''
foo
Future<List<int>> bar() {}
''', r'''
foo
Future<List<int>> bar(int x) {}
''');
  }

  test_mixin_field_withoutType() {
    _assertNotSameSignature(r'''
mixin M {
  var a = 1;
}
''', r'''
mixin M {
  var a = 2;
}
''');
  }

  test_mixin_field_withType() {
    _assertSameSignature(r'''
mixin M {
  int a = 1;
}
''', r'''
mixin M {
  int a = 2;
}
''');
  }

  test_mixin_implements() {
    _assertNotSameSignature(r'''
class A {}
mixin M {}
''', r'''
class A {}
mixin M implements A {}
''');
  }

  test_mixin_method_body_block() {
    _assertSameSignature(r'''
mixin M {
  int foo() {
    return 1;
  }
}
''', r'''
mixin M {
  int foo() {
    return 2;
  }
}
''');
  }

  test_mixin_method_body_expression() {
    _assertSameSignature(r'''
mixin M {
  int foo() => 1;
}
''', r'''
mixin M {
  int foo() => 2;
}
''');
  }

  test_mixin_on() {
    _assertNotSameSignature(r'''
class A {}
mixin M {}
''', r'''
class A {}
mixin M on A {}
''');
  }

  test_topLevelVariable_final_add() {
    _assertNotSameSignature(r'''
int a = 0;
''', r'''
final int a = 0;
''');
  }

  test_topLevelVariable_late_add() {
    _assertNotSameSignature(r'''
int a;
''', r'''
late int a;
''');
  }

  test_topLevelVariable_late_remove() {
    _assertNotSameSignature(r'''
late int a;
''', r'''
int a;
''');
  }

  test_topLevelVariable_withoutType() {
    _assertNotSameSignature(r'''
var a = 1;
''', r'''
var a = 2;
''');
  }

  test_topLevelVariable_withoutType2() {
    _assertNotSameSignature(r'''
var a = 1, b = 2, c, d = 4;;
''', r'''
var a = 1, b, c = 3, d = 4;;
''');
  }

  test_topLevelVariable_withType() {
    _assertSameSignature(r'''
int a = 1;
''', r'''
int a = 2;
''');
  }

  test_topLevelVariable_withType_const() {
    _assertNotSameSignature(r'''
const int a = 1;
''', r'''
const int a = 2;
''');
  }

  test_topLevelVariable_withType_final() {
    _assertSameSignature(r'''
final int a = 1;
''', r'''
final int a = 2;
''');
  }

  test_topLevelVariable_withType_initializer_add() {
    _assertNotSameSignature(r'''
int a;
''', r'''
int a = 1;
''');
  }

  test_topLevelVariable_withType_initializer_remove() {
    _assertNotSameSignature(r'''
int a = 1;
''', r'''
int a;
''');
  }

  test_typedef_generic_parameters_type() {
    _assertNotSameSignature(r'''
typedef F = void Function(int);
''', r'''
typedef F = void Function(double);
''');
  }

  void _assertNotSameSignature(String oldCode, String newCode) {
    _assertSignature(oldCode, newCode, same: false);
  }

  void _assertNotSameSignature_classLike(String oldCode, String newCode) {
    _assertSignature_classLike(oldCode, newCode, same: false);
  }

  void _assertNotSameSignature_executable(String oldCode, String newCode) {
    _assertSignature_executable(oldCode, newCode, same: false);
  }

  void _assertSameSignature(String oldCode, String newCode) {
    _assertSignature(oldCode, newCode, same: true);
  }

  void _assertSameSignature_classLike(String oldCode, String newCode) {
    _assertSignature_classLike(oldCode, newCode, same: true);
  }

  void _assertSameSignature_executable(String oldCode, String newCode) {
    _assertSignature_executable(oldCode, newCode, same: true);
  }

  void _assertSignature(String oldCode, String newCode, {required bool same}) {
    var path = convertPath('/test.dart');

    newFile(path, oldCode);
    var oldUnit = parseUnit(path).unit;
    var oldSignature = computeUnlinkedApiSignature(oldUnit);

    newFile(path, newCode);
    var newUnit = parseUnit(path).unit;
    var newSignature = computeUnlinkedApiSignature(newUnit);

    if (same) {
      expect(newSignature, oldSignature);
    } else {
      expect(newSignature, isNot(oldSignature));
    }
  }

  void _assertSignature_classLike(
    String oldCode,
    String newCode, {
    required bool same,
  }) {
    _assertSignature('''
class A {
$oldCode
}
''', '''
class A {
$newCode
}
''', same: same);

    _assertSignature('''
extension on int {
$oldCode
}
''', '''
extension on int {
$newCode
}
''', same: same);

    _assertSignature('''
mixin M {
$oldCode
}
''', '''
mixin M {
$newCode
}
''', same: same);

    _assertSignature('''
enum E {
  v;
$oldCode
}
''', '''
enum E {
  v;
$newCode
}
''', same: same);
  }

  void _assertSignature_executable(String oldCode, String newCode,
      {required bool same}) {
    _assertSignature_classLike(oldCode, newCode, same: same);
    _assertSignature(oldCode, newCode, same: same);
  }
}
