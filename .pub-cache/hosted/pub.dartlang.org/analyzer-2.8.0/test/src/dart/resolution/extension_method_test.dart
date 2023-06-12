// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsDeclarationTest);
    defineReflectiveTests(ExtensionMethodsDeclarationWithoutNullSafetyTest);
    defineReflectiveTests(ExtensionMethodsExtendedTypeTest);
    defineReflectiveTests(ExtensionMethodsExtendedTypeWithoutNullSafetyTest);
    defineReflectiveTests(ExtensionMethodsExternalReferenceTest);
    defineReflectiveTests(
        ExtensionMethodsExternalReferenceWithoutNullSafetyTest);
    defineReflectiveTests(ExtensionMethodsInternalReferenceTest);
    defineReflectiveTests(
        ExtensionMethodsInternalReferenceWithoutNullSafetyTest);
  });
}

/// Tests that show that extension declarations and the members inside them are
/// resolved correctly.
@reflectiveTest
class ExtensionMethodsDeclarationTest extends PubPackageResolutionTest {
  test_this_type_interface() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {
    this;
  }
}
''');
    assertType(findNode.this_('this;'), 'int');
  }

  test_this_type_typeParameter() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  void foo() {
    this;
  }
}
''');
    assertType(findNode.this_('this;'), 'T');
  }

  test_this_type_typeParameter_withBound() async {
    await assertNoErrorsInCode('''
extension E<T extends Object> on T {
  void foo() {
    this;
  }
}
''');
    assertType(findNode.this_('this;'), 'T');
  }
}

/// Tests that show that extension declarations and the members inside them are
/// resolved correctly.
@reflectiveTest
class ExtensionMethodsDeclarationWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  @override
  List<MockSdkLibrary> get additionalMockSdkLibraries => [
        MockSdkLibrary('test1', [
          MockSdkLibraryUnit('test1/test1.dart', r'''
extension E on Object {
  int get a => 1;
}

class A {}
'''),
        ]),
        MockSdkLibrary('test2', [
          MockSdkLibraryUnit('test2/test2.dart', r'''
extension E on Object {
  int get a => 1;
}
'''),
        ]),
      ];

  test_constructor() async {
    await assertErrorsInCode('''
extension E {
  E() {}
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 12, 0),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
      error(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 16, 1),
    ]);
  }

  test_factory() async {
    await assertErrorsInCode('''
extension E {
  factory S() {}
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 12, 0),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
      error(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 16, 7),
    ]);
  }

  test_fromPlatform() async {
    await assertNoErrorsInCode('''
import 'dart:test2';

f(Object o) {
  o.a;
}
''');
  }

  test_metadata() async {
    await assertNoErrorsInCode('''
const int ann = 1;
class C {}
@ann
extension E on C {}
''');
    var annotation = findNode.annotation('@ann');
    assertElement(annotation, findElement.topVar('ann').getter);
  }

  test_multipleExtensions_noConflict() async {
    await assertNoErrorsInCode('''
class C {}
extension E1 on C {}
extension E2 on C {}
''');
  }

  test_this_type_interface() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {
    this;
  }
}
''');
    assertType(findNode.this_('this;'), 'int');
  }

  test_this_type_typeParameter() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  void foo() {
    this;
  }
}
''');
    assertType(findNode.this_('this;'), 'T');
  }

  test_this_type_typeParameter_withBound() async {
    await assertNoErrorsInCode('''
extension E<T extends Object> on T {
  void foo() {
    this;
  }
}
''');
    assertType(findNode.this_('this;'), 'T');
  }

  test_visibility_hidden() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}
extension E on C {
  int a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart' hide E;

f(C c) {
  c.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_visibility_notShown() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}
extension E on C {
  int a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart' show C;

f(C c) {
  c.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_visibility_shadowed_byClass() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart';

class E {}
f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(access, import.extension_('E').getGetter('a'));
    assertType(access, 'int');
  }

