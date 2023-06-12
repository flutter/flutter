// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationResolutionTest);
    defineReflectiveTests(MethodInvocationResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class MethodInvocationResolutionTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, MethodInvocationResolutionTestCases {}

mixin MethodInvocationResolutionTestCases on PubPackageResolutionTest {
  test_clamp_double_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'),
        [typeStringByNullability(nullable: 'double', legacy: 'num')]);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'),
        [typeStringByNullability(nullable: 'double', legacy: 'num')]);
  }

  test_clamp_double_context_int() async {
    await assertErrorsInCode(
        '''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 17),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'), ['num']);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'), ['num']);
  }

  test_clamp_double_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  a.clamp(f(), f());
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'), ['num']);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'), ['num']);
  }

  test_clamp_double_double_double() async {
    await assertNoErrorsInCode('''
f(double a, double b, double c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType:
            typeStringByNullability(nullable: 'double', legacy: 'num'));
  }

  test_clamp_double_double_int() async {
    await assertNoErrorsInCode('''
f(double a, double b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_double_int_double() async {
    await assertNoErrorsInCode('''
f(double a, int b, double c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_double_int_int() async {
    await assertNoErrorsInCode('''
f(double a, int b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_context_double() async {
    await assertErrorsInCode(
        '''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 17),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'), ['num']);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'), ['num']);
  }

  test_clamp_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_clamp_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a.clamp(f(), f());
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'), ['num']);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'), ['num']);
  }

  test_clamp_int_double_double() async {
    await assertNoErrorsInCode('''
f(int a, double b, double c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_double_dynamic() async {
    await assertNoErrorsInCode('''
f(int a, double b, dynamic c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_double_int() async {
    await assertNoErrorsInCode('''
f(int a, double b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_dynamic_double() async {
    await assertNoErrorsInCode('''
f(int a, dynamic b, double c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_dynamic_int() async {
    await assertNoErrorsInCode('''
f(int a, dynamic b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_int_double() async {
    await assertNoErrorsInCode('''
f(int a, int b, double c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_int_dynamic() async {
    await assertNoErrorsInCode('''
f(int a, int b, dynamic c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_int_int() async {
    await assertNoErrorsInCode('''
f(int a, int b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: typeStringByNullability(nullable: 'int', legacy: 'num'));
  }

  test_clamp_int_int_int_from_cascade() async {
    await assertErrorsInCode(
        '''
f(int a, int b, int c) {
  a..clamp(b, c).isEven;
}
''',
        expectedErrorsByNullability(nullable: [], legacy: [
          error(CompileTimeErrorCode.UNDEFINED_GETTER, 42, 6),
        ]));

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: typeStringByNullability(nullable: 'int', legacy: 'num'));
  }

  test_clamp_int_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
extension E on int {
  String clamp(int x, int y) => '';
}
f(int a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp(b'),
        elementMatcher(findElement.extension_('E').getMethod('clamp')),
        'String Function(int, int)',
        expectedType: 'String');
  }

  test_clamp_int_int_never() async {
    await assertNoErrorsInCode('''
f(int a, int b, Never c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_int_never_int() async {
    await assertErrorsInCode(
        '''
f(int a, Never b, int c) {
  a.clamp(b, c);
}
''',
        expectedErrorsByNullability(nullable: [
          error(HintCode.DEAD_CODE, 40, 3),
        ], legacy: []));

    assertMethodInvocation(
        findNode.methodInvocation('clamp'),
        elementMatcher(numElement.getMethod('clamp'),
            isLegacy: isLegacyLibrary),
        'num Function(num, num)',
        expectedType: 'num');
  }

  test_clamp_never_int_int() async {
    await assertErrorsInCode(
        '''
f(Never a, int b, int c) {
  a.clamp(b, c);
}
''',
        expectedErrorsByNullability(nullable: [
          error(HintCode.RECEIVER_OF_TYPE_NEVER, 29, 1),
          error(HintCode.DEAD_CODE, 36, 7),
        ], legacy: [
          error(CompileTimeErrorCode.UNDEFINED_METHOD, 31, 5),
        ]));

    assertMethodInvocation(
        findNode.methodInvocation('clamp'), isNull, 'dynamic',
        expectedType:
            typeStringByNullability(nullable: 'Never', legacy: 'dynamic'));
  }

  test_clamp_other_context_int() async {
    await assertErrorsInCode(
        '''
abstract class A {
  num clamp(String x, String y);
}
T f<T>() => throw Error();
g(A a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 94, 17),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f(),'), ['String']);
    assertTypeArgumentTypes(findNode.methodInvocation('f())'), ['String']);
  }

  test_clamp_other_int_int() async {
    await assertNoErrorsInCode('''
abstract class A {
  String clamp(int x, int y);
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp(b'),
        elementMatcher(findElement.class_('A').getMethod('clamp')),
        'String Function(int, int)',
        expectedType: 'String');
  }

  test_clamp_other_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp(b'),
        elementMatcher(findElement.extension_('E').getMethod('clamp')),
        'String Function(int, int)',
        expectedType: 'String');
  }

  test_clamp_other_int_int_via_extension_implicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('clamp(b'),
        elementMatcher(findElement.extension_('E').getMethod('clamp')),
        'String Function(int, int)',
        expectedType: 'String');
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
void test<T>(T t) {}

void f<S>(S s) {
  if (s is int) {
    test(s);
  }
}

''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('test(s)'),
      ['S'],
    );
  }

  test_error_ambiguousImport_topFunction() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void foo(int _) {}
''');
    newFile('$testPackageLibPath/b.dart', content: r'''
void foo(int _) {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 46, 3),
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');
  }

  test_error_ambiguousImport_topFunction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void foo(int _) {}
''');
    newFile('$testPackageLibPath/b.dart', content: r'''
void foo(int _) {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 58, 3),
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');
  }

  test_error_instanceAccessToStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

void f(A a) {
  a.foo(0);
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 59, 3),
    ]);
    assertMethodInvocation2(
      findNode.methodInvocation('a.foo(0)'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'void Function(int)',
      type: 'void',
    );
  }

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    await assertErrorsInCode(r'''
class C {
  void Function() call = throw Error();
}

void f(C c) {
  c();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 69, 1),
    ]);

    var invocation = findNode.functionExpressionInvocation('c();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var cRef = invocation.function as SimpleIdentifier;
    assertElement(cRef, findElement.parameter('c'));
    assertType(cRef, 'C');
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_instance() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;
}

void f(C c) {
  c.foo();
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertTypeDynamic(foo);
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertTypeDynamic(foo.propertyName);
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertTypeDynamic(foo);
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertTypeDynamic(foo);
  }

  test_error_invocationOfNonFunction_OK_Function() async {
    await assertNoErrorsInCode(r'''
f(Function foo) {
  foo(1, 2);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(1, 2);');
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.parameter('foo'));
    assertType(foo, 'Function');
  }

  test_error_invocationOfNonFunction_OK_functionTypeTypeParameter() async {
    await assertNoErrorsInCode(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  C(this.foo);

  main() {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_error_invocationOfNonFunction_parameter() async {
    await assertErrorsInCode(r'''
main(Object foo) {
  foo();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 21, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.parameter('foo'));
    assertType(foo, 'Object');
  }

  test_error_invocationOfNonFunction_parameter_dynamic() async {
    await assertNoErrorsInCode(r'''
main(var foo) {
  foo();
}
''');

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.parameter('foo'));
    assertTypeDynamic(foo);
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;
}

main() {
  C.foo();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 46, 5),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'int');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'int');
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;

  main() {
    foo();
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 48, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'int');
  }

  test_error_invocationOfNonFunction_super_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 68, 9),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'int');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'int');

    assertSuperExpression(foo.target);
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void foo() {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 6),
    ]);

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo();');
    assertMethodInvocation(
      invocation,
      import.topFunction('foo'),
      'void Function()',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_error_prefixIdentifierNotFollowedByDot_deferred() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 49, 4),
    ]);

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
      expectedType: 'Future<dynamic>$question',
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_error_prefixIdentifierNotFollowedByDot_invoke() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 3),
    ]);
    _assertInvalidInvocation(
      'foo()',
      findElement.import('dart:math').prefix,
      dynamicNameType: true,
    );
  }

  test_error_undefinedFunction() async {
    await assertErrorsInCode(r'''
main() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 11, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0)');
  }

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 45, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedIdentifier_target() async {
    await assertErrorsInCode(r'''
main() {
  bar.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 11, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class() async {
    await assertErrorsInCode(r'''
class C {}
main() {
  C.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    await assertErrorsInCode(r'''
class C {}

int x = 0;
main() {
  C.foo(x);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 36, 3),
    ]);

    _assertUnresolvedMethodInvocation('foo(x);');
    assertTopGetRef('x)', 'x');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    await assertErrorsInCode(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 76, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    await assertErrorsInCode(r'''
class C {}

main() {
  C.foo<int>();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);

    _assertUnresolvedMethodInvocation(
      'foo<int>();',
      expectedTypeArguments: ['int'],
    );
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  static main() => C.T();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 34, 1),
    ]);
    _assertUnresolvedMethodInvocation('C.T();');
  }

  test_error_undefinedMethod_hasTarget_instance() async {
    await assertErrorsInCode(r'''
main() {
  42.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 14, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    await assertErrorsInCode(r'''
main() {
  var v = () {};
  v.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 30, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  main() {
    foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
  }

  test_error_undefinedMethod_null() async {
    await assertErrorsInCode(r'''
main() {
  null.foo();
}
''', [
      if (typeToStringWithNullability)
        error(CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE, 16, 3)
      else
        error(CompileTimeErrorCode.UNDEFINED_METHOD, 16, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo();');
  }

  test_error_undefinedMethod_object_call() async {
    await assertErrorsInCode(r'''
main(Object o) {
  o.call();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 21, 4),
    ]);
  }

  test_error_undefinedMethod_private() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  void _foo(int _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 53, 4),
    ]);
    _assertUnresolvedMethodInvocation('_foo(0);');
  }

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 50, 3),
    ]);
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance methods of Type.
    await assertErrorsInCode(r'''
class A {}
main() {
  A?.toString();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 8),
    ]);
  }

  test_error_undefinedSuperMethod() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 62, 3),
    ]);
    _assertUnresolvedMethodInvocation('foo(0);');
    assertSuperExpression(findNode.super_('super.foo'));
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''', [
      error(
          CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          71,
          3),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 75, 1),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('foo(0)'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_prefixed() async {
    await assertErrorsInCode(r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_show() async {
    await assertErrorsInCode(r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
    _assertUnresolvedMethodInvocation('foo(1);');
    _assertUnresolvedMethodInvocation('bar(2);');
  }

  test_error_useOfVoidResult_name_getter() async {
    await assertErrorsInCode('''
class C<T>{
  T foo;
  C(this.foo);
}

void f(C<void> c) {
  c.foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 61, 5),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'void');
    assertMember(foo.propertyName, findElement.getter('foo'), {'T': 'void'});
    assertType(foo.propertyName, 'void');
  }

  test_error_useOfVoidResult_name_localVariable() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertType(foo, 'void');
  }

  test_error_useOfVoidResult_name_topFunction() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo()();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 3),
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo()()'),
      findElement.topFunction('foo'),
      'void Function()',
    );
  }

  test_error_useOfVoidResult_name_topVariable() async {
    await assertErrorsInCode(r'''
void foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 22, 3),
    ]);

    var invocation = findNode.functionExpressionInvocation('foo();');
    assertElementNull(invocation);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.topGet('foo'));
    assertType(foo, 'void');
  }

  test_error_useOfVoidResult_receiver() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo.toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);
    assertMethodInvocation2(
      findNode.methodInvocation('toString()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_error_useOfVoidResult_receiver_cascade() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo..toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);
    assertMethodInvocation2(
      findNode.methodInvocation('toString()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_error_useOfVoidResult_receiver_withNull() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo?.toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);
    assertMethodInvocation2(
      findNode.methodInvocation('toString()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_error_wrongNumberOfTypeArgumentsMethod_01() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 29, 5),
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      'void Function()',
    );
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    await assertErrorsInCode(r'''
Map<T, U> foo<T extends num, U>() => throw Error();

main() {
  foo<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 67, 5),
    ]);
    assertMethodInvocation(
      findNode.methodInvocation('foo<int>()'),
      findElement.topFunction('foo'),
      'Map<dynamic, dynamic> Function()',
      expectedTypeArguments: ['dynamic', 'dynamic'],
    );
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_hasReceiver_class_staticGetter() async {
    await assertNoErrorsInCode(r'''
class C {
  static double Function(int) get foo => throw Error();
}

main() {
  C.foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertClassRef(foo.target, findElement.class_('C'));
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'double Function(int)');
  }

  test_hasReceiver_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
    assertClassRef(invocation.target, findElement.class_('C'));
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertImportPrefix(invocation.target, import.prefix);

    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
    );
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary_extraArgument() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary(1 + 2);
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 66, 5),
    ]);

    var import = findElement.importFind('dart:math');

    var invocation = findNode.methodInvocation('loadLibrary(1 + 2)');
    assertImportPrefix(invocation.target, import.prefix);

    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic> Function()',
    );

    assertType(findNode.binary('1 + 2'), 'int');
  }

  test_hasReceiver_dynamic_hash() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.hash(0, 1);
}
''');
    assertMethodInvocation2(
      findNode.methodInvocation('hash('),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_functionTyped() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');

    var invocation = findNode.methodInvocation('call(0)');
    assertMethodInvocation(
      invocation,
      null,
      'void Function(int)',
    );
    assertElement(invocation.target, findElement.topFunction('foo'));
    assertType(invocation.target, 'void Function(int)');
  }

  test_hasReceiver_functionTyped_generic() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T _) {}

main() {
  foo.call(0);
}
''');

    var invocation = findNode.methodInvocation('call(0)');
    assertMethodInvocation(
      invocation,
      null,
      'void Function(int)',
      expectedTypeArguments: ['int'],
    );
    assertElement(invocation.target, findElement.topFunction('foo'));
    assertType(invocation.target, 'void Function<T>(T)');
  }

  test_hasReceiver_importPrefix_topFunction() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
