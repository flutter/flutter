// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentDriverResolutionTest);
  });
}

@reflectiveTest
class AssignmentDriverResolutionTest extends PubPackageResolutionTest
    with AssignmentDriverResolutionTestCases {}

mixin AssignmentDriverResolutionTestCases on PubPackageResolutionTest {
  test_compound_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a += f();
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      [typeStringByNullability(nullable: 'int', legacy: 'num')],
    );
  }

  test_compound_plus_int_context_int_complex() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(List<int> a) {
  a[0] += f();
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      [typeStringByNullability(nullable: 'int', legacy: 'num')],
    );
  }

  test_compound_plus_int_context_int_promoted() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a) {
  if (a is int) {
    a += f();
  }
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      [typeStringByNullability(nullable: 'int', legacy: 'num')],
    );
  }

  test_compound_plus_int_context_int_promoted_with_subsequent_demotion() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a, bool b) {
  if (a is int) {
    a += b ? f() : 1.0;
    print(a);
  }
}
''');

    assertTypeArgumentTypes(
      findNode.methodInvocation('f()'),
      [typeStringByNullability(nullable: 'int', legacy: 'num')],
    );

    assertType(findNode.simple('a);').staticType, 'num');
  }

  test_indexExpression_cascade_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a..[0] += 2;
}
''');

    assertAssignment(
      findNode.assignment('[0] += 2'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_indexExpression_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2;
}
''');

    assertAssignment(
      findNode.assignment('[0] += 2'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_indexExpression_instance_compound_double_num() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2.0;
}
''');

    assertAssignment(
      findNode.assignment('[0] += 2.0'),
      readElement: findElement.method('[]'),
      readType: 'num',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
  }

  test_indexExpression_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? operator[](int? index) => 0;
  operator[]=(int? index, num? _) {}
}