  test_visibility_shadowed_byImport() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
extension E on Object {
  int get a => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', content: '''
class E {}
class A {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';

f(Object o, A a) {
  o.a;
}
''');
    var access = findNode.prefixed('o.a');
    var import = findElement.importFind('package:test/lib1.dart');
    assertElement(access, import.extension_('E').getGetter('a'));
    assertType(access, 'int');
  }

  test_visibility_shadowed_byLocal_imported() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart';

f(C c) {
  double E = 2.71;
  c.a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 38, 1),
    ]);
    var access = findNode.prefixed('c.a');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(access, import.extension_('E').getGetter('a'));
    assertType(access, 'int');
  }

  test_visibility_shadowed_byLocal_local() async {
    await assertErrorsInCode('''
class C {}
extension E on C {
  int get a => 1;
}
f(C c) {
  double E = 2.71;
  c.a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 68, 1),
    ]);
    var access = findNode.prefixed('c.a');
    assertElement(access, findElement.getter('a'));
    assertType(access, 'int');
  }

  test_visibility_shadowed_byTopLevelVariable() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart';

double E = 2.71;
f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(access, import.extension_('E').getGetter('a'));
    assertType(access, 'int');
  }

  test_visibility_shadowed_platformByNonPlatform() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
extension E on Object {
  int get a => 1;
}
class B {}
''');
    await assertNoErrorsInCode('''
import 'dart:test1';
import 'lib.dart';

f(Object o, A a, B b) {
  o.a;
}
''');
  }

  test_visibility_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f(p.C c) {
  c.a;
}
''');
  }
}

@reflectiveTest
class ExtensionMethodsExtendedTypeTest extends PubPackageResolutionTest
    with ExtensionMethodsExtendedTypeTestCases {}

mixin ExtensionMethodsExtendedTypeTestCases on PubPackageResolutionTest {
  test_named_generic() async {
    await assertNoErrorsInCode('''
class C<T> {}
extension E<S> on C<S> {}
''');
    var extendedType = findNode.typeAnnotation('C<S>');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C<S>');
  }

  test_named_onDynamic() async {
    await assertNoErrorsInCode('''
extension E on dynamic {}
''');
    var extendedType = findNode.typeAnnotation('dynamic');
    assertType(extendedType, 'dynamic');
  }

  test_named_onEnum() async {
    await assertNoErrorsInCode('''
enum A {a, b, c}
extension E on A {}
''');
    var extendedType = findNode.typeAnnotation('A {}');
    assertElement(extendedType, findElement.enum_('A'));
    assertType(extendedType, 'A');
  }

  test_named_onFunctionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {}
''');
    var extendedType = findNode.typeAnnotation('Function');
    assertType(extendedType, 'int Function(int)');
  }

  test_named_onInterface() async {
    await assertNoErrorsInCode('''
class C { }
extension E on C {}
''');
    var extendedType = findNode.typeAnnotation('C {}');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C');
  }

  test_named_onMixin() async {
    await assertNoErrorsInCode('''
mixin M {
}
extension E on M {}
''');
    var extendedType = findNode.typeAnnotation('M {}');
    assertElement(extendedType, findElement.mixin('M'));
    assertType(extendedType, 'M');
  }

  test_unnamed_generic() async {
    await assertNoErrorsInCode('''
class C<T> {}
extension<S> on C<S> {}
''');
    var extendedType = findNode.typeAnnotation('C<S>');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C<S>');
  }

  test_unnamed_onDynamic() async {
    await assertNoErrorsInCode('''
extension on dynamic {}
''');
    var extendedType = findNode.typeAnnotation('dynamic');
    assertType(extendedType, 'dynamic');
  }

  test_unnamed_onEnum() async {
    await assertNoErrorsInCode('''
enum A {a, b, c}
extension on A {}
''');
    var extendedType = findNode.typeAnnotation('A {}');
    assertElement(extendedType, findElement.enum_('A'));
    assertType(extendedType, 'A');
  }

  test_unnamed_onFunctionType() async {
    await assertNoErrorsInCode('''
extension on int Function(String) {}
''');
    var extendedType = findNode.typeAnnotation('Function');
    assertType(extendedType, 'int Function(String)');
    var returnType = findNode.typeAnnotation('int');
    assertType(returnType, 'int');
    var parameterType = findNode.typeAnnotation('String');
    assertType(parameterType, 'String');
  }

  test_unnamed_onInterface() async {
    await assertNoErrorsInCode('''
class C { }
extension on C {}
''');
    var extendedType = findNode.typeAnnotation('C {}');
    assertElement(extendedType, findElement.class_('C'));
    assertType(extendedType, 'C');
  }

  test_unnamed_onMixin() async {
    await assertNoErrorsInCode('''
mixin M {
}
extension on M {}
''');
    var extendedType = findNode.typeAnnotation('M {}');
    assertElement(extendedType, findElement.mixin('M'));
    assertType(extendedType, 'M');
  }
}

/// Tests that show that extension declarations support all of the possible
/// types in the `on` clause.
@reflectiveTest
class ExtensionMethodsExtendedTypeWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ExtensionMethodsExtendedTypeTestCases, WithoutNullSafetyMixin {}

@reflectiveTest
class ExtensionMethodsExternalReferenceTest extends PubPackageResolutionTest
    with ExtensionMethodsExternalReferenceTestCases {
  test_instance_getter_fromInstance_Never() async {
    await assertNoErrorsInCode('''
extension E on Never {
  int get foo => 0;
}

f(Never a) {
  a.foo;
}
''');
    var access = findNode.prefixed('a.foo');
    assertElementNull(access);
    assertType(access, 'Never');
  }

  test_instance_getter_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  int get foo => 0;
}

f(int? a) {
  a.foo;
}
''');
    var access = findNode.prefixed('a.foo');
    assertElement(access, findElement.getter('foo', of: 'E'));
    assertType(access, 'int');
  }

  test_instance_getter_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

