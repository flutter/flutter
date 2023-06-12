// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest);
    defineReflectiveTests(NonErrorResolverWithoutNullSafetyTest);
  });
}

@reflectiveTest
class NonErrorResolverTest extends PubPackageResolutionTest
    with NonErrorResolverTestCases {
  test_await_flattened() async {
    await assertNoErrorsInCode('''
Future<Future<int>>? ffi() => null;
f() async {
  Future<int>? b = await ffi();
  b;
}
''');
  }

  test_conflictingStaticGetterAndInstanceSetter_thisClass() async {
    await assertErrorsInCode(r'''
class A {
  static get x => 0;
  static set x(int p) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 23, 1),
    ]);
  }

  test_const_constructor_with_named_generic_parameter() async {
    await assertNoErrorsInCode('''
class C<T> {
  const C({required T t});
}
const c = const C(t: 1);
''');
  }

  test_inconsistentMethodInheritance_accessors_typeParameters1() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {
  E? get x;
}
abstract class B<E> {
  E? get x;
}
class C<E> implements A<E>, B<E> {
  E? get x => null;
}
''');
  }

  test_inconsistentMethodInheritance_accessors_typeParameters2() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {
  E? get x {return null;}
}
class B<E> {
  E? get x {return null;}
}
class C<E> extends A<E> implements B<E> {}
''');
  }

  test_inconsistentMethodInheritance_accessors_typeParameters_diamond() async {
    await assertNoErrorsInCode(r'''
abstract class F<E> extends B<E> {}
class D<E> extends F<E> {
  external E? get g;
}
abstract class C<E> {
  E? get g;
}
abstract class B<E> implements C<E> {
  E? get g { return null; }
}
class A<E> extends B<E> implements D<E> {
}
''');
  }

  test_typedef_not_function() async {
    newFile('$testPackageLibPath/a.dart', content: '''
typedef F = int;
''');
    await assertNoErrorsInCode('''
import 'a.dart';
F f = 0;
''');
  }
}

mixin NonErrorResolverTestCases on PubPackageResolutionTest {
  test_ambiguousExport() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library lib1;
class M {}
''');
    newFile("$testPackageLibPath/lib2.dart", content: r'''
library lib2;
class N {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart';
''');
  }

  test_ambiguousExport_combinators_hide() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library L1;
class A {}
class B {}
''');
    newFile("$testPackageLibPath/lib2.dart", content: r'''
library L2;
class B {}
class C {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' hide B;
''');
  }

  test_ambiguousExport_combinators_show() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library L1;
class A {}
class B {}
''');
    newFile("$testPackageLibPath/lib2.dart", content: r'''
library L2;
class B {}
class C {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' show C;
''');
  }

  test_ambiguousExport_sameDeclaration() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
class N {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib.dart';
export 'lib.dart';
''');
  }

  test_ambiguousImport_dart_implicitHide() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
class Future {
  static const zero = 0;
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart';
main() {
  print(Future.zero);
}
''');
  }

  test_ambiguousImport_hideCombinator() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library lib1;
class N {}
class N1 {}
''');
    newFile("$testPackageLibPath/lib2.dart", content: r'''
library lib2;
class N {}
class N2 {}
''');
    newFile("$testPackageLibPath/lib3.dart", content: r'''
library lib3;
class N {}
class N3 {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart' hide N;
main() {
  new N1();
  new N2();
  new N3();
}
''');
  }

  test_ambiguousImport_showCombinator() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library lib1;
class N {}
class N1 {}
''');
    newFile("$testPackageLibPath/lib2.dart", content: r'''
library lib2;
class N {}
class N2 {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib2.dart' show N, N2;
main() {
  new N1();
  new N2();
}
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 44, 1),
    ]);
  }

  test_annotated_partOfDeclaration() async {
    newFile('$testPackageLibPath/part.dart', content: '''
@deprecated part of L;
''');
    await assertNoErrorsInCode('''
library L; part "part.dart";
''');
  }

  test_argumentTypeNotAssignable_classWithCall_Function() async {
    await assertNoErrorsInCode(r'''
caller(Function callee) {
  callee();
}

class CallMeBack {
  call() => 0;
}

main() {
  caller(new CallMeBack());
}
''');
  }

  test_argumentTypeNotAssignable_fieldFormalParameterElement_member() async {
    await assertNoErrorsInCode(r'''
class ObjectSink<T> {
  void sink(T object) {
    new TimestampedObject<T>(object);
  }
}
class TimestampedObject<E> {
  E object2;
  TimestampedObject(this.object2);
}
''');
  }

  test_argumentTypeNotAssignable_invocation_functionParameter_generic() async {
    await assertNoErrorsInCode(r'''
class A<K> {
  m(f(K k), K v) {
    f(v);
  }
}
''');
  }

  test_argumentTypeNotAssignable_invocation_typedef_generic() async {
    await assertNoErrorsInCode(r'''
typedef A<T>(T p);
f(A<int> a) {
  a(1);
}
''');
  }

  test_argumentTypeNotAssignable_Object_Function() async {
    await assertNoErrorsInCode(r'''
main() {
  process(() {});
}
process(Object x) {}''');
  }

  test_argumentTypeNotAssignable_optionalNew() async {
    await assertNoErrorsInCode(r'''
class Widget { }

class MaterialPageRoute {
  final Widget Function() builder;
  const MaterialPageRoute({this.builder = f});
}

Widget f() => Widget();

void main() {
  MaterialPageRoute(builder: () {
      return Widget();
    },
  );
}
''');
  }

  test_argumentTypeNotAssignable_typedef_local() async {
    await assertNoErrorsInCode(r'''
typedef A(int p1, String p2);
A getA() => (int p1, String p2) {};
f() {
  A a = getA();
  a(1, '2');
}
''');
  }

  test_argumentTypeNotAssignable_typedef_parameter() async {
    await assertNoErrorsInCode(r'''
typedef A(int p1, String p2);
f(A a) {
  a(1, '2');
}
''');
  }

  test_assert_with_message_await() async {
    await assertNoErrorsInCode('''
f() async {
  assert(false, await g());
}
Future<String> g() => Future.value('');
''');
  }

  test_assert_with_message_dynamic() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, g());
}
g() => null;
''');
  }

  test_assert_with_message_non_string() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, 3);
}
''');
  }

  test_assert_with_message_null() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, null);
}
''');
  }

  test_assert_with_message_string() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, 'message');
}
''');
  }

  test_assert_with_message_suppresses_unused_var_hint() async {
    await assertNoErrorsInCode('''
f() {
  String message = 'msg';
  assert(true, message);
}
''');
  }

  test_assignability_function_expr_rettype_from_typedef_cls() async {
    // In the code below, the type of (() => f()) has a return type which is
    // a class, and that class is inferred from the return type of the typedef
    // F.
    await assertNoErrorsInCode('''
class C {}
typedef C F();
F f = () => C();
main() {
  F f2 = (() => f());
  f2;
}
''');
  }

  test_assignability_function_expr_rettype_from_typedef_typedef() async {
    // In the code below, the type of (() => f()) has a return type which is
    // a typedef, and that typedef is inferred from the return type of the
    // typedef F.
    await assertNoErrorsInCode('''
typedef G F();
typedef G();
F f = () => () => {};
main() {
  F f2 = (() => f());
  f2;
}
''');
  }

  test_assignmentToFinal_prefixNegate() async {
    await assertErrorsInCode(r'''