void f(A a) {
  a[0] ??= 2;
}
''');

    assertAssignment(
      findNode.assignment('[0] ??= 2'),
      readElement: findElement.method('[]'),
      readType: 'int?',
      writeElement: findElement.method('[]='),
      writeType: 'num?',
      operatorElement: null,
      type: 'int',
    );
  }

  test_indexExpression_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] = 2;
}
''');

    assertAssignment(
      findNode.assignment('[0] = 2'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );
  }

  test_indexExpression_super_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    super[0] += 2;
  }
}
''');

    assertAssignment(
      findNode.assignment('[0] += 2'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_indexExpression_this_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0] += 2;
  }
}
''');

    assertAssignment(
      findNode.assignment('[0] += 2'),
      readElement: findElement.method('[]'),
      readType: 'int',
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );
  }

  test_indexExpression_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 20, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('a['),
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      findNode.simple('b]'),
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_indexExpression_unresolved2_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 26, 3),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 27, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('a['),
      element: findElement.parameter('a'),
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('b]'),
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_indexExpression_unresolved3_simple() async {
    await assertErrorsInCode(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a, int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 73, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]='),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('a['),
      element: findElement.parameter('a'),
      type: 'A',
    );

    assertSimpleIdentifier(
      findNode.simple('b]'),
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_notLValue_binaryExpression_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  a + b += c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 5),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 5),
    ]);

    var assignment = findNode.assignment('= c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertElement(findNode.simple('a +'), findElement.parameter('a'));
    assertElement(findNode.simple('b +'), findElement.parameter('b'));
    assertElement(findNode.simple('c;'), findElement.parameter('c'));
  }

  test_notLValue_parenthesized_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  (a + b) += c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 7),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 7),
    ]);

    var assignment = findNode.assignment('= c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );
  }

  test_notLValue_parenthesized_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  (a + b) = c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 7),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 7),
    ]);

    var assignment = findNode.assignment('= c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'double',
    );

    assertType(assignment.leftHandSide, 'int');

    assertSimpleIdentifier(
      findNode.simple('a + b'),
      element: findElement.parameter('a'),
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('b)'),
      element: findElement.parameter('b'),
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('c;'),
      element: findElement.parameter('c'),
      type: 'double',
    );
  }

  test_notLValue_postfixIncrement_compound() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ += y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    assertAssignment(
      findNode.assignment('= y'),
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      findNode.simple('y;'),
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_notLValue_postfixIncrement_compound_ifNull() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ ??= y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    assertAssignment(
      findNode.assignment('= y'),
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      findNode.simple('y;'),
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_notLValue_postfixIncrement_simple() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ = y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    assertAssignment(
      findNode.assignment('= y'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('y;'),
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_notLValue_prefixIncrement_compound() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x += y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    assertAssignment(
      findNode.assignment('= y'),
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      findNode.simple('y;'),
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_notLValue_prefixIncrement_compound_ifNull() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x ??= y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    assertAssignment(
      findNode.assignment('= y'),
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      findNode.simple('y;'),
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_notLValue_prefixIncrement_simple() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x = y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    assertAssignment(
      findNode.assignment('= y'),
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('y;'),
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_notLValue_typeLiteral_class_ambiguous_simple() async {
    newFile('$testPackageLibPath/a.dart', content: 'class C {}');
    newFile('$testPackageLibPath/b.dart', content: 'class C {}');
    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';
void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 47, 1),
    ]);

    var matcherC = multiplyDefinedElementMatcher([
      findElement.importFind('package:test/a.dart').class_('C'),
      findElement.importFind('package:test/b.dart').class_('C'),
    ]);

    var assignment = findNode.assignment('C = 0');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: matcherC,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_notLValue_typeLiteral_class_simple() async {
    await assertErrorsInCode('''
class C {}

void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 25, 1),
    ]);

    var assignment = findNode.assignment('C = 0');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.class_('C'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_nullAware_context() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int$question a) {
  a ??= f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['int$question']);
  }

  test_prefixedIdentifier_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  a.x ??= 2;
}
''');

    var assignment = findNode.assignment('x ??= 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int?',
      writeElement: findElement.setter('x'),
      writeType: 'num?',
      operatorElement: null,
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  a.x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_instanceGetter_simple() async {
    await assertErrorsInCode(r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 49, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.getter('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_static_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  static set x(num _) {}
}

void f() {
  A.x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_staticGetter_simple() async {
    await assertErrorsInCode(r'''
class A {
  static int get x => 0;
}

void f() {
  A.x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.getter('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_topLevel_compound() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
int get x => 0;
set x(num _) {}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.x += 2;
}
''');

    var importFind = findElement.importFind('package:test/a.dart');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: importFind.topGet('x'),
      readType: 'int',
      writeElement: importFind.topSet('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertImportPrefix(prefixed.prefix, importFind.prefix);

    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_typeAlias_static_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}

typedef B = A;

void f() {
  B.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'int',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var prefixed = assignment.leftHandSide as PrefixedIdentifier;
    assertSimpleIdentifierAssignmentTarget(
      prefixed.identifier,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_prefixedIdentifier_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  a.b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('a.b = c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('a.'),
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifierAssignmentTarget(
      findNode.simple('b ='),
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_prefixedIdentifier_unresolved2_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  a.b += c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 27, 1),
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 1),
    ]);

    var assignment = findNode.assignment('a.b += c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifier(
      findNode.simple('a.'),
      element: findElement.parameter('a'),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      findNode.simple('b +='),
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_propertyAccess_cascade_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a..x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    assertSimpleIdentifierAssignmentTarget(
      propertyAccess.propertyName,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_forwardingStub() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}
abstract class I<T> {
  T x = throw 0;
}
class B extends A implements I<int> {}
main() {
  new B().x = 1;
}
''');

    var assignment = findNode.assignment('x = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x', of: 'A'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  (a).x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    assertSimpleIdentifierAssignmentTarget(
      propertyAccess.propertyName,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_instance_fromMixins_compound() async {
    await assertNoErrorsInCode('''
class M1 {
  int get x => 0;
  set x(num _) {}
}

class M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
}

void f(C c) {
  (c).x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x', of: 'M2'),
      readType: 'int',
      writeElement: findElement.setter('x', of: 'M2'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  (a).x ??= 2;
}
''');

    var assignment = findNode.assignment('x ??= 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int?',
      writeElement: findElement.setter('x'),
      writeType: 'num?',
      operatorElement: null,
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    assertSimpleIdentifierAssignmentTarget(
      propertyAccess.propertyName,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  (a).x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    assertSimpleIdentifierAssignmentTarget(
      propertyAccess.propertyName,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_super_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    super.x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x', of: 'A'),
      readType: 'int',
      writeElement: findElement.setter('x', of: 'A'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    assertSuperExpression(propertyAccess.target);
    assertSimpleIdentifierAssignmentTarget(
      propertyAccess.propertyName,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_this_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}

  void f() {
    this.x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    var propertyAccess = assignment.leftHandSide as PropertyAccess;
    assertSimpleIdentifierAssignmentTarget(
      propertyAccess.propertyName,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_propertyAccess_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  (a).b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 19, 1),
    ]);

    var assignment = findNode.assignment('(a).b = c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('a)'),
      element: null,
      type: 'dynamic',
    );

    assertSimpleIdentifierAssignmentTarget(
      findNode.simple('b ='),
    );

    assertSimpleIdentifier(
      findNode.simple('c;'),
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_propertyAccess_unresolved2_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  (a).b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 29, 1),
    ]);

    var assignment = findNode.assignment('(a).b = c');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifier(
      findNode.simple('a)'),
      element: findElement.parameter('a'),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      findNode.simple('b ='),
    );

    assertSimpleIdentifier(
      findNode.simple('c;'),
      element: findElement.parameter('c'),
      type: 'int',
    );
  }

  test_simpleIdentifier_fieldInstance_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_fieldStatic_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  static num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    await assertErrorsInCode('''
class C {
  num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 46, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.getter('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    await assertErrorsInCode('''
class C {
  static num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.getter('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    await assertErrorsInCode('''
int get x => 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 30, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.topGet('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_importPrefix_hasSuperSetter_simple() async {
    await assertErrorsInCode('''
// ignore:unused_import
import 'dart:math' as x;

class A {
  var x;
}

class B extends A {
  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 109, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.prefix('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );
  }

  test_simpleIdentifier_importPrefix_simple() async {
    await assertErrorsInCode('''
import 'dart:math' as x;

main() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 37, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.prefix('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariable_compound() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x += 3;
}
''');

    var assignment = findNode.assignment('x += 3');
    assertAssignment(
      assignment,
      readElement: findElement.localVar('x'),
      readType: 'num',
      writeElement: findElement.localVar('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'num', // num + int = num
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariable_simple() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.localVar('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.localVar('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.localVar('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_parameter_compound_ifNull() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertNoErrorsInCode('''
void f(num$question x) {
  x ??= 0;
}
''');

    var assignment = findNode.assignment('x ??=');
    assertAssignment(
      assignment,
      readElement: findElement.parameter('x'),
      readType: 'num$question',
      writeElement: findElement.parameter('x'),
      writeType: 'num$question',
      operatorElement: null,
      type: 'num',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_parameter_compound_ifNull2() async {
    var question = typeToStringWithNullability ? '?' : '';
    var errorOffset = typeToStringWithNullability ? 77 : 76;
    await assertErrorsInCode('''
class A {}
class B extends A {}
class C extends A {}

void f(B$question x) {
  x ??= C();
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, errorOffset, 3),
    ]);

    var assignment = findNode.assignment('x ??=');
    assertAssignment(
      assignment,
      readElement: findElement.parameter('x'),
      readType: 'B$question',
      writeElement: findElement.parameter('x'),
      writeType: 'B$question',
      operatorElement: null,
      type: 'A',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'C');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    var question = typeToStringWithNullability ? '?' : '';
    var code = '''
void f(double$question a, int b) {
  a ??= b;
}
''';
    await assertErrorsInCode(code, [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, code.indexOf('b;'), 1),
    ]);

    var assignment = findNode.assignment('a ??=');
    assertAssignment(
      assignment,
      readElement: findElement.parameter('a'),
      readType: 'double$question',
      writeElement: findElement.parameter('a'),
      writeType: 'double$question',
      operatorElement: null,
      type: 'num',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('b'),
      type: 'int',
    );
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x += 1.2;
  x -= 1.2;
  x *= 1.2;
  x %= 1.2;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 47, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 59, 3),
    ]);
    assertType(findNode.assignment('+='), 'double');
    assertType(findNode.assignment('-='), 'double');
    assertType(findNode.assignment('*='), 'double');
    assertType(findNode.assignment('%='), 'double');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x += 1;
  x -= 1;
  x *= 1;
  x ~/= 1;
  x %= 1;
}
''');
    assertType(findNode.assignment('+='), 'int');
    assertType(findNode.assignment('-='), 'int');
    assertType(findNode.assignment('*='), 'int');
    assertType(findNode.assignment('~/='), 'int');
    assertType(findNode.assignment('%='), 'int');
  }

  test_simpleIdentifier_parameter_simple() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.parameter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_parameter_simple_context() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x is double) {
    x = 1;
  }
}
''');

    var expectedType = typeStringByNullability(
      nullable: 'double',
      legacy: 'int',
    );

    var assignment = findNode.assignment('x = 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.parameter('x'),
      writeType: 'Object',
      operatorElement: null,
      type: expectedType,
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, expectedType);
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 22, 4),
    ]);

    var assignment = findNode.assignment('x = true');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.parameter('x'),
      writeType: 'int',
      operatorElement: null,
      type: 'bool',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'bool');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    await assertErrorsInCode('''
void f(final int x) {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 24, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.parameter('x'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_staticGetter_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

class B extends A {
  static int get x => 1;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 94, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.getter('x', of: 'B'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );
  }

  test_simpleIdentifier_staticMethod_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 90, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.method('x', of: 'B'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );
  }

  test_simpleIdentifier_superSetter_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_synthetic_simple() async {
    await assertErrorsInCode('''
void f(int y) {
  = y;
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('= y');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('y'),
      type: 'int',
    );
  }

  test_simpleIdentifier_thisGetter_superGetter_simple() async {
    await assertNoErrorsInCode('''
class A {
  int x = 0;
}

class B extends A {
  int get x => 1;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.setter('x', of: 'A'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_thisGetter_thisSetter_compound() async {
    await assertNoErrorsInCode('''
class C {
  int get x => 0;
  set x(num _) {}

  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int',
      writeElement: findElement.setter('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_thisGetter_thisSetter_fromMixins_compound() async {
    await assertNoErrorsInCode('''
class M1 {
  int get x => 0;
  set x(num _) {}
}

class M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x', of: 'M2'),
      readType: 'int',
      writeElement: findElement.setter('x', of: 'M2'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_thisGetter_thisSetter_ifNull() async {
    await assertNoErrorsInCode('''
class C {
  int? get x => 0;
  set x(num? _) {}

  void f() {
    x ??= 2;
  }
}
''');

    var assignment = findNode.assignment('x ??= 2');
    assertAssignment(
      assignment,
      readElement: findElement.getter('x'),
      readType: 'int?',
      writeElement: findElement.setter('x'),
      writeType: 'num?',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_topGetter_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

int get x => 1;

class B extends A {

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 86, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.topGet('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_topGetter_topSetter_compound() async {
    await assertNoErrorsInCode('''
int get x => 0;
set x(num _) {}

void f() {
  x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_topGetter_topSetter_compound_ifNull2() async {
    var question = typeToStringWithNullability ? '?' : '';
    await assertErrorsInCode('''
void f() {
  x ??= C();
}

class A {}
class B extends A {}
class C extends A {}

B$question get x => B();
set x(B$question _) {}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 3),
    ]);

    var assignment = findNode.assignment('x ??=');
    assertAssignment(
      assignment,
      readElement: findElement.topGet('x'),
      readType: 'B$question',
      writeElement: findElement.topSet('x'),
      writeType: 'B$question',
      operatorElement: null,
      type: 'A',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'C');
  }

  test_simpleIdentifier_topGetter_topSetter_fromClass_compound() async {
    await assertNoErrorsInCode('''
int get x => 0;
set x(num _) {}

class A {
  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');
    assertAssignment(
      assignment,
      readElement: findElement.topGet('x'),
      readType: 'int',
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      operatorElement: elementMatcher(
        numElement.getMethod('+'),
        isLegacy: isLegacyLibrary,
      ),
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_topLevelVariable_simple() async {
    await assertNoErrorsInCode(r'''
num x = 0;

void f() {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.topSet('x'),
      writeType: 'num',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
int x = 0;

void f() {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 4),
    ]);

    var assignment = findNode.assignment('x = true');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.topSet('x'),
      writeType: 'int',
      operatorElement: null,
      type: 'bool',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'bool');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    await assertErrorsInCode(r'''
final num x = 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 31, 1),
    ]);

    var assignment = findNode.assignment('x = 2');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: findElement.topGet('x'),
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_typeLiteral_compound() async {
    await assertErrorsInCode(r'''
void f() {
  int += 3;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var assignment = findNode.assignment('int += 3');
    assertAssignment(
      assignment,
      readElement: intElement,
      readType: 'dynamic',
      writeElement: intElement,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_typeLiteral_simple() async {
    await assertErrorsInCode(r'''
void f() {
  int = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var assignment = findNode.assignment('int = 0');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: intElement,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_unresolved_compound() async {
    await assertErrorsInCode(r'''
void f() {
  x += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    var assignment = findNode.assignment('x += 1');
    assertAssignment(
      assignment,
      readElement: null,
      readType: 'dynamic',
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'dynamic',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertType(assignment.rightHandSide, 'int');
  }

  test_simpleIdentifier_unresolved_simple() async {
    await assertErrorsInCode(r'''
void f(int a) {
  x = a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('x = a');
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: null,
      writeType: 'dynamic',
      operatorElement: null,
      type: 'int',
    );

    assertSimpleIdentifierAssignmentTarget(
      assignment.leftHandSide,
    );

    assertSimpleIdentifier(
      assignment.rightHandSide,
      element: findElement.parameter('a'),
      type: 'int',
    );
  }
}