f(int? a) {
  a?.foo;
}
''');
    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.getter('foo', of: 'E'));
    assertType(identifier, 'int');
  }

  test_instance_method_fromInstance_Never() async {
    await assertErrorsInCode('''
extension E on Never {
  void foo() {}
}

f(Never a) {
  a.foo();
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 57, 1),
      error(HintCode.DEAD_CODE, 62, 3),
    ]);
    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'Never',
    );
  }

  test_instance_method_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  void foo() {}
}

f(int? a) {
  a.foo();
}
''');
    var invocation = findNode.methodInvocation('a.foo()');
    assertElement(invocation, findElement.method('foo', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromInstance_nullable_nullLiteral() async {
    await assertNoErrorsInCode('''
extension E on int? {
  void foo() {}
}

f(int? a) {
  null.foo();
}
''');
    var invocation = findNode.methodInvocation('null.foo()');
    assertElement(invocation, findElement.method('foo', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {}
}

f(int? a) {
  a?.foo();
}
''');
    var invocation = findNode.methodInvocation('a?.foo()');
    assertElement(invocation, findElement.method('foo', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromInstance_nullLiteral() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  void foo() {}
}

f() {
  null.foo();
}
''');
    var invocation = findNode.methodInvocation('null.foo()');
    assertMember(
      invocation,
      findElement.method('foo', of: 'E'),
      {'T': 'Null'},
    );
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_operator_binary_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  int operator +(int _) => 0;
}

f(A? a) {
  a + 1;
}
''');
    var binary = findNode.binary('a + 1');
    assertElement(binary, findElement.method('+'));
    assertType(binary, 'int');
  }

  test_instance_operator_index_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  int operator [](int index) => 0;
}

f(int? a) {
  a[0];
}
''');
    var index = findNode.index('a[0]');
    assertElement(index, findElement.method('[]'));
  }

  test_instance_operator_index_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int operator [](int index) => 0;
}

f(int? a) {
  a?[0];
}
''');
    var index = findNode.index('a?[0]');
    assertElement(index, findElement.method('[]'));
  }

  test_instance_operator_postfixInc_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  A? operator +(int _) => this;
}