f() {
  final x = 0;
  -x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
    ]);
  }

  test_assignmentToFinalNoSetter_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(v) {}
}
main() {
  A a = new A();
  a.x = 0;
}
''');
  }

  test_assignmentToFinalNoSetter_propertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(v) {}
}
class B {
  static A a = A();
}
main() {
  B.a.x = 0;
}
''');
  }

  test_assignmentToFinals_importWithPrefix() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library lib1;
bool x = false;''');
    await assertNoErrorsInCode(r'''
library lib;
import 'lib1.dart' as foo;
main() {
  foo.x = true;
}
''');
  }

  test_async_dynamic_with_return() async {
    await assertNoErrorsInCode('''
dynamic f() async {
  return;
}
''');
  }

  test_async_dynamic_with_return_value() async {
    await assertNoErrorsInCode('''
dynamic f() async {
  return 5;
}
''');
  }

  test_async_dynamic_without_return() async {
    await assertNoErrorsInCode('''
dynamic f() async {}
''');
  }

  test_async_expression_function_type() async {
    await assertErrorsInCode('''
typedef Future<int> F(int i);
main() {
  F f = (int i) async => i;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
    ]);
  }

  test_async_flattened() async {
    await assertNoErrorsInCode('''
typedef Future<int> CreatesFutureInt();
main() {
  CreatesFutureInt createFutureInt = () async => f();
  Future<int> futureInt = createFutureInt();
  futureInt.then((int i) => print(i));
}
Future<int> f() => Future.value(0);
''');
  }

  test_async_future_dynamic_with_return() async {
    await assertNoErrorsInCode('''
Future<dynamic> f() async {
  return;
}
''');
  }

  test_async_future_dynamic_with_return_value() async {
    await assertNoErrorsInCode('''
Future<dynamic> f() async {
  return 5;
}
''');
  }

  test_async_future_dynamic_without_return() async {
    await assertNoErrorsInCode('''
Future<dynamic> f() async {}
''');
  }

  test_async_future_int_with_return_future_int() async {
    await assertNoErrorsInCode('''
Future<int> f() async {
  return new Future<int>.value(5);
}
''');
  }

  test_async_future_int_with_return_value() async {
    await assertNoErrorsInCode('''
Future<int> f() async {
  return 5;
}
''');
  }

  test_async_future_null_with_return() async {
    await assertNoErrorsInCode('''
Future<Null> f() async {
  return;
}
''');
  }

  test_async_future_null_without_return() async {
    await assertNoErrorsInCode('''
Future<Null> f() async {}
''');
  }

  test_async_future_object_with_return_value() async {
    await assertNoErrorsInCode('''
Future<Object> f() async {
  return 5;
}
''');
  }

  test_async_future_with_return() async {
    await assertNoErrorsInCode('''
Future f() async {
  return;
}
''');
  }

  test_async_future_with_return_value() async {
    await assertNoErrorsInCode('''
Future f() async {
  return 5;
}
''');
  }

  test_async_future_without_return() async {
    await assertNoErrorsInCode('''
Future f() async {}
''');
  }

  test_async_with_return() async {
    await assertNoErrorsInCode('''
f() async {
  return;
}
''');
  }

  test_async_with_return_value() async {
    await assertNoErrorsInCode('''
f() async {
  return 5;
}
''');
  }

  test_async_without_return() async {
    await assertNoErrorsInCode('''
f() async {}
''');
  }

  test_asyncForInWrongContext_async() async {
    await assertErrorsInCode(r'''
f(list) async {
  await for (var e in list) {
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
  }

  test_asyncForInWrongContext_asyncStar() async {
    await assertErrorsInCode(r'''
f(list) async* {
  await for (var e in list) {
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);
  }

  test_await_simple() async {
    await assertNoErrorsInCode('''
Future<int> fi() => Future.value(0);
f() async {
  int a = await fi();
  a;
}
''');
  }

  test_awaitInWrongContext_async() async {
    await assertNoErrorsInCode(r'''
f(x, y) async {
  return await x + await y;
}
''');
  }

  test_awaitInWrongContext_asyncStar() async {
    await assertNoErrorsInCode(r'''
f(x, y) async* {
  yield await x + await y;
}
''');
  }

  test_breakWithoutLabelInSwitch() async {
    await assertNoErrorsInCode(r'''
class A {
  void m(int i) {
    switch (i) {
      case 0:
        break;
    }
  }
}
''');
  }

  test_bug_24539_getter() async {
    await assertNoErrorsInCode('''
class C<T> {
  List<Foo> get x => [];
}

typedef Foo(param);
''');
  }

  test_bug_24539_setter() async {
    await assertNoErrorsInCode('''
class C<T> {
  void set x(List<Foo> value) {}
}

typedef Foo(param);
''');
  }

  test_builtInIdentifierAsType_dynamic() async {
    await assertErrorsInCode(r'''
f() {
  dynamic x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
    ]);
  }

  test_class_type_alias_documentationComment() async {
    await assertNoErrorsInCode('''
/**
 * Documentation
 */
class C = D with E;

class D {}
class E {}
''');
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement!.getType('C')!;
    expect(classC.documentationComment, isNotNull);
  }

  test_closure_in_type_inferred_variable_in_other_lib() async {
    newFile('$testPackageLibPath/other.dart', content: '''
var y = (Object x) => x is int && x.isEven;
''');
    await assertNoErrorsInCode('''
import 'other.dart';
var x = y;
''');
  }

  test_concreteClassWithAbstractMember() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  m();
}
''');
  }

  test_concreteClassWithAbstractMember_inherited() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  m();
}
''');
  }

  test_conflictingConstructorNameAndMember_setter() async {
    await assertNoErrorsInCode(r'''
class A {
A.x() {}
set x(_) {}
}
''');
  }

  test_const_dynamic() async {
    await assertNoErrorsInCode('''
const Type d = dynamic;
''');
  }

  test_const_imported_defaultParameterValue_withImportPrefix() async {
    newFile('$testPackageLibPath/b.dart', content: r'''
import 'c.dart' as ccc;
class B {
  const B([p = ccc.value]);
}
''');
    newFile('$testPackageLibPath/c.dart', content: r'''
const int value = 12345;
''');
    await assertNoErrorsInCode(r'''
import 'b.dart';
const b = const B();
''');
  }

  test_constConstructorWithNonConstSuper_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B(): super();
}
''');
  }

  test_constConstructorWithNonConstSuper_redirectingFactory() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B implements C {
  const B();
}
class C extends A {
  const factory C() = B;
}
''');
  }

  test_constConstructorWithNonConstSuper_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  A.a();
}
class B extends A {
  const B(): super();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          54, 7),
    ]);
  }

  test_constConstructorWithNonFinalField_finalInstanceVar() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x = 0;
  const A();
}
''');
  }

  test_constConstructorWithNonFinalField_static() async {
    await assertNoErrorsInCode(r'''
class A {
  static int x = 0;
  const A();
}
''');
  }

  test_constConstructorWithNonFinalField_syntheticField() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  set x(value) {}
  get x {return 0;}
}
''');
  }

  test_constDeferredClass_new() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
class A {
  const A.b();
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' deferred as a;
main() {
  new a.A.b();
}
''');
  }

  test_constEval_functionTypeLiteral() async {
    await assertNoErrorsInCode(r'''
typedef F();
const C = F;
''');
  }

  test_constEval_propertyExtraction_fieldStatic_targetType() async {
    newFile("$testPackageLibPath/math.dart", content: r'''
library math;
const PI = 3.14;
''');
    await assertNoErrorsInCode(r'''
import 'math.dart' as math;
const C = math.PI;
''');
  }

  test_constEval_propertyExtraction_methodStatic_targetType() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  static m() {}
}
const C = A.m;
''');
  }

  test_constEval_symbol() async {
    newFile("$testPackageLibPath/math.dart", content: r'''