T foo<T extends num>(T a, T b) => a;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(1, 2)');
    assertMethodInvocation(
      invocation,
      import.topFunction('foo'),
      'int Function(int, int)',
      expectedTypeArguments: ['int'],
    );
    assertImportPrefix(invocation.target, import.prefix);
  }

  test_hasReceiver_importPrefix_topGetter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
T Function<T>(T a, T b) get foo => null;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.functionExpressionInvocation('foo(1, 2);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'int Function(int, int)');
    assertType(invocation, 'int');

    var foo = invocation.function as PrefixedIdentifier;
    assertType(foo, 'T Function<T>(T, T)');
    assertElement(foo.identifier, import.topGet('foo'));
    assertType(foo.identifier, 'T Function<T>(T, T)');

    assertImportPrefix(foo.prefix, import.prefix);
  }

  test_hasReceiver_instance_Function_call_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(Function getFunction()) {
  Function foo = getFunction();

  foo.call(0);
}
''');
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_Function_call_topVariable() async {
    await assertNoErrorsInCode(r'''
Function foo = throw Error();

void main() {
  foo.call(0);
}
''');
    _assertInvalidInvocation('call(0)', null);
  }

  test_hasReceiver_instance_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => throw Error();
}

void f(C c) {
  c.foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'double Function(int)');
  }

  /// It is important to use this expression as an initializer of a top-level
  /// variable, because of the way top-level inference works, at the time of
  /// writing this. We resolve initializers twice - first for dependencies,
  /// then for resolution. This has its issues (for example we miss some
  /// dependencies), but the important thing is that we rewrite `foo(0)` from
  /// being a [MethodInvocation] to [FunctionExpressionInvocation]. So, during
  /// the second pass we see [SimpleIdentifier] `foo` as a `function`. And
  /// we should be aware that it is not a stand-alone identifier, but a
  /// cascade section.
  test_hasReceiver_instance_getter_cascade() async {
    await resolveTestCode(r'''