f(A? a) {
  a++;
}
''');
    var expression = findNode.postfix('a++');
    assertElement(expression, findElement.method('+'));
    assertType(expression, 'A?');
  }

  test_instance_operator_prefixInc_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  A? operator +(int _) => this;
}

f(A? a) {
  ++a;
}
''');
    var expression = findNode.prefix('++a');
    assertElement(expression, findElement.method('+'));
    assertType(expression, 'A?');
  }

  test_instance_operator_unaryMinus_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  A? operator -() => this;
}

f(A? a) {
  -a;
}
''');
    var expression = findNode.prefix('-a');
    assertElement(expression, findElement.method('unary-'));
    assertType(expression, 'A?');
  }

  test_instance_setter_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  set foo(int _) {}
}

f(int? a) {
  a.foo = 1;
}
''');
    assertAssignment(
      findNode.assignment('foo = 1'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_setter_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

f(int? a) {
  a?.foo = 1;
}
''');
    assertAssignment(
      findNode.assignment('foo = 1'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int?',
    );
  }
}

mixin ExtensionMethodsExternalReferenceTestCases on PubPackageResolutionTest {
  /// Corresponds to: extension_member_resolution_t07
  test_dynamicInvocation() async {
    await assertNoErrorsInCode(r'''
class A {}
class C extends A {
  String method(int i) => "$i";
  noSuchMethod(Invocation i) { }
}

extension E<T extends A> on T {
  String method(int i, String s) => '';
}

main() {
  dynamic c = new C();
  c.method(42, "-42");
}
''');
  }

  test_instance_call_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  int call(int x) => 0;
}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  c(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('c(2)');
    assertElement(invocation, findElement.method('call', of: 'C'));
    assertInvokeType(invocation, 'int Function(int)');
    assertType(invocation, 'int');

    var cRef = invocation.function as SimpleIdentifier;
    assertElement(cRef, findElement.parameter('c'));
    assertType(cRef, 'C');
  }

  test_instance_call_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  c(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('c(2)');
    assertElement(invocation, findElement.method('call', of: 'E'));
    assertInvokeType(invocation, 'int Function(int)');
    assertType(invocation, 'int');

    var cRef = invocation.function as SimpleIdentifier;
    assertElement(cRef, findElement.parameter('c'));
    assertType(cRef, 'C');
  }

  test_instance_call_fromExtension_int() async {
    await assertNoErrorsInCode('''
extension E on int {
  int call(int x) => 0;
}

f() {
  1(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('1(2)');
    expect(
      invocation.staticElement,
      same(findElement.method('call', of: 'E')),
    );
    assertInvokeType(invocation, 'int Function(int)');
  }

  test_instance_compoundAssignment_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c += 2;
}
''');
    var assignment = findNode.assignment('+=');
    assertElement(assignment, findElement.method('+', of: 'C'));
  }

  test_instance_compoundAssignment_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c += 2;
}
''');
    var assignment = findNode.assignment('+=');
    assertElement(assignment, findElement.method('+', of: 'E'));
  }

  test_instance_getter_fromDifferentExtension_usingBounds() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  int get g => 0;
}
extension E2<T extends B> on T {
  void a() {
    g;
  }
}
''');
    var identifier = findNode.simple('g;');
    assertElement(identifier, findElement.getter('g'));
  }

  test_instance_getter_fromDifferentExtension_withoutTarget() async {
    await assertNoErrorsInCode('''
class C {}
extension E1 on C {
  int get a => 1;
}
extension E2 on C {
  void m() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_instance_getter_fromExtendedType_usingBounds() async {
    await assertNoErrorsInCode('''
class B {
  int get g => 0;
}
extension E<T extends B> on T {
  void a() {
    g;
  }
}
''');
    var identifier = findNode.simple('g;');
    assertElement(identifier, findElement.getter('g'));
  }