library math;
const PI = 3.14;
''');
    await assertNoErrorsInCode(r'''
const C = #foo;
foo() {}
''');
  }

  test_constEvalTypeBoolNumString_equal() async {
    await assertNoErrorsInCode(r'''
class B {
  final v;
  const B.a1(bool p) : v = p == true;
  const B.a2(bool p) : v = p == false;
  const B.a3(bool p) : v = p == 0;
  const B.a4(bool p) : v = p == 0.0;
  const B.a5(bool p) : v = p == '';
  const B.b1(int p) : v = p == true;
  const B.b2(int p) : v = p == false;
  const B.b3(int p) : v = p == 0;
  const B.b4(int p) : v = p == 0.0;
  const B.b5(int p) : v = p == '';
  const B.c1(String p) : v = p == true;
  const B.c2(String p) : v = p == false;
  const B.c3(String p) : v = p == 0;
  const B.c4(String p) : v = p == 0.0;
  const B.c5(String p) : v = p == '';
}
''');
  }

  test_constEvalTypeBoolNumString_notEqual() async {
    await assertNoErrorsInCode(r'''
class B {
  final v;
  const B.a1(bool p) : v = p != true;
  const B.a2(bool p) : v = p != false;
  const B.a3(bool p) : v = p != 0;
  const B.a4(bool p) : v = p != 0.0;
  const B.a5(bool p) : v = p != '';
  const B.b1(int p) : v = p != true;
  const B.b2(int p) : v = p != false;
  const B.b3(int p) : v = p != 0;
  const B.b4(int p) : v = p != 0.0;
  const B.b5(int p) : v = p != '';
  const B.c1(String p) : v = p != true;
  const B.c2(String p) : v = p != false;
  const B.c3(String p) : v = p != 0;
  const B.c4(String p) : v = p != 0.0;
  const B.c5(String p) : v = p != '';
}
''');
  }

  test_constEvAlTypeNum_String() async {
    await assertNoErrorsInCode(r'''
const String A = 'a';
const String B = A + 'b';
''');
  }

  test_constNotInitialized_field() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int x = 0;
}
''');
  }

  test_constNotInitialized_local() async {
    await assertErrorsInCode(r'''
main() {
  const int x = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
    ]);
  }

  test_constRedirectSkipsSupertype() async {
    // Since C redirects to C.named, it doesn't implicitly refer to B's
    // unnamed constructor.  Therefore there is no cycle.
    await assertNoErrorsInCode('''
class B {
  final x;
  const B() : x = y;
  const B.named() : x = null;
}
class C extends B {
  const C() : this.named();
  const C.named() : super.named();
}
const y = const C();
''');
  }

  test_constructorDeclaration_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
class A {
  A(@app int app) {}
}
''');
  }

  test_constWithNonConstantArgument_constField() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(x);
}
main() {
  const A(double.infinity);
}
''');
  }

  test_constWithNonConstantArgument_literals() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(a, b, c, d);
}
f() { return const A(true, 0, 1.0, '2'); }
''');
  }

  test_constWithTypeParameters_direct() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  static const V = const A<int>();
  const A();
}
''');
  }

  test_constWithUndefinedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.name();
}
f() {
  return const A.name();
}
''');
  }

  test_constWithUndefinedConstructorDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
f() {
  return const A();
}
''');
  }

  test_defaultValueInFunctionTypeAlias() async {
    await assertNoErrorsInCode('''
typedef F([x]);
''');
  }

  test_defaultValueInFunctionTypedParameter_named() async {
    await assertNoErrorsInCode('''
f(g({p})) {}
''');
  }

  test_defaultValueInFunctionTypedParameter_optional() async {
    await assertNoErrorsInCode("f(g([p])) {}");
  }

  test_deprecatedMemberUse_hide() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library lib1;
class A {}
@deprecated
class B {}
''');
    await assertNoErrorsInCode(r'''
library lib;
import 'lib1.dart' hide B;
A a = new A();
''');
  }

  test_dynamicIdentifier() async {
    await assertErrorsInCode(r'''
main() {
  var v = dynamic;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
  }

  test_empty_generator_async() async {
    await assertNoErrorsInCode('''
Stream<int> f() async* {
}
''');
  }

  test_empty_generator_sync() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
}
''');
  }

  test_extraPositionalArguments_function() async {
    await assertNoErrorsInCode(r'''
f(p1, p2) {}
main() {
  f(1, 2);
}
''');
  }

  test_extraPositionalArguments_Function() async {
    await assertNoErrorsInCode(r'''
f(Function a) {
  a(1, 2);
}
''');
  }

  test_extraPositionalArguments_typedef_local() async {
    await assertNoErrorsInCode(r'''
typedef A(p1, p2);
A getA() => (p1, p2) {};
f() {
  A a = getA();
  a(1, 2);
}
''');
  }

  test_extraPositionalArguments_typedef_parameter() async {
    await assertNoErrorsInCode(r'''
typedef A(p1, p2);
f(A a) {
  a(1, 2);
}
''');
  }

  test_fieldFormalParameter_functionTyped_named() async {
    await assertNoErrorsInCode(r'''
class C {
  final Function field;

  C({String this.field(int value) = f});
}
String f(int value) => '';
''');
  }

  test_fieldFormalParameter_genericFunctionTyped() async {
    await assertNoErrorsInCode(r'''
class C {
  final Object Function(int, double) field;

  C(String Function(num, Object) this.field);
}
''');
  }

  test_fieldFormalParameter_genericFunctionTyped_named() async {
    await assertNoErrorsInCode(r'''
class C {
  final Object Function(int, double) field;

  C({String Function(num, Object) this.field = f});
}
String f(num a, Object b) => '';
''');
  }

  test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
  A() : x = 1 {}
}
''');
  }

  test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A() : x = 1 {}
}
''');
  }

  test_fieldInitializerOutsideConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A(this.x) {}
}
''');
  }

  test_fieldInitializerOutsideConstructor_defaultParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
  A([this.x = 1]) {}
}
''');
  }

  test_fieldInitializerRedirectingConstructor_super() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  int x;
  B(this.x) : super();
}
''');
  }

  test_finalInitializedInDeclarationAndConstructor_initializer() async {
    await assertNoErrorsInCode(r'''
class A {
  final x;
  A() : x = 1 {}
}
''');
  }

  test_finalInitializedInDeclarationAndConstructor_initializingFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final x;
  A(this.x) {}
}
''');
  }

  test_finalNotInitialized_atDeclaration() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x = 0;
  A() {}
}
''');
  }

  test_finalNotInitialized_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x = 0;
  A() {}
}
''');
  }

  test_finalNotInitialized_functionTypedFieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final Function x;
  A(int this.x(int p)) {}
}
''');
  }

  test_finalNotInitialized_hasNativeClause_hasConstructor() async {
    await assertErrorsInCode(r'''
