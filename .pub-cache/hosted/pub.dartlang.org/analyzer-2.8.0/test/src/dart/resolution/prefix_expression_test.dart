// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixExpressionResolutionTest);
    defineReflectiveTests(PrefixExpressionResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class PrefixExpressionResolutionTest extends PubPackageResolutionTest
    with PrefixExpressionResolutionTestCases {
  test_bang_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  bool get foo => true;
}

void f(A? a) {
  !a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION,
          55, 6),
    ]);

    assertPrefixExpression(
      findNode.prefix('!a'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: boolElement.getMethod('!'),
      type: 'bool',
    );
  }

  test_minus_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  -a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          50, 1),
    ]);

    assertPrefixExpression(
      findNode.prefix('-a'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: intElement.getMethod('unary-'),
      type: 'int',
    );
  }

  test_plusPlus_depromote() async {
    await assertNoErrorsInCode(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    ++x;
  }
}
''');

    assertPrefixExpression(
      findNode.prefix('++x'),
      readElement: findElement.parameter('x'),
      readType: 'A',
      writeElement: findElement.parameter('x'),
      writeType: 'Object',
      element: findElement.method('+'),
      type: 'Object',
    );

    if (hasAssignmentLeftResolution) {
      assertType(findNode.simple('x;'), 'A');
    }
  }

  test_plusPlus_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  ++a?.foo;
}
''');

    assertPrefixExpression(
      findNode.prefix('++a'),
      readElement: findElement.getter('foo'),
      readType: 'int',
      writeElement: findElement.setter('foo'),
      writeType: 'int',
      element: numElement.getMethod('+'),
      type: 'int?',
    );
  }

  test_tilde_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  ~a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          50, 1),
    ]);

    assertPrefixExpression(
      findNode.prefix('~a'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: intElement.getMethod('~'),
      type: 'int',
    );
  }
}

mixin PrefixExpressionResolutionTestCases on PubPackageResolutionTest {
  test_bang_bool_context() async {
    await assertNoErrorsInCode(r'''
T f<T>() {
  throw 42;
}

main() {
  !f();
}
''');

    assertMethodInvocation2(
      findNode.methodInvocation('f();'),
      element: findElement.topFunction('f'),
      typeArgumentTypes: ['bool'],
      invokeType: 'bool Function()',
      type: 'bool',
    );

    assertPrefixExpression(
      findNode.prefix('!f()'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: boolElement.getMethod('!'),
      type: 'bool',
    );
  }

  test_bang_bool_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  !x;
}
''');

    assertPrefixExpression(
      findNode.prefix('!x'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: boolElement.getMethod('!'),
      type: 'bool',
    );
  }

  test_bang_int_localVariable() async {
    await assertErrorsInCode(r'''
void f(int x) {
  !x;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 19, 1),
    ]);

    assertPrefixExpression(
      findNode.prefix('!x'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: null,
      type: 'bool',
    );
  }

  test_inc_indexExpression_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  ++a[0];
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_indexExpression_super() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    ++super[0];
  }
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_inc_indexExpression_this() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    ++this[0];
  }
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_minus_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  -x;
}
''');

    assertPrefixExpression(
      findNode.prefix('-x'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: elementMatcher(
        intElement.getMethod('unary-'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plusPlus_notLValue_extensionOverride() async {
    await assertErrorsInCode(r'''
class C {}

extension Ext on C {
  int operator +(int _) {
    return 0;
  }
}

void f(C c) {
  ++Ext(c);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 103, 1),
    ]);

    assertPrefixExpression(
      findNode.prefix('++Ext'),
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      element: findElement.method('+'),
      type: 'int',
    );
  }

  test_plusPlus_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  ++int;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 15, 3),
    ]);

    assertPrefixExpression(
      findNode.prefix('++int'),
      readElement: intElement,
      readType: 'dynamic',
      writeElement: intElement,
      writeType: 'dynamic',
      element: null,
      type: 'dynamic',
    );
  }

  test_plusPlus_prefixedIdentifier_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f(A a) {
  ++a.x;
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plusPlus_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
int x = 0;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  ++p.x;
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var prefix = findNode.prefix('++');
    assertPrefixExpression(
      prefix,
      readElement: importFind.topGet('x'),
      readType: 'int',
      writeElement: importFind.topSet('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var prefixed = prefix.operand as PrefixedIdentifier;
    assertImportPrefix(prefixed.prefix, importFind.prefix);
  }

  test_plusPlus_propertyAccess_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f() {
  ++A().x;
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plusPlus_propertyAccess_super() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++super.x;
  }
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.getter('x', of: 'A'),
      readType: 'int',
      writeElement: findElement.setter('x', of: 'A'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plusPlus_propertyAccess_this() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++this.x;
  }
}
''');

    assertPrefixExpression(
      findNode.prefix('++'),
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plusPlus_simpleIdentifier_parameter_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  ++x;
}
''');

    assertPrefixExpression(
      findNode.prefix('++x'),
      readElement: findElement.parameter('x'),
      readType: 'double',
      writeElement: findElement.parameter('x'),
      writeType: 'double',
      element: elementMatcher(
        doubleElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_plusPlus_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  ++x;
}
''');

    assertPrefixExpression(
      findNode.prefix('++x'),
      readElement: findElement.parameter('x'),
      readType: 'int',
      writeElement: findElement.parameter('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_plusPlus_simpleIdentifier_parameter_num() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  ++x;
}
''');

    assertPrefixExpression(
      findNode.prefix('++x'),
      readElement: findElement.parameter('x'),
      readType: 'num',
      writeElement: findElement.parameter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_plusPlus_simpleIdentifier_parameter_typeParameter() async {
    await assertErrorsInCode(
      r'''
void f<T extends num>(T x) {
  ++x;
}
''',
      expectedErrorsByNullability(nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 31, 3),
      ], legacy: []),
    );

    assertPrefixExpression(
      findNode.prefix('++x'),
      readElement: findElement.parameter('x'),
      readType: 'T',
      writeElement: findElement.parameter('x'),
      writeType: 'T',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num',
    );
  }

  test_plusPlus_simpleIdentifier_thisGetter_superSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  int get x => 0;
  void f() {
    ++x;
  }
}
''');

    var prefix = findNode.prefix('++x');
    assertPrefixExpression(
      prefix,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      prefix.operand,
    );
  }

  test_plusPlus_simpleIdentifier_thisGetter_thisSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
  void f() {
    ++x;
  }
}
''');

    var prefix = findNode.prefix('++x');
    assertPrefixExpression(
      prefix,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      prefix.operand,
    );
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

void f() {
  ++x;
}
''');

    var prefix = findNode.prefix('++x');
    assertPrefixExpression(
      prefix,
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      prefix.operand,
    );
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter_fromClass() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    ++x;
  }
}
''');

    var prefix = findNode.prefix('++x');
    assertPrefixExpression(
      prefix,
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      prefix.operand,
    );
  }

  /// Verify that we get all necessary types when building the dependencies
  /// graph during top-level inference.
  test_plusPlus_topLevelInference() async {
    await assertNoErrorsInCode(r'''
var x = 0;

class A {
  final y = ++x;
}
''');

    assertPrefixExpression(
      findNode.prefix('++x'),
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'int',
      element: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_tilde_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  ~x;
}
''');

    assertPrefixExpression(
      findNode.prefix('~x'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: null,
      element: elementMatcher(
        intElement.getMethod('~'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }
}

@reflectiveTest
class PrefixExpressionResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with PrefixExpressionResolutionTestCases, WithoutNullSafetyMixin {}