  test_instance_getter_fromExtendedType_withoutTarget() async {
    await assertNoErrorsInCode('''
class C {
  void m() {
    a;
  }
}
extension E on C {
  int get a => 1;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_instance_getter_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  int get a => 1;
}
g(int Function(int) f) {
  f.a;
}
''');
    var access = findNode.prefixed('f.a');
    assertElement(access, findElement.getter('a'));
    assertType(access, 'int');
  }

  test_instance_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
}

f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    assertElement(access, findElement.getter('a'));
    assertType(access, 'int');
  }

  test_instance_getter_methodInvocation() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  double Function(int) get a => (b) => 2.0;
}

f(C c) {
  c.a(0);
}
''');
    var invocation = findNode.functionExpressionInvocation('c.a(0)');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var function = invocation.function as PropertyAccess;
    assertElement(function.propertyName, findElement.getter('a', of: 'E'));
    assertType(function.propertyName, 'double Function(int)');
  }

  test_instance_getter_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}

extension A_Ext on A {
  int get a => 1;
}
extension B_Ext on B {
  int get a => 2;
}

f(B b) {
  b.a;
}
''');
    var access = findNode.prefixed('b.a');
    assertElement(access, findElement.getter('a', of: 'B_Ext'));
    assertType(access, 'int');
  }

  test_instance_getterInvoked_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  String Function() get a => () => 'a';
}
g(int Function(int) f) {
  f.a();
}
''');
    var invocation = findNode.functionExpressionInvocation('f.a()');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'String Function()');
    assertType(invocation, 'String');

    var function = invocation.function as PropertyAccess;
    assertElement(function.propertyName, findElement.getter('a', of: 'E'));
    assertType(function.propertyName, 'String Function()');
  }

  test_instance_method_fromDifferentExtension_usingBounds() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  void m() {}
}
extension E2<T extends B> on T {
  void a() {
    m();
  }
}
''');
    var invocation = findNode.methodInvocation('m();');
    assertElement(invocation, findElement.method('m'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromDifferentExtension_withoutTarget() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  void a() {}
}
extension E2 on B {
  void m() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromExtendedType_usingBounds() async {
    await assertNoErrorsInCode('''
class B {
  void m() {}
}
extension E<T extends B> on T {
  void a() {
    m();
  }
}
''');
    var invocation = findNode.methodInvocation('m();');
    assertElement(invocation, findElement.method('m'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromExtendedType_withoutTarget() async {
    await assertNoErrorsInCode('''
class B {
  void m() {
    a();
  }
}
extension E on B {
  void a() {}
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void a() {}
}
g(int Function(int) f) {
  f.a();
}
''');
    var invocation = findNode.methodInvocation('f.a()');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromInstance() async {
    await assertNoErrorsInCode('''
class B {}

extension A on B {
  void a() {}
}

f(B b) {
  b.a();
}
''');
    var invocation = findNode.methodInvocation('b.a()');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}

extension A_Ext on A {
  void a() {}
}
extension B_Ext on B {
  void a() {}
}

f(B b) {
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    assertElement(invocation, findElement.method('a', of: 'B_Ext'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_specificSubtypeMatchLocalGenerics() async {
    await assertNoErrorsInCode('''
class A<T> {}

class B<T> extends A<T> {}

class C {}

extension A_Ext<T> on A<T> {
  void f(T x) {}
}

extension B_Ext<T> on B<T> {
  void f(T x) {}
}

f(B<C> x, C o) {
  x.f(o);
}
''');
    var invocation = findNode.methodInvocation('x.f(o)');
    assertMember(
      invocation,
      findElement.method('f', of: 'B_Ext'),
      {'T': 'C'},
    );
    assertInvokeType(invocation, 'void Function(C)');
  }

  test_instance_operator_binary_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'C'));
  }

  test_instance_operator_binary_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator +(int i) {}
}
g(int Function(int) f) {
  f + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'E'));
  }

  test_instance_operator_binary_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'E'));
  }

  test_instance_operator_binary_undefinedTarget() async {
    // Ensure that there is no exception thrown while resolving the code.
    await assertErrorsInCode('''
extension on Object {}
var a = b + c;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 31, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 35, 1),
    ]);
  }

  test_instance_operator_index_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator [](int index) {}
}
extension E on C {
  void operator [](int index) {}
}
f(C c) {
  c[2];
}
''');
    var index = findNode.index('c[2]');
    assertElement(index, findElement.method('[]', of: 'C'));
  }

  test_instance_operator_index_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator [](int index) {}
}
g(int Function(int) f) {
  f[2];
}
''');
    var index = findNode.index('f[2]');
    assertElement(index, findElement.method('[]', of: 'E'));
  }

  test_instance_operator_index_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator [](int index) {}
}
f(C c) {
  c[2];
}
''');
    var index = findNode.index('c[2]');
    assertElement(index, findElement.method('[]', of: 'E'));
  }

  test_instance_operator_indexEquals_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator []=(int index, int value) {}
}
extension E on C {
  void operator []=(int index, int value) {}
}
f(C c) {
  c[2] = 1;
}
''');
    assertAssignment(
      findNode.assignment('[2] ='),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]=', of: 'C'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_operator_indexEquals_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator []=(int index, int value) {}
}
g(int Function(int) f) {
  f[2] = 3;
}
''');
    assertAssignment(
      findNode.assignment('f[2]'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]=', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_operator_indexEquals_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int index, int value) {}
}
f(C c) {
  c[2] = 3;
}
''');
    assertAssignment(
      findNode.assignment('c[2]'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]=', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_operator_postfix_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c++;
}
''');
    var postfix = findNode.postfix('++');
    assertElement(postfix, findElement.method('+', of: 'C'));
  }

  test_instance_operator_postfix_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  int Function(int) operator +(int i) => this;
}
g(int Function(int) f) {
  f++;
}
''');
    var postfix = findNode.postfix('++');
    assertElement(postfix, findElement.method('+', of: 'E'));
  }

  test_instance_operator_postfix_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c++;
}
''');
    var postfix = findNode.postfix('++');
    assertElement(postfix, findElement.method('+', of: 'E'));
  }

  test_instance_operator_prefix_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  ++c;
}
''');
    var prefix = findNode.prefix('++');
    assertElement(prefix, findElement.method('+', of: 'C'));
  }

  test_instance_operator_prefix_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  int Function(int) operator +(int i) => this;
}
g(int Function(int) f) {
  ++f;
}
''');
    var prefix = findNode.prefix('++');
    assertElement(prefix, findElement.method('+', of: 'E'));
  }

  test_instance_operator_prefix_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  ++c;
}
''');
    var prefix = findNode.prefix('++');
    assertElement(prefix, findElement.method('+', of: 'E'));
  }

  test_instance_operator_unary_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator -() => this;
}
extension E on C {
  C operator -() => this;
}
f(C c) {
  -c;
}
''');
    var prefix = findNode.prefix('-c');
    assertElement(prefix, findElement.method('unary-', of: 'C'));
  }

  test_instance_operator_unary_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator -() {}
}
g(int Function(int) f) {
  -f;
}
''');
    var prefix = findNode.prefix('-f');
    assertElement(prefix, findElement.method('unary-', of: 'E'));
  }

  test_instance_operator_unary_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator -() => this;
}
f(C c) {
  -c;
}
''');
    var prefix = findNode.prefix('-c');
    assertElement(prefix, findElement.method('unary-', of: 'E'));
  }

  test_instance_setter_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  set a(int x) {}
}
g(int Function(int) f) {
  f.a = 1;
}
''');
    assertAssignment(
      findNode.assignment('a = 1'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_setter_oneMatch() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  set a(int x) {}
}

f(C c) {
  c.a = 1;
}
''');
    assertAssignment(
      findNode.assignment('a = 1'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_tearoff_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void a(int x) {}
}
g(int Function(int) f) => f.a;
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_instance_tearoff_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
}