class A native 'something' {
  final int x;
  A() {}
}
''', [
      error(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, 8, 18),
    ]);
  }

  test_finalNotInitialized_hasNativeClause_noConstructor() async {
    await assertErrorsInCode(r'''
class A native 'something' {
  final int x;
}
''', [
      error(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, 8, 18),
    ]);
  }

  test_finalNotInitialized_initializer() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A() : x = 0 {}
}
''');
  }

  test_finalNotInitialized_redirectingConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A(this.x);
  A.named() : this (42);
}
''');
  }

  test_functionDeclaration_scope_returnType() async {
    await assertNoErrorsInCode('''
int f(int) { return 0; }
''');
  }

  test_functionDeclaration_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
f(@app int app) {}
''');
  }

  test_functionTypeAlias_scope_returnType() async {
    await assertNoErrorsInCode('''
typedef int f(int);
''');
  }

  test_functionTypeAlias_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
typedef int f(@app int app);
''');
  }

  test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters() async {
    await assertNoErrorsInCode('''
// @dart = 2.9
typedef Foo<S> = S Function<T>(T x);

main(Object p) {
  (p as Foo)<int>(3);
  if (p is Foo) {
    p<int>(3);
  }
  (p as Foo<String>)<int>(3);
  if (p is Foo<String>) {
    p<int>(3);
  }
}
''');
  }

  test_genericTypeAlias_castsAndTypeChecks_noTypeParameters() async {
    await assertNoErrorsInCode('''
// @dart = 2.9
typedef Foo = T Function<T>(T x);

main(Object p) {
  (p as Foo)<int>(3);
  if (p is Foo) {
    p<int>(3);
  }
}
''');
  }

  test_genericTypeAlias_fieldAndReturnType_noTypeParameters() async {
    await assertNoErrorsInCode(r'''
typedef Foo = int Function<T>(T x);
int foo<T>(T x) => 3;
Foo bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo f = <T>(T x) => 0;
  void test() {
    f<String>("hello");
  }
}
''');
  }

  test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments() async {
    await assertNoErrorsInCode(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
Foo<int> bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo<int> f = <T>(T x) => 0;
  void test() {
    f<String>("hello");
  }
}
''');
  }

  test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments() async {
    await assertNoErrorsInCode(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
Foo bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo f = <T>(T x) {};
  void test() {
    f<String>("hello");
  }
}
''');
  }

  test_genericTypeAlias_noTypeParameters() async {
    await assertNoErrorsInCode(r'''
typedef Foo = int Function<T>(T x);
int foo<T>(T x) => 3;
void test1() {
  Foo y = foo;
  // These two should be equivalent
  foo<String>("hello");
  y<String>("hello");
}
''');
  }

  test_genericTypeAlias_typeParameters() async {
    await assertNoErrorsInCode(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
void test1() {
  Foo<int> y = foo;
  // These two should be equivalent
  foo<String>("hello");
  y<String>("hello");
}
''');
  }

  test_importDuplicatedLibraryName() async {
    newFile("$testPackageLibPath/lib.dart", content: "library lib;");
    await assertErrorsInCode(r'''
library test;
import 'lib.dart';
import 'lib.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 21, 10),
      error(HintCode.UNUSED_IMPORT, 40, 10),
      error(HintCode.DUPLICATE_IMPORT, 40, 10),
    ]);
  }

  test_importDuplicatedLibraryUnnamed() async {
    newFile("$testPackageLibPath/lib1.dart");
    newFile("$testPackageLibPath/lib2.dart");
    // No warning on duplicate import (https://github.com/dart-lang/sdk/issues/24156)
    await assertErrorsInCode(r'''
library test;
import 'lib1.dart';
import 'lib2.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 21, 11),
      error(HintCode.UNUSED_IMPORT, 41, 11),
    ]);
  }

  test_importOfNonLibrary_libraryDeclared() async {
    newFile("$testPackageLibPath/part.dart", content: r'''
library lib1;
class A {}
''');
    await assertNoErrorsInCode(r'''
library lib;
import 'part.dart';
A a = A();
''');
  }

  test_importOfNonLibrary_libraryNotDeclared() async {
    newFile("$testPackageLibPath/part.dart", content: '''
class A {}
''');
    await assertNoErrorsInCode(r'''
library lib;
import 'part.dart';
A a = A();
''');
  }

  test_importPrefixes_withFirstLetterDifference() async {
    newFile("$testPackageLibPath/lib1.dart", content: r'''
library lib1;
test1() {}
''');
    newFile("$testPackageLibPath/lib2.dart", content: r'''
library lib2;
test2() {}
''');
    await assertNoErrorsInCode(r'''
library L;
import 'lib1.dart' as math;
import 'lib2.dart' as path;
main() {
  math.test1();
  path.test2();
}
''');
  }

  test_inconsistentMethodInheritance_methods_typeParameter2() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  x(E e) {}
}
class B<E> {
  x(E e) {}
}
class C<E> extends A<E> implements B<E> {
  x(E e) {}
}
''');
  }

  test_inconsistentMethodInheritance_methods_typeParameters1() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  x(E e) {}
}
class B<E> {
  x(E e) {}
}
class C<E> implements A<E>, B<E> {
  x(E e) {}
}
''');
  }

  test_inconsistentMethodInheritance_simple() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  x();
}
abstract class B {
  x();
}
class C implements A, B {
  x() {}
}
''');
  }

  test_infer_mixin_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}

class B {}

mixin M<T> on A<T> {}

class C extends A<B> with M {}
''');
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement!.getType('C')!;
    expect(classC.mixins, hasLength(1));
    assertType(classC.mixins[0], 'M<B>');
  }

  test_infer_mixin_with_substitution_functionType_new_syntax() async {
    await assertErrorsInCode('''
abstract class A<T> {}

class B {}

mixin M<T, U> on A<T Function(U)> {}

class C extends A<int Function(String)> with M {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        47,
        1,
      ),
    ]);
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement!.getType('C')!;
    expect(classC.mixins, hasLength(1));
    assertType(classC.mixins[0], 'M<int, String>');
  }

  test_infer_mixin_with_substitution_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}

class B {}

mixin M<T> on A<List<T>> {}

class C extends A<List<B>> with M {}
''');
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement!.getType('C')!;
    expect(classC.mixins, hasLength(1));
    assertType(classC.mixins[0], 'M<B>');
  }

  test_initializingFormalForNonExistentField() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A(this.x) {}
}
''');
  }

  test_instance_creation_inside_annotation() async {
    await assertNoErrorsInCode('''
class C {
  const C();
}
class D {
  final C c;
  const D(this.c);
}
@D(const C())
f() {}
''');
  }

  test_instanceAccessToStaticMember_fromComment() async {
    await assertNoErrorsInCode(r'''
class A {
  static m() {}
}
/// [A.m]
main() {
}
''');
  }

  test_instanceAccessToStaticMember_topLevel() async {
    await assertNoErrorsInCode(r'''
m() {}
main() {
  m();
}
''');
  }

  test_instanceMemberAccessFromStatic_fromComment() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
  /// [m]
  static foo() {
  }
}
''');
  }

  test_instanceMethodNameCollidesWithSuperclassStatic_field() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library L;