class C {
  double Function(int) get foo => 0;
}

var v = C()..foo(0) = 0;
''');

    var invocation = findNode.functionExpressionInvocation('foo(0)');
    assertFunctionExpressionInvocation(
      invocation,
      element: null,
      typeArgumentTypes: [],
      invokeType: 'double Function(int)',
      type: 'double',
    );
    assertSimpleIdentifier(
      invocation.function,
      element: findElement.getter('foo'),
      type: 'double Function(int)',
    );
  }

  test_hasReceiver_instance_getter_switchStatementExpression() async {
    await assertNoErrorsInCode(r'''
class C {
  int Function() get foo => throw Error();
}

void f(C c) {
  switch ( c.foo() ) {
    default:
      break;
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo()');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'int Function()');
    assertType(invocation, 'int');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'int Function()');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'int Function()');
  }

  test_hasReceiver_instance_method() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}
}

void f(C c) {
  c.foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
      expectedMethodNameType: 'void Function(int)',
    );
    assertTypeArgumentTypes(invocation, []);
  }

  test_hasReceiver_instance_method_generic() async {
    await assertNoErrorsInCode(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

void f(C c) {
  c.foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'int Function(int)',
      expectedMethodNameType: 'int Function(int)',
      expectedTypeArguments: ['int'],
    );
    assertTypeArgumentTypes(invocation, ['int']);
  }

  test_hasReceiver_instance_method_issue30552() async {
    await assertNoErrorsInCode(r'''
abstract class I1 {
  void foo(int i);
}

abstract class I2 {
  void foo(Object o);
}

abstract class C implements I1, I2 {}

class D extends C {
  void foo(Object o) {}
}

void f(C c) {
  c.foo('hi');
}
''');

    var invocation = findNode.methodInvocation("foo('hi')");
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'I2'),
      'void Function(Object)',
    );
  }

  test_hasReceiver_instance_typeParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class C<T extends A> {
  T a;
  C(this.a);

  main() {
    a.foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_hasReceiver_prefixed_class_staticGetter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class C {
  static double Function(int) get foo => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, import.class_('C').getGetter('foo'));
    assertType(foo.propertyName, 'double Function(int)');

    var target = foo.target as PrefixedIdentifier;
    assertImportPrefix(target.prefix, import.prefix);
    assertClassRef(target.identifier, import.class_('C'));
  }

  test_hasReceiver_prefixed_class_staticMethod() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class C {
  static void foo(int _) => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      import.class_('C').getMethod('foo'),
      'void Function(int)',
    );

    var target = invocation.target as PrefixedIdentifier;
    assertImportPrefix(target.prefix, import.prefix);
    assertClassRef(target.identifier, import.class_('C'));
  }

  test_hasReceiver_super_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'double Function(int)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'double Function(int)');

    assertSuperExpression(foo.target);
  }

  test_hasReceiver_super_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0);');
    assertMethodInvocation(
      invocation,
      findElement.method('foo', of: 'A'),
      'void Function(int)',
    );
    assertSuperExpression(invocation.target);
  }

  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode('''
void f({a = b?.foo()}) {}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('?.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode('''
typedef void F({a = b?.foo()});
''');

    assertMethodInvocation2(
      findNode.methodInvocation('?.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_namedArgument() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
void foo({int$question a, bool$question b}) {}

main() {
  foo(b: false, a: 0);
}
''');

    var invocation = findNode.methodInvocation('foo(b:');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      'void Function({int$question a, bool$question b})',
    );
    assertNamedParameterRef('b: false', 'b');
    assertNamedParameterRef('a: 0', 'a');
  }

  test_noReceiver_getter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_noReceiver_getter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => throw Error();

  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.getter('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_noReceiver_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 40, 4),
    ]);
    assertElement(findNode.simple('math()'), findElement.prefix('math'));
  }

  test_noReceiver_localFunction() async {
    await assertNoErrorsInCode(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.localFunction('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_localVariable_call() async {
    await assertNoErrorsInCode(r'''
class C {
  void call(int _) {}
}

void f(C c) {
  c(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('c(0);');
    assertElement(invocation, findElement.method('call', of: 'C'));
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var cRef = invocation.function as SimpleIdentifier;
    assertElement(cRef, findElement.parameter('c'));
    assertType(cRef, 'C');
  }

  test_noReceiver_localVariable_promoted() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.localVar('foo'));
    assertType(foo, 'void Function(int)');
  }

  test_noReceiver_method_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_method_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.method('foo'),
      'void Function(int)',
    );
  }

  test_noReceiver_parameter() async {
    await assertNoErrorsInCode(r'''
void f(void Function(int) foo) {
  foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.parameter('foo'));
    assertType(foo, 'void Function(int)');
  }

  test_noReceiver_parameter_call_nullAware() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
double Function(int)$question foo;

main() {
  foo?.call(1);
}
    ''');

    var invocation = findNode.methodInvocation('call(1)');
    if (typeToStringWithNullability) {
      assertType(invocation.target, 'double Function(int)?');
    } else {
      assertTypeLegacy(invocation.target);
    }
  }

  test_noReceiver_parameter_functionTyped_typedef() async {
    await assertNoErrorsInCode(r'''
typedef F = void Function();

void f(F a) {
  a();
}
''');

    var invocation = findNode.functionExpressionInvocation('a();');
    assertFunctionExpressionInvocation(
      invocation,
      element: null,
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );

    var aRef = invocation.function as SimpleIdentifier;
    assertElement(aRef, findElement.parameter('a'));
    assertType(aRef, 'void Function()');
  }

  test_noReceiver_topFunction() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertMethodInvocation(
      invocation,
      findElement.topFunction('foo'),
      'void Function(int)',
      expectedMethodNameType: 'void Function(int)',
    );
  }

  test_noReceiver_topGetter() async {
    await assertNoErrorsInCode(r'''
double Function(int) get foo => throw Error();

main() {
  foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'double Function(int)');
    assertType(invocation, 'double');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.topGet('foo'));
    assertType(foo, 'double Function(int)');
  }

  test_noReceiver_topVariable() async {
    await assertNoErrorsInCode(r'''
void Function(int) foo = throw Error();

main() {
  foo(0);
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(0);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(int)');
    assertType(invocation, 'void');

    var foo = invocation.function as SimpleIdentifier;
    assertElement(foo, findElement.topGet('foo'));
    assertType(foo, 'void Function(int)');
  }

  test_objectMethodOnDynamic_argumentsDontMatch() async {
    await assertNoErrorsInCode(r'''
void f(a, int b) {
  a.toString(b);
}
''');
    assertMethodInvocation2(
      findNode.methodInvocation('toString(b)'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );

    assertType(findNode.simple('b);'), 'int');
  }

  test_objectMethodOnDynamic_argumentsMatch() async {
    await assertNoErrorsInCode(r'''
void f(a) {
  a.toString();
}
''');
    assertMethodInvocation2(
      findNode.methodInvocation('toString()'),
      element: elementMatcher(
        objectElement.getMethod('toString'),
        isLegacy: isLegacyLibrary,
      ),
      typeArgumentTypes: [],
      invokeType: 'String Function()',
      type: 'String',
    );
  }

  test_objectMethodOnFunction() async {
    await assertNoErrorsInCode(r'''
void f() {}

main() {
  f.toString();
}
''');

    var invocation = findNode.methodInvocation('toString();');
    assertMethodInvocation(
      invocation,
      typeProvider.objectType.getMethod('toString'),
      'String Function()',
    );
  }

  test_remainder_int_context_cascaded() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a..remainder(f()));
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_remainder_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.remainder(f()));
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_remainder_int_context_int_target_rewritten() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a().remainder(f()));
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_remainder_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
extension E on int {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 98, 19),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_remainder_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a.remainder(f());
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_remainder_int_double() async {
    await assertNoErrorsInCode('''
f(int a, double b) {
  a.remainder(b);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('remainder'),
        elementMatcher(numElement.getMethod('remainder'),
            isLegacy: isLegacyLibrary),
        'num Function(num)',
        expectedType:
            typeStringByNullability(nullable: 'double', legacy: 'num'));
  }

  test_remainder_int_int() async {
    await assertNoErrorsInCode('''
f(int a, int b) {
  a.remainder(b);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('remainder'),
        elementMatcher(numElement.getMethod('remainder'),
            isLegacy: isLegacyLibrary),
        'num Function(num)',
        expectedType: typeStringByNullability(nullable: 'int', legacy: 'num'));
  }

  test_remainder_int_int_target_rewritten() async {
    await assertNoErrorsInCode('''
f(int Function() a, int b) {
  a().remainder(b);
}
''');

    assertMethodInvocation(
        findNode.methodInvocation('remainder'),
        elementMatcher(numElement.getMethod('remainder'),
            isLegacy: isLegacyLibrary),
        'num Function(num)',
        expectedType: typeStringByNullability(nullable: 'int', legacy: 'num'));
  }

  test_remainder_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 19),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_remainder_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a.remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 16),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_syntheticName() async {
    // This code is invalid, and the constructor initializer has a method
    // invocation with a synthetic name. But we should still resolve the
    // invocation, and resolve all its arguments.
    await assertErrorsInCode(r'''
class A {
  A() : B(1 + 2, [0]);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 18, 1),
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 13),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation(');'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );

    assertType(findNode.binary('1 + 2'), 'int');
    assertType(findNode.listLiteral('[0]'), 'List<int>');
  }

  test_typeArgumentTypes_generic_inferred() async {
    await assertErrorsInCode(r'''
U foo<T, U>(T a) => throw Error();

main() {
  bool v = foo(0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
    ]);

    var invocation = findNode.methodInvocation('foo(0)');
    assertTypeArgumentTypes(invocation, ['int', 'bool']);
  }

  test_typeArgumentTypes_generic_instantiateToBounds() async {
    await assertNoErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo();
}
''');

    var invocation = findNode.methodInvocation('foo();');
    assertTypeArgumentTypes(invocation, ['num']);
  }

  test_typeArgumentTypes_generic_typeArguments_notBounds() async {
    await assertErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 45, 4),
    ]);
    var invocation = findNode.methodInvocation('foo<bool>();');
    assertTypeArgumentTypes(invocation, ['bool']);
  }

  test_typeArgumentTypes_generic_typeArguments_wrongNumber() async {
    await assertErrorsInCode(r'''
void foo<T>() {}

main() {
  foo<int, double>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 32, 13),
    ]);
    var invocation = findNode.methodInvocation('foo<int, double>();');
    assertTypeArgumentTypes(invocation, ['dynamic']);
  }

  test_typeArgumentTypes_notGeneric() async {
    await assertNoErrorsInCode(r'''
void foo(int a) {}

main() {
  foo(0);
}
''');

    var invocation = findNode.methodInvocation('foo(0)');
    assertTypeArgumentTypes(invocation, []);
  }

  void _assertInvalidInvocation(String search, Element? expectedElement,
      {String? expectedMethodNameType,
      String? expectedNameType,
      List<String> expectedTypeArguments = const <String>[],
      bool dynamicNameType = false}) {
    var invocation = findNode.methodInvocation(search);
    if (dynamicNameType) {
      assertTypeDynamic(invocation.methodName);
    }
    // TODO(scheglov) I think `invokeType` should be `null`.
    assertMethodInvocation(
      invocation,
      expectedElement,
      'dynamic',
      expectedMethodNameType: expectedMethodNameType,
      expectedNameType: expectedNameType,
      expectedType: 'dynamic',
      expectedTypeArguments: expectedTypeArguments,
    );
    assertTypeArgumentTypes(invocation, expectedTypeArguments);
  }

  void _assertUnresolvedMethodInvocation(
    String search, {
    List<String> expectedTypeArguments = const <String>[],
  }) {
    // TODO(scheglov) clean up
    _assertInvalidInvocation(
      search,
      null,
      expectedTypeArguments: expectedTypeArguments,
    );
//    var invocation = findNode.methodInvocation(search);
//    assertTypeDynamic(invocation.methodName);
//    // TODO(scheglov) I think `invokeType` should be `null`.
//    assertMethodInvocation(
//      invocation,
//      null,
//      'dynamic',
//      expectedType: 'dynamic',
//    );
  }
}

@reflectiveTest
class MethodInvocationResolutionWithNullSafetyTest
    extends PubPackageResolutionTest with MethodInvocationResolutionTestCases {
  test_hasReceiver_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 22, 8),
    ]);

    var import = findElement.importFind('package:test/a.dart');

    var invocation = findNode.methodInvocation('loadLibrary()');
    assertImportPrefix(invocation.target, import.prefix);

    assertMethodInvocation(
      invocation,
      import.importedLibrary.loadLibraryFunction,
      'Future<dynamic>* Function()*',
    );
  }

  test_hasReceiver_interfaceQ_Function_call_checked() async {
    await assertNoErrorsInCode(r'''
void f(Function? foo) {
  foo?.call();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('foo?.call()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceQ_Function_call_unchecked() async {
    await assertErrorsInCode(r'''
void f(Function? foo) {
  foo.call();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          30, 4),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('foo.call()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceQ_nullShorting() async {
    await assertNoErrorsInCode(r'''
class C {
  C foo() => throw 0;
  C bar() => throw 0;
}

void testShort(C? c) {
  c?.foo().bar();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('c?.foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'C Function()',
      type: 'C',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('bar();'),
      element: findElement.method('bar'),
      typeArgumentTypes: [],
      invokeType: 'C Function()',
      type: 'C?',
    );
  }

  test_hasReceiver_interfaceQ_nullShorting_getter() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  void Function(C) get foo;
}

void f(C? c) {
  c?.foo(c); // 1
}
''');

    var invocation = findNode.functionExpressionInvocation('foo(c);');
    assertElementNull(invocation);
    assertInvokeType(invocation, 'void Function(C)');
    assertType(invocation, 'void');

    var foo = invocation.function as PropertyAccess;
    assertType(foo, 'void Function(C)');
    assertElement(foo.propertyName, findElement.getter('foo'));
    assertType(foo.propertyName, 'void Function(C)');

    assertSimpleIdentifier(
      findNode.simple('c); // 1'),
      element: findElement.parameter('c'),
      type: 'C',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          48, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'A'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined_extension() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          86, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'A'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'E'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ2() async {
    await assertNoErrorsInCode(r'''
extension E<T> on T? {
  T foo() => throw 0;
}

void f(int? a) {
  a.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: elementMatcher(
        findElement.method('foo', of: 'E'),
        substitution: {'T': 'int'},
      ),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );
  }

  test_hasReceiver_interfaceTypeQ_notDefined() async {
    await assertErrorsInCode(r'''
class A {}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          31, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extension() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          69, 3),
    ]);

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'dynamic',
      type: 'dynamic',
    );
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo', of: 'E'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_hasReceiver_typeAlias_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

typedef B = A;

void f() {
  B.foo(0);
}
''');

    assertMethodInvocation(
      findNode.methodInvocation('foo(0)'),
      findElement.method('foo'),
      'void Function(int)',
    );

    assertTypeAliasRef(
      findNode.simple('B.foo'),
      findElement.typeAlias('B'),
    );
  }

  test_hasReceiver_typeAlias_staticMethod_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  static void foo(int _) {}
}

typedef B<T> = A<T>;

void f() {
  B.foo(0);
}
''');

    assertMethodInvocation(
      findNode.methodInvocation('foo(0)'),
      findElement.method('foo'),
      'void Function(int)',
    );

    assertTypeAliasRef(
      findNode.simple('B.foo'),
      findElement.typeAlias('B'),
    );
  }

  test_hasReceiver_typeParameter_promotedToNonNullable() async {
    await assertNoErrorsInCode('''
void f<T>(T? t) {
  if (t is int) {
    t.abs();
  }
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('t.abs()'),
      element: intElement.getMethod('abs'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );
  }

  test_hasReceiver_typeParameter_promotedToOtherTypeParameter() async {
    await assertNoErrorsInCode('''
abstract class A {}

abstract class B extends A {
  void foo();
}

void f<T extends A, U extends B>(T a) {
  if (a is U) {
    a.foo();
  }
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('a.foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'void Function()',
      type: 'void',
    );
  }

  test_namedArgument_anywhere() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}
class D {}

void foo(A a, B b, {C? c, D? d}) {}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  foo(g1(), c: g3(), g2(), d: g4());
}
''');

    assertMethodInvocation(
      findNode.methodInvocation('foo(g'),
      findElement.topFunction('foo'),
      'void Function(A, B, {C? c, D? d})',
    );

    var g1 = findNode.methodInvocation('g1()');
    assertType(g1, 'A');
    assertParameterElement(g1, findElement.parameter('a'));

    var g2 = findNode.methodInvocation('g2()');
    assertType(g2, 'B');
    assertParameterElement(g2, findElement.parameter('b'));

    var named_g3 = findNode.namedExpression('c: g3()');
    assertType(named_g3.expression, 'C?');
    assertParameterElement(named_g3, findElement.parameter('c'));
    assertNamedParameterRef('c:', 'c');

    var named_g4 = findNode.namedExpression('d: g4()');
    assertType(named_g4.expression, 'D?');
    assertParameterElement(named_g4, findElement.parameter('d'));
    assertNamedParameterRef('d:', 'd');
  }

  test_nullShorting_cascade_firstMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo()..bar();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('..foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('..bar()'),
      element: findElement.method('bar'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_nullShorting_cascade_firstPropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo..bar();
}
''');

    assertPropertyAccess2(
      findNode.propertyAccess('..foo'),
      element: findElement.getter('foo'),
      type: 'int',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('..bar()'),
      element: findElement.method('bar'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_nullShorting_cascade_nullAwareInside() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() => 0;
}

main() {
  A a = A()..foo()?.abs();
  a;
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('..foo()'),
      element: findElement.method('foo'),
      typeArgumentTypes: [],
      invokeType: 'int? Function()',
      type: 'int?',
    );

    assertMethodInvocation2(
      findNode.methodInvocation('.abs()'),
      element: intElement.getMethod('abs'),
      typeArgumentTypes: [],
      invokeType: 'int Function()',
      type: 'int',
    );

    assertType(findNode.cascade('A()'), 'A');
  }

  test_typeArgumentTypes_generic_inferred_leftTop_dynamic() async {
    await assertNoErrorsInCode('''
void foo<T extends Object>(T? value) {}

void f(dynamic o) {
  foo(o);
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('foo(o)'),
      ['Object'],
    );
  }

  test_typeArgumentTypes_generic_inferred_leftTop_void() async {
    await assertNoErrorsInCode('''
void foo<T extends Object>(List<T?> value) {}

void f(List<void> o) {
  foo(o);
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('foo(o)'),
      ['Object'],
    );
  }
}