f(C c) => c.a;
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_static_field_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}

extension E on C {
  static int a = 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a;
}
''');
    var identifier = findNode.simple('a;');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(identifier, import.extension_('E').getGetter('a'));
    assertType(identifier, 'int');
  }

  test_static_field_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
}

f() {
  E.a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}

extension E on C {
  static int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a;
}
''');
    var identifier = findNode.simple('a;');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(identifier, import.extension_('E').getGetter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
}

f() {
  E.a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_method_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}

extension E on C {
  static void a() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a();
}
''');
    var invocation = findNode.methodInvocation('E.a()');
    var import = findElement.importFind('package:test/lib.dart');
    assertElement(invocation, import.extension_('E').getMethod('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_method_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f() {
  E.a();
}
''');
    var invocation = findNode.methodInvocation('E.a()');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_setter_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class C {}

extension E on C {
  static set a(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a = 3;
}
''');
    var importFind = findElement.importFind('package:test/lib.dart');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: importFind.setter('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_static_setter_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
}

f() {
  E.a = 3;
}
''');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_static_tearoff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
}

f() => E.a;
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_thisAccessOnDynamic() async {
    await assertNoErrorsInCode('''
extension E on dynamic {
  int get d => 3;

  void testDynamic() {
    // Static type of `this` is dynamic, allows dynamic invocation.
    this.arglebargle();
  }
}
''');
  }

  test_thisAccessOnFunction() async {
    await assertNoErrorsInCode('''
extension E on Function {
  int get f => 4;

  void testFunction() {
    // Static type of `this` is Function. Allows any dynamic invocation.
    this();
    this(1);
    this(x: 1);
    // No function can have both optional positional and named parameters.
  }
}
''');
  }
}