class A {
  static var _m;
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 41, 2),
    ]);
  }

  test_instanceMethodNameCollidesWithSuperclassStatic_method() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library L;
class A {
  static _m() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 41, 2),
    ]);
  }

  test_integerLiteralOutOfRange_negative_leadingZeros() async {
    await assertNoErrorsInCode('''
int x = -000923372036854775809;
''');
  }

  test_integerLiteralOutOfRange_negative_small() async {
    await assertNoErrorsInCode('''
int x = -42;
''');
  }

  test_integerLiteralOutOfRange_negative_valid() async {
    await assertNoErrorsInCode('''
int x = -9223372036854775808;
''');
  }

  test_integerLiteralOutOfRange_positive_leadingZeros() async {
    await assertNoErrorsInCode('''
int x = 000923372036854775808;
''');
  }

  test_integerLiteralOutOfRange_positive_valid() async {
    await assertNoErrorsInCode('''
int x = 9223372036854775807;
''');
  }

  test_integerLiteralOutOfRange_positive_zero() async {
    await assertNoErrorsInCode('''
int x = 0;
''');
  }

  test_intLiteralInDoubleContext() async {
    await assertNoErrorsInCode(r'''
void takeDouble(double x) {}
void main() {
  takeDouble(0);
  takeDouble(-0);
  takeDouble(0x0);
  takeDouble(-0x0);
}
''');
  }

  test_invalidAnnotation_constantVariable_field() async {
    await assertNoErrorsInCode(r'''
@A.C
class A {
  static const C = 0;
}
''');
  }

  test_invalidAnnotation_constantVariable_field_importWithPrefix() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
class A {
  static const C = 0;
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.A.C
main() {
}
''');
  }

  test_invalidAnnotation_constantVariable_topLevel() async {
    await assertNoErrorsInCode(r'''
const C = 0;
@C
main() {
}
''');
  }

  test_invalidAnnotation_constantVariable_topLevel_importWithPrefix() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
const C = 0;
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.C
main() {
}
''');
  }

  test_invalidAnnotation_constConstructor_importWithPrefix() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
class A {
  const A(int p);
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.A(42)
main() {
}
''');
  }

  test_invalidAnnotation_constConstructor_named_importWithPrefix() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
class A {
  const A.named(int p);
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.A.named(42)
main() {
}
''');
  }

  test_invalidIdentifierInAsync() async {
    await assertErrorsInCode(r'''
class A {
  m() {
    int async;
    int await;
    int yield;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 56, 5),
    ]);
  }

  test_invalidMethodOverrideNamedParamType() async {
    await assertNoErrorsInCode(r'''
class A {
  m({int a = 1}) {}
}
class B implements A {
  m({int a = 1, int b = 2}) {}
}
''');
  }

  test_invalidOverrideNamed_unorderedNamedParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({b, a}) {}
}
''');
  }

  test_invalidOverrideRequired_less() async {
    await assertNoErrorsInCode(r'''
class A {
  m(a, b) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
  }

  test_invalidOverrideRequired_same() async {
    await assertNoErrorsInCode(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}
''');
  }

  test_invalidOverrideReturnType_returnType_interface() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  num m();
}
class B implements A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_interface2() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  num m();
}
abstract class B implements A {
}
class C implements B {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_mixin() async {
    await assertNoErrorsInCode(r'''
class A {
  num m() { return 0; }
}
class B extends Object with A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_parameterizedTypes() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {
  List<E> m();
}
class B extends A<dynamic> {
  List<dynamic> m() { return <dynamic>[]; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_sameType() async {
    await assertNoErrorsInCode(r'''
class A {
  int m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_superclass() async {
    await assertNoErrorsInCode(r'''
class A {
  num m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_superclass2() async {
    await assertNoErrorsInCode(r'''
class A {
  num m() { return 0; }
}
class B extends A {
}
class C extends B {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_void() async {
    await assertNoErrorsInCode(r'''
class A {
  void m() {}
}
class B extends A {
  int m() { return 0; }
}
''');
  }

  test_invalidTypeArgumentForKey() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {
    return const <int, int>{};
  }
}
''');
  }

  Future test_issue32114() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class O {}

typedef T Func<T extends O>(T e);
''');
    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';
export 'a.dart' show Func;

abstract class A<T extends O> {
  Func<T> get func;
}
''');
    await assertNoErrorsInCode('''
import 'b.dart';

class B extends A {
  Func get func => (x) => x;
}
''');
  }

  test_issue_24191() async {
    await assertNoErrorsInCode('''
abstract class S extends Stream {}
f(S s) async {
  await for (var v in s) {
    print(v);
  }
}
''');
  }

  test_issue_32394() async {
    await assertErrorsInCode('''
var x = y.map((a) => a.toString());
var y = [3];
var z = x.toList();

void main() {
  String p = z;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 93, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 97, 1),
    ]);
    var z = result.unit.declaredElement!.topLevelVariables
        .where((e) => e.name == 'z')
        .single;
    assertType(z.type, 'List<String>');
  }

  test_issue_35320_lists() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
const x = const <String>['a'];
''');
    await assertNoErrorsInCode('''
import 'lib.dart';
const y = const <String>['b'];
int f(v) {
  switch(v) {
    case x:
      return 0;
    case y:
      return 1;
    default:
      return 2;
  }
}
''');
  }

  test_issue_35320_maps() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
const x = const <String, String>{'a': 'b'};
''');
    await assertNoErrorsInCode('''
import 'lib.dart';
const y = const <String, String>{'c': 'd'};
int f(v) {
  switch(v) {
    case x:
      return 0;
    case y:
      return 1;
    default:
      return 2;
  }
}
''');
  }

  test_loadLibraryDefined() async {
    newFile('$testPackageLibPath/lib.dart', content: r'''
library lib;
foo() => 22;''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' deferred as other;
main() {
  other.loadLibrary().then((_) => other.foo());
}
''');
  }

  test_local_generator_async() async {
    await assertNoErrorsInCode('''
f() {
  return () async* { yield 0; };
}
''');
  }

  test_local_generator_sync() async {
    await assertNoErrorsInCode('''
f() {
  return () sync* { yield 0; };
}
''');
  }

  test_metadata_enumConstantDeclaration() async {
    await assertNoErrorsInCode(r'''
const x = 1;
enum E {
  aaa,
  @x
  bbb
}
''');
  }

  test_methodDeclaration_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
class A {
  foo(@app int app) {}
}
''');
  }

  test_missingEnumConstantInSwitch_all() async {
    await assertNoErrorsInCode(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.A: break;
    case E.B: break;
    case E.C: break;
  }
}
''');
  }

  test_missingEnumConstantInSwitch_default() async {
    await assertNoErrorsInCode(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.B: break;
    default: break;
  }
}
''');
  }

  test_mixedReturnTypes_differentScopes() async {
    await assertNoErrorsInCode(r'''
class C {
  m(int x) {
    f(int y) {
      return;
    }
    f(x);
    return 0;
  }
}
''');
  }

  test_mixedReturnTypes_ignoreImplicit() async {
    await assertNoErrorsInCode(r'''
f(bool p) {
  if (p) return 42;
  // implicit 'return;' is ignored
}
''');
  }

  test_mixedReturnTypes_ignoreImplicit2() async {
    await assertNoErrorsInCode(r'''