/// Tests that extension members can be correctly resolved when referenced
/// by code external to the extension declaration.
@reflectiveTest
class ExtensionMethodsExternalReferenceWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ExtensionMethodsExternalReferenceTestCases, WithoutNullSafetyMixin {}

@reflectiveTest
class ExtensionMethodsInternalReferenceTest extends PubPackageResolutionTest
    with ExtensionMethodsInternalReferenceTestCases {}

mixin ExtensionMethodsInternalReferenceTestCases on PubPackageResolutionTest {
  test_instance_call() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
  int m() => this(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('this(2)');
    assertElement(invocation, findElement.method('call', of: 'E'));
    assertType(invocation, 'int');
  }

  test_instance_getter_asSetter() async {
    await assertErrorsInCode('''
extension E1 on int {
  int get foo => 0;
}

extension E2 on int {
  int get foo => 0;
  void f() {
    foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 104, 3),
    ]);
    assertAssignment(
      findNode.assignment('foo = 0'),
      readElement: null,
      readType: null,
      writeElement: findElement.getter('foo', of: 'E2'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 1;
}

extension E on C {
  int get a => 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a', of: 'E'));
    assertType(identifier, 'int');
  }

  test_instance_getter_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 1;
}

extension E on C {
  int get a => 1;
  int m() => this.a;
}
''');
    var access = findNode.propertyAccess('this.a');
    assertPropertyAccess(access, findElement.getter('a', of: 'C'), 'int');
  }

  test_instance_getter_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
  int m() => this.a;
}
''');
    var access = findNode.propertyAccess('this.a');
    assertPropertyAccess(access, findElement.getter('a', of: 'E'), 'int');
  }

  test_instance_method_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}
extension E on C {
  void a() {}
  void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}
extension E on C {
  void a() {}
  void b() { this.a(); }
}
''');
    var invocation = findNode.methodInvocation('this.a');
    assertElement(invocation, findElement.method('a', of: 'C'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_method_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void a() {}
  void b() { this.a(); }
}
''');
    var invocation = findNode.methodInvocation('this.a');
    assertElement(invocation, findElement.method('a', of: 'E'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_instance_operator_binary_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
  void b() { this + 2; }
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'C'));
  }

  test_instance_operator_binary_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
  void b() { this + 2; }
}
''');
    var binary = findNode.binary('+ ');
    assertElement(binary, findElement.method('+', of: 'E'));
  }

  test_instance_operator_index_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator [](int index) {}
}
extension E on C {
  void operator [](int index) {}
  void b() { this[2]; }
}
''');
    var index = findNode.index('this[2]');
    assertElement(index, findElement.method('[]', of: 'C'));
  }

  test_instance_operator_index_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator [](int index) {}
  void b() { this[2]; }
}
''');
    var index = findNode.index('this[2]');
    assertElement(index, findElement.method('[]', of: 'E'));
  }

  test_instance_operator_indexEquals_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator []=(int index, int value) {}
}
extension E on C {
  void operator []=(int index, int value) {}
  void b() { this[2] = 1; }
}
''');
    assertAssignment(
      findNode.assignment('this[2]'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]=', of: 'C'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_operator_indexEquals_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int index, int value) {}
  void b() { this[2] = 3; }
}
''');
    assertAssignment(
      findNode.assignment('this[2]'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]=', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_operator_unary_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator -() {}
}
extension E on C {
  void operator -() {}
  void b() { -this; }
}
''');
    var prefix = findNode.prefix('-this');
    assertElement(prefix, findElement.method('unary-', of: 'C'));
  }

  test_instance_operator_unary_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator -() {}
  void b() { -this; }
}
''');
    var prefix = findNode.prefix('-this');
    assertElement(prefix, findElement.method('unary-', of: 'E'));
  }

  test_instance_setter_asGetter() async {
    await assertErrorsInCode('''
extension E1 on int {
  set foo(int _) {}
}

extension E2 on int {
  set foo(int _) {}
  void f() {
    foo;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 104, 3),
    ]);
    assertSimpleIdentifier(
      findNode.simple('foo;'),
      element: null,
      type: 'dynamic',
    );
  }

  test_instance_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

extension E on C {
  set a(int _) {}
  void m() {
    a = 3;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_setter_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

extension E on C {
  set a(int _) {}
  void m() {
    this.a = 3;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a', of: 'C'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_setter_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  set a(int _) {}
  void m() {
    this.a = 3;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_instance_tearoff_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
  get b => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_instance_tearoff_fromThis() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
  get c => this.a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_static_field_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_field_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
  static int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_getter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
  static int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'int');
  }

  test_static_method_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  static void a() {}
  void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_method_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  static void a() {}
  static void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.method('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_static_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
  void m() {
    a = 3;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_static_setter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
  static void m() {
    a = 3;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 3'),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_static_tearoff_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
  get b => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_static_tearoff_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
  static get c => a;
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.method('a'));
    assertType(identifier, 'void Function(int)');
  }

  test_topLevel_function_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}

void a() {}

extension E on C {
  void b() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.topFunction('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_topLevel_function_fromStatic() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}

void a() {}

extension E on C {
  static void b() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertElement(invocation, findElement.topFunction('a'));
    assertInvokeType(invocation, 'void Function()');
  }

  test_topLevel_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 0;
}

int get a => 0;

extension E on C {
  void b() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.topGet('a'));
    assertType(identifier, 'int');
  }

  test_topLevel_getter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 0;
}

int get a => 0;

extension E on C {
  static void b() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.topGet('a'));
    assertType(identifier, 'int');
  }

  test_topLevel_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

set a(int _) {}

extension E on C {
  void b() {
    a = 0;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 0'),
      readElement: null,
      readType: null,
      writeElement: findElement.topSet('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }

  test_topLevel_setter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

set a(int _) {}

extension E on C {
  static void b() {
    a = 0;
  }
}
''');
    assertAssignment(
      findNode.assignment('a = 0'),
      readElement: null,
      readType: null,
      writeElement: findElement.topSet('a'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );
  }
}

/// Tests that extension members can be correctly resolved when referenced
/// by code internal to (within) the extension declaration.
@reflectiveTest
class ExtensionMethodsInternalReferenceWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ExtensionMethodsInternalReferenceTestCases, WithoutNullSafetyMixin {}