f(bool p) {
  if (p) {
    return 42;
  } else {
    return 42;
  }
  // implicit 'return;' is ignored
}
''');
  }

  test_mixedReturnTypes_sameKind() async {
    await assertNoErrorsInCode(r'''
class C {
  m(int x) {
    if (x < 0) {
      return 1;
    }
    return 0;
  }
}
''');
  }

  test_mixin_of_mixin_type_argument_inference() async {
    // In the code below, B's superclass constraints don't include A, because
    // superclass constraints are determined from the mixin's superclass, and
    // B's superclass is Object.  So no mixin type inference is attempted, and
    // "with B" is interpreted as "with B<dynamic>".
    await assertNoErrorsInCode('''
class A<T> {}
class B<T> = Object with A<T>;
class C = Object with B;
''');
    var bReference = result.unit.declaredElement!.getType('C')!.mixins[0];
    assertTypeDynamic(bReference.typeArguments[0]);
  }

  test_mixin_of_mixin_type_argument_inference_cascaded_mixin() async {
    // In the code below, B has a single superclass constraint, A1, because
    // superclass constraints are determined from the mixin's superclass, and
    // B's superclass is "Object with A1<T>".  So mixin type inference succeeds
    // (since C's base class implements A1<int>), and "with B" is interpreted as
    // "with B<int>".
    await assertErrorsInCode('''
class A1<T> {}
class A2<T> {}
class B<T> = Object with A1<T>, A2<T>;
class Base implements A1<int> {}
class C = Base with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 122, 1),
    ]);
    var bReference = result.unit.declaredElement!.getType('C')!.mixins[0];
    assertType(bReference.typeArguments[0], 'int');
  }

  test_mixinDeclaresConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends Object with A {}
''');
  }

  test_mixinDeclaresConstructor_factory() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() => throw 0;
}
class B extends Object with A {}
''');
  }

  test_mixinInference_with_actual_mixins() async {
    await assertNoErrorsInCode('''
class I<X> {}

mixin M0<T> on I<T> {}

mixin M1<T> on I<T> {
  T foo(T a) => a;
}

class A = I<int> with M0, M1;

void main () {
  var x = new A().foo(0);
  x;
}
''');
    var main = result.unit.declarations.last as FunctionDeclaration;
    var mainBody = main.functionExpression.body as BlockFunctionBody;
    var xDecl = mainBody.block.statements[0] as VariableDeclarationStatement;
    var xElem = xDecl.variables.variables[0].declaredElement!;
    assertType(xElem.type, 'int');
  }

  test_multipleSuperInitializers_no() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  B() {}
}
''');
  }

  test_multipleSuperInitializers_single() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  B() : super() {}
}
''');
  }

  test_newWithAbstractClass_factory() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  factory A() { return new B(); }
}
class B implements A {
  B() {}
}
A f() {
  return new A();
}
''');
  }

  test_nonBoolExpression_interfaceType() async {
    await assertNoErrorsInCode(r'''
f() {
  assert(true);
}
''');
  }

  test_nonBoolNegationExpression() async {
    await assertNoErrorsInCode(r'''
f(bool pb, pd) {
  !true;
  !false;
  !pb;
  !pd;
}
''');
  }

  test_nonBoolNegationExpression_dynamic() async {
    await assertErrorsInCode(r'''
f1(bool dynamic) {
  !dynamic;
}
f2() {
  bool dynamic = true;
  !dynamic;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 7),
    ]);
  }

  test_nonBoolOperand_and_bool() async {
    await assertNoErrorsInCode(r'''
bool f(bool left, bool right) {
  return left && right;
}
''');
  }

  test_nonBoolOperand_and_dynamic() async {
    await assertNoErrorsInCode(r'''
bool f(left, dynamic right) {
  return left && right;
}
''');
  }

  test_nonBoolOperand_or_bool() async {
    await assertNoErrorsInCode(r'''
bool f(bool left, bool right) {
  return left || right;
}
''');
  }

  test_nonBoolOperand_or_dynamic() async {
    await assertNoErrorsInCode(r'''
bool f(dynamic left, right) {
  return left || right;
}
''');
  }

  test_nonConstantDefaultValue_constField() async {
    await assertNoErrorsInCode(r'''
f([a = double.infinity]) {
}
''');
  }

  test_nonConstantDefaultValue_function_named() async {
    await assertNoErrorsInCode('''
f({x : 2 + 3}) {}
''');
  }

  test_nonConstantDefaultValue_function_positional() async {
    await assertNoErrorsInCode('''
f([x = 2 + 3]) {}
''');
  }

  test_nonConstantDefaultValue_inConstructor_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A({x : 2 + 3}) {}
}
''');
  }

  test_nonConstantDefaultValue_inConstructor_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  A([x = 2 + 3]) {}
}
''');
  }

  test_nonConstantDefaultValue_method_named() async {
    await assertNoErrorsInCode(r'''
class A {
  m({x : 2 + 3}) {}
}
''');
  }

  test_nonConstantDefaultValue_method_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  m([x = 2 + 3]) {}
}
''');
  }

  test_nonConstantDefaultValue_typedConstList() async {
    await assertNoErrorsInCode(r'''
class A {
  m([p111 = const <String>[]]) {}
}
class B extends A {
  m([p222 = const <String>[]]) {}
}
''');
  }

  test_nonConstantValueInInitializer_namedArgument() async {
    await assertNoErrorsInCode(r'''
class A {
  final a;
  const A({this.a});
}
class B extends A {
  const B({b}) : super(a: b);
}
''');
  }

  test_nonConstListElement_constField() async {
    await assertNoErrorsInCode(r'''
main() {
  const [double.infinity];
}
''');
  }

  test_nonConstMapAsExpressionStatement_const() async {
    await assertNoErrorsInCode(r'''
f() {
  const {'a' : 0, 'b' : 1};
}
''');
  }

  test_nonConstMapAsExpressionStatement_notExpressionStatement() async {
    await assertErrorsInCode(r'''
f() {
  var m = {'a' : 0, 'b' : 1};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_nonConstMapAsExpressionStatement_typeArguments() async {
    await assertNoErrorsInCode(r'''
f() {
  <String, int> {'a' : 0, 'b' : 1};
}
''');
  }

  test_nonConstMapValue_constField() async {
    await assertNoErrorsInCode(r'''
main() {
  const {0: double.infinity};
}
''');
  }

  test_nonConstValueInInitializer_binary_bool() async {
    await assertErrorsInCode(r'''
class A {
  final v;
  const A.a1(bool p) : v = p && true;
  const A.a2(bool p) : v = true && p;
  const A.b1(bool p) : v = p || true;
  const A.b2(bool p) : v = true || p;
}
''', [
      error(HintCode.DEAD_CODE, 170, 1),
    ]);
  }

  test_nonConstValueInInitializer_binary_dynamic() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a1(p) : v = p + 5;
  const A.a2(p) : v = 5 + p;
  const A.b1(p) : v = p - 5;
  const A.b2(p) : v = 5 - p;
  const A.c1(p) : v = p * 5;
  const A.c2(p) : v = 5 * p;
  const A.d1(p) : v = p / 5;
  const A.d2(p) : v = 5 / p;
  const A.e1(p) : v = p ~/ 5;
  const A.e2(p) : v = 5 ~/ p;
  const A.f1(p) : v = p > 5;
  const A.f2(p) : v = 5 > p;
  const A.g1(p) : v = p < 5;
  const A.g2(p) : v = 5 < p;
  const A.h1(p) : v = p >= 5;
  const A.h2(p) : v = 5 >= p;
  const A.i1(p) : v = p <= 5;
  const A.i2(p) : v = 5 <= p;
  const A.j1(p) : v = p % 5;
  const A.j2(p) : v = 5 % p;
}
''');
  }

  test_nonConstValueInInitializer_binary_int() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a1(int p) : v = p ^ 5;
  const A.a2(int p) : v = 5 ^ p;
  const A.b1(int p) : v = p & 5;
  const A.b2(int p) : v = 5 & p;
  const A.c1(int p) : v = p | 5;
  const A.c2(int p) : v = 5 | p;
  const A.d1(int p) : v = p >> 5;
  const A.d2(int p) : v = 5 >> p;
  const A.e1(int p) : v = p << 5;
  const A.e2(int p) : v = 5 << p;
}
''');
  }

  test_nonConstValueInInitializer_binary_num() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a1(num p) : v = p + 5;
  const A.a2(num p) : v = 5 + p;
  const A.b1(num p) : v = p - 5;
  const A.b2(num p) : v = 5 - p;
  const A.c1(num p) : v = p * 5;
  const A.c2(num p) : v = 5 * p;
  const A.d1(num p) : v = p / 5;
  const A.d2(num p) : v = 5 / p;
  const A.e1(num p) : v = p ~/ 5;
  const A.e2(num p) : v = 5 ~/ p;
  const A.f1(num p) : v = p > 5;
  const A.f2(num p) : v = 5 > p;
  const A.g1(num p) : v = p < 5;
  const A.g2(num p) : v = 5 < p;
  const A.h1(num p) : v = p >= 5;
  const A.h2(num p) : v = 5 >= p;
  const A.i1(num p) : v = p <= 5;
  const A.i2(num p) : v = 5 <= p;
  const A.j1(num p) : v = p % 5;
  const A.j2(num p) : v = 5 % p;
}
''');
  }

  test_nonConstValueInInitializer_field() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a;
  const A() : a = 5;
}
''');
  }

  test_nonConstValueInInitializer_redirecting() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.named(p);
  const A() : this.named(42);
}
''');
  }

  test_nonConstValueInInitializer_super() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(p);
}
class B extends A {
  const B() : super(42);
}
''');
  }

  test_nonConstValueInInitializer_unary() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a(bool p) : v = !p;
  const A.b(int p) : v = ~p;
  const A.c(num p) : v = -p;
}
''');
  }

  @failingTest
  test_null_callOperator() async {
    await assertErrorsInCode(r'''
main() {
  null + 5;
  null == 5;
  null[0];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 0, 0),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 0, 0),
    ]);
  }

  test_optionalNew_rewrite() async {
    newFile("$testPackageLibPath/a.dart", content: r'''
class A {
  const A();
  const A.named();
}
''');
    newFile("$testPackageLibPath/b.dart", content: r'''
import 'a.dart';
import 'a.dart' as p;

const _a1 = A();
const _a2 = A.named();
const _a3 = p.A();
const _a4 = p.A.named();

class B {
  const B.named1({this.a: _a1}) : assert(a != null);
  const B.named2({this.a: _a2}) : assert(a != null);
  const B.named3({this.a: _a3}) : assert(a != null);
  const B.named4({this.a: _a4}) : assert(a != null);

  final A a;
}
''');
    await assertNoErrorsInCode(r'''
import 'b.dart';
main() {
  const B.named1();
  const B.named2();
  const B.named3();
  const B.named4();
}
''');
  }

  test_optionalNew_rewrite_instantiatesToBounds() async {
    newFile("$testPackageLibPath/a.dart", content: r'''
class Unbounded<T> {
  const Unbounded();
  const Unbounded.named();
}
class Bounded<T extends String> {
  const Bounded();
  const Bounded.named();
}
''');
    newFile("$testPackageLibPath/b.dart", content: r'''
import 'a.dart';
import 'a.dart' as p;

const unbounded1 = Unbounded();
const unbounded2 = Unbounded.named();
const unbounded3 = p.Unbounded();
const unbounded4 = p.Unbounded.named();
const bounded1 = Bounded();
const bounded2 = Bounded.named();
const bounded3 = p.Bounded();
const bounded4 = p.Bounded.named();

class B {
  const B.named1({this.unbounded: unbounded1}) : bounded = null;
  const B.named2({this.unbounded: unbounded2}) : bounded = null;
  const B.named3({this.unbounded: unbounded3}) : bounded = null;
  const B.named4({this.unbounded: unbounded4}) : bounded = null;
  const B.named5({this.bounded: bounded1}) : unbounded = null;
  const B.named6({this.bounded: bounded2}) : unbounded = null;
  const B.named7({this.bounded: bounded3}) : unbounded = null;
  const B.named8({this.bounded: bounded4}) : unbounded = null;

  final Unbounded unbounded;
  final Bounded bounded;
}
''');
    await assertNoErrorsInCode(r'''
import 'b.dart';

@B.named1()
@B.named2()
@B.named3()
@B.named4()
@B.named5()
@B.named6()
@B.named7()
@B.named8()
main() {}
''');
    expect(result.unit.declarations, hasLength(1));
    final mainDecl = result.unit.declarations[0];
    expect(mainDecl.metadata, hasLength(8));
    mainDecl.metadata.forEach((metadata) {
      final value = metadata.elementAnnotation!.computeConstantValue()!;
      expect(value, isNotNull);
      assertType(value.type, 'B');
      final unbounded = value.getField('unbounded')!;
      final bounded = value.getField('bounded')!;
      if (!unbounded.isNull) {
        expect(bounded.isNull, true);
        assertType(unbounded.type, 'Unbounded<dynamic>');
      } else {
        expect(unbounded.isNull, true);
        assertType(bounded.type, 'Bounded<String>');
      }
    });
  }

  test_parameterScope_local() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    await assertErrorsInCode(r'''
f() {
  g(g) {
    h(g);
  }
}
h(x) {}
''', [
      error(HintCode.UNUSED_ELEMENT, 8, 1),
    ]);
  }

  test_parameterScope_method() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    await assertNoErrorsInCode(r'''
class C {
  g(g) {
    h(g);
  }
}
h(x) {}
''');
  }

  test_parameterScope_topLevel() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    await assertNoErrorsInCode(r'''
g(g) {
  h(g);
}
h(x) {}
''');
  }

  test_parametricCallFunction() async {
    await assertNoErrorsInCode(r'''
f() {
  var c = new C();
  c<String>('').codeUnits;
}

class C {
  T call<T>(T a) => a;
}
''');
  }

  test_propagateTypeArgs_intoBounds() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {}
abstract class B<F> implements A<F>{}
abstract class C<G, H extends A<G>> {}
class D<I> extends C<I, B<I>> {}
''');
  }

  test_propagateTypeArgs_intoSupertype() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T p);
  A.named(T p);
}
class B<S> extends A<S> {
  B(S p) : super(p);
  B.named(S p) : super.named(p);
}
''');
  }

  test_referenceToDeclaredVariableInInitializer_constructorName() async {
    await assertErrorsInCode(r'''
class A {
  A.x() {}
}
f() {
  var x = new A.x();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
    ]);
  }

  test_referenceToDeclaredVariableInInitializer_methodName() async {
    await assertErrorsInCode(r'''
class A {
  x() {}
}
f(A a) {
  var x = a.x();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
  }

  test_referenceToDeclaredVariableInInitializer_propertyName() async {
    await assertErrorsInCode(r'''
class A {
  var x;
}
f(A a) {
  var x = a.x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
  }

  test_regress34906() async {
    await assertNoErrorsInCode(r'''
typedef G<X, Y extends Function(X)> = X Function(Function(Y));
f(G<dynamic, Function(Null)> superBoundedG) {}
''');
  }

  test_reversedTypeArguments() async {
    await assertNoErrorsInCode(r'''
class Codec<S1, T1> {
  Codec<T1, S1> get inverted => new _InvertedCodec<T1, S1>(this);
}
class _InvertedCodec<T2, S2> extends Codec<T2, S2> {
  _InvertedCodec(Codec<S2, T2> codec);
}
''');
  }

  test_sharedDeferredPrefix() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
f1() {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: r'''
f2() {}
''');
    newFile('$testPackageLibPath/lib3.dart', content: r'''
f3() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' as lib;
import 'lib3.dart' as lib;
main() { lib1.f1(); lib.f2(); lib.f3(); }
''');
  }

  test_typeArgument_boundToFunctionType() async {
    await assertNoErrorsInCode('''
class A<T extends void Function(T)>{}
''');
  }

  test_typePromotion_booleanAnd_useInRight() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  p is String && p.length != 0;
}
''');
  }

  test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_noAssignment() async {
    await assertNoErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
}
''');
  }

  test_typePromotion_conditional_useInThen() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  p is String ? p.length : 0;
}''');
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_noAssignment() async {
    await assertNoErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
}
''');
  }

  test_typePromotion_if_accessedInClosure_noAssignment() async {
    await assertNoErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
}
''');
  }

  test_typePromotion_if_hasAssignment_outsideAfter() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  p = 0;
}
''');
  }

  test_typePromotion_if_hasAssignment_outsideBefore() async {
    await assertNoErrorsInCode(r'''
main(Object p, Object p2) {
  p = p2;
  if (p is String) {
    p.length;
  }
}''');
  }

  test_typePromotion_if_inClosure_assignedAfter_inSameFunction() async {
    await assertErrorsInCode(r'''
main() {
  f(Object p) {
    if (p is String) {
      p.length;
    }
    p = 0;
  };
}
''', [
      error(HintCode.UNUSED_ELEMENT, 11, 1),
    ]);
  }

  test_typePromotion_if_is_and_left() async {
    await assertNoErrorsInCode(r'''
bool tt() => true;
main(Object p) {
  if (p is String && tt()) {
    p.length;
  }
}
''');
  }

  test_typePromotion_if_is_and_right() async {
    await assertNoErrorsInCode(r'''
bool tt() => true;
main(Object p) {
  if (tt() && p is String) {
    p.length;
  }
}
''');
  }

  test_typePromotion_if_is_and_subThenSuper() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.9
class A {
  var a;
}
class B extends A {
  var b;
}
main(Object p) {
  if (p is B && p is A) {
    p.a;
    p.b;
  }
}
''');
  }

  test_typePromotion_if_is_parenthesized() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  if ((p is String)) {
    p.length;
  }
}
''');
  }

  test_typePromotion_if_is_single() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
}
''');
  }

  test_typePromotion_parentheses() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  (p is String) ? p.length : 0;
  (p) is String ? p.length : 0;
  ((p)) is String ? p.length : 0;
  ((p) is String) ? p.length : 0;
}
''');
  }

  test_typeType_class() async {
    await assertNoErrorsInCode(r'''
class C {}
f(Type t) {}
main() {
  f(C);
}
''');
  }

  test_typeType_class_prefixed() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
class C {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.C);
}
''');
  }

  test_typeType_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F();
f(Type t) {}
main() {
  f(F);
}
''');
  }

  test_typeType_functionTypeAlias_prefixed() async {
    newFile("$testPackageLibPath/lib.dart", content: r'''
library lib;
typedef F();''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.F);
}
''');
  }

  test_undefinedSuperMethod_field() async {
    await assertNoErrorsInCode(r'''
class A {
  var m;
}
class B extends A {
  f() {
    super.m();
  }
}
''');
  }

  test_undefinedSuperMethod_method() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  f() {
    super.m();
  }
}
''');
  }

  Future test_useDynamicWithPrefix() async {
    await assertNoErrorsInCode('''
import 'dart:core' as core;

core.dynamic dynamicVariable;
''');
  }
}

@reflectiveTest
class NonErrorResolverWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, NonErrorResolverTestCases {
  test_conflictingStaticGetterAndInstanceSetter_thisClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static get x => 0;
  static set x(int p) {}
}
''');
  }

  test_constEvalTypeBoolNumString_equal_null() async {
    await assertNoErrorsInCode(r'''
class B {
  final v;
  const B.n1(num p) : v = p == null;
  const B.n2(num p) : v = null == p;
  const B.n3(Object p) : v = p == null;
  const B.n4(Object p) : v = null == p;
}
''');
  }

  test_constEvalTypeBoolNumString_notEqual_null() async {
    await assertNoErrorsInCode('''
class B {
  final v;
  const B.n1(num p) : v = p != null;
  const B.n2(num p) : v = null != p;
  const B.n3(Object p) : v = p != null;
  const B.n4(Object p) : v = null != p;
}
''');
  }

  test_genericTypeAlias_invalidGenericFunctionType() async {
    // There is a parse error, but no crashes.
    await assertErrorsInCode('''
typedef F = int;
main(p) {
  p is F;
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 10, 1),
    ]);
  }

  test_typePromotion_conditional_issue14655() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class C extends B {
  mc() {}
}
print(_) {}
main(A p) {
  (p is C) && (print(() => p) && (p is B)) ? p.mc() : p = null;
}
''');
  }

  test_typePromotion_functionType_arg_ignoreIfNotMoreSpecific() async {
    await assertNoErrorsInCode(r'''
typedef FuncB(B b);
typedef FuncA(A a);
class A {}
class B {}
main(FuncA f) {
  if (f is FuncB) {
    f(new A());
  }
}
''');
  }

  test_typePromotion_functionType_return_ignoreIfNotMoreSpecific() async {
    await assertErrorsInCode(r'''
class A {}
typedef FuncAtoDyn(A a);
typedef FuncDynToDyn(x);
main(FuncAtoDyn f) {
  if (f is FuncDynToDyn) {
    A a = f(new A());
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 115, 1),
    ]);
  }

  test_typePromotion_functionType_return_voidToDynamic() async {
    await assertErrorsInCode(r'''
typedef FuncDynToDyn(x);
typedef void FuncDynToVoid(x);
class A {}
main(FuncDynToVoid f) {
  if (f is FuncDynToDyn) {
    A a = f(null);
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 124, 1),
    ]);
  }

  test_typePromotion_if_extends_moreSpecific() async {
    await assertNoErrorsInCode(r'''
class V {}
class VP extends V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<VP>) {
    p.b;
  }
}
''');
  }

  test_typePromotion_if_implements_moreSpecific() async {
    await assertNoErrorsInCode(r'''
class V {}
class VP extends V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<VP>) {
    p.b;
  }
}
''');
  }
}
