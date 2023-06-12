// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.test.constant_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantEvaluatorTest);
  });
}

@reflectiveTest
class ConstantEvaluatorTest extends PubPackageResolutionTest {
  void assertTypeArguments(DartObject value, List<String>? typeArgumentNames) {
    var typeArguments = (value as DartObjectImpl).typeArguments;
    if (typeArguments == null) {
      expect(typeArguments, typeArgumentNames);
      return;
    }
    expect(
      typeArguments.map((arg) => arg.getDisplayString(withNullability: true)),
      equals(typeArgumentNames),
    );
  }

  test_bitAnd_int_int() async {
    await _assertValueInt(74 & 42, "74 & 42");
  }

  test_bitNot() async {
    await _assertValueInt(~42, "~42");
  }

  test_bitOr_int_int() async {
    await _assertValueInt(74 | 42, "74 | 42");
  }

  test_bitXor_int_int() async {
    await _assertValueInt(74 ^ 42, "74 ^ 42");
  }

  test_conditionalExpression_unknownCondition_dynamic() async {
    await assertErrorsInCode('''
const bool kIsWeb = identical(0, 0.0);
const x = kIsWeb ? a : b;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 58,
          1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 58, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 62, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 62,
          1),
    ]);

    var x_result = findElement.topVar('x').evaluationResult;
    assertDartObjectText(x_result.value, r'''
dynamic <unknown>
''');
  }

  test_constructorInvocation_fieldInitializer() async {
    var result = await _getExpressionValue("const C(2)", context: '''
class C {
  final int x;
  const C(this.x);
}
''');
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C');
    DartObject x = value.getField('x')!;
    assertType(x.type, 'int');
    expect(x.toIntValue(), 2);
  }

  test_constructorInvocation_noArgs() async {
    var result = await _getExpressionValue(
      "const C()",
      context: 'class C {const C();}',
    );
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C');
  }

  test_constructorInvocation_noConstConstructor() async {
    var result = await _getExpressionValue(
      "const C()",
      context: 'class C {}',
    );
    expect(result.isValid, isFalse);
    var value = result.value;
    expect(value, isNull);
  }

  test_constructorInvocation_simpleArgs() async {
    var result = await _getExpressionValue("const C(1)", context: '''
class C {
  const C(int x);
}
''');
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C');
  }

  test_constructorReference_generic_named() async {
    var result = await _getExpressionValue("C<int>.foo", context: '''
class C<T> {
  C.foo();
}
''');
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C<int> Function()');
  }

  test_constructorReference_generic_unnamed() async {
    var result = await _getExpressionValue("C<int>.new", context: '''
class C<T> {
  C.new();
}
''');
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C<int> Function()');
  }

  test_constructorReference_nonGeneric_named() async {
    var result = await _getExpressionValue("C.foo", context: '''
class C {
  const C.foo();
}
''');
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C Function()');
  }

  test_constructorReference_nonGeneric_unnamed() async {
    var result = await _getExpressionValue("C.new", context: '''
class C {
  const C();
}
''');
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, 'C Function()');
  }

  test_divide_double_double() async {
    await _assertValueDouble(3.2 / 2.3, "3.2 / 2.3");
  }

  test_divide_double_double_byZero() async {
    var result = await _getExpressionValue("3.2 / 0.0");
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, "double");
    expect(value.toDoubleValue()!.isInfinite, isTrue);
  }

  test_divide_int_int() async {
    await _assertValueDouble(1.5, "3 / 2");
  }

  test_divide_int_int_byZero() async {
    var result = await _getExpressionValue("3 / 0");
    expect(result.isValid, isTrue);
  }

  test_equal_boolean_boolean() async {
    await _assertValueBool(false, "true == false");
  }

  test_equal_int_int() async {
    await _assertValueBool(false, "2 == 3");
  }

  test_equal_invalidLeft() async {
    var result = await _getExpressionValue("a == 3");
    expect(result.isValid, isFalse);
  }

  test_equal_invalidRight() async {
    var result = await _getExpressionValue("2 == a");
    expect(result.isValid, isFalse);
  }

  test_equal_string_string() async {
    await _assertValueBool(false, "'a' == 'b'");
  }

  test_greaterThan_int_int() async {
    await _assertValueBool(false, "2 > 3");
  }

  test_greaterThanOrEqual_int_int() async {
    await _assertValueBool(false, "2 >= 3");
  }

  @failingTest
  test_identifier_class() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_identifier_function() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_identifier_static() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_identifier_staticMethod() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_identifier_topLevel() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_identifier_typeParameter() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  test_lessThan_int_int() async {
    await _assertValueBool(true, "2 < 3");
  }

  test_lessThanOrEqual_int_int() async {
    await _assertValueBool(true, "2 <= 3");
  }

  test_literal_boolean_false() async {
    await _assertValueBool(false, "false");
  }

  test_literal_boolean_true() async {
    await _assertValueBool(true, "true");
  }

  test_literal_list() async {
    var result = await _getExpressionValue("const ['a', 'b', 'c']");
    expect(result.isValid, isTrue);
  }

  test_literal_list_explicitType() async {
    var result = await _getExpressionValue("const <String>['a', 'b', 'c']");
    expect(result.isValid, isTrue);
  }

  test_literal_list_explicitType_functionType() async {
    var result = await _getExpressionValue("const <void Function()>[]");
    expect(result.isValid, isTrue);
  }

  test_literal_list_forElement() async {
    var result = await _getExpressionValue('''
const [for (var i = 0; i < 4; i++) i]
''');
    expect(result.isValid, isFalse);
    expect(result.errors, isNotEmpty);
  }

  test_literal_map() async {
    var result = await _getExpressionValue(
      "const {'a' : 'm', 'b' : 'n', 'c' : 'o'}",
    );
    expect(result.isValid, isTrue);
    var map = result.value!.toMapValue()!;
    expect(map.keys.map((k) => k!.toStringValue()), ['a', 'b', 'c']);
  }

  test_literal_null() async {
    var result = await _getExpressionValue("null");
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    expect(value.isNull, isTrue);
  }

  test_literal_number_double() async {
    await _assertValueDouble(3.45, "3.45");
  }

  test_literal_number_integer() async {
    await _assertValueInt(42, "42");
  }

  test_literal_string_adjacent() async {
    await _assertValueString("abcdef", "'abc' 'def'");
  }

  test_literal_string_interpolation_invalid() async {
    var result = await _getExpressionValue("'a\${f()}c'");
    expect(result.isValid, isFalse);
  }

  test_literal_string_interpolation_valid() async {
    await _assertValueString("a3c", "'a\${3}c'");
  }

  test_literal_string_simple() async {
    await _assertValueString("abc", "'abc'");
  }

  test_logicalAnd() async {
    await _assertValueBool(false, "true && false");
  }

  test_logicalNot() async {
    await _assertValueBool(false, "!true");
  }

  test_logicalOr() async {
    await _assertValueBool(true, "true || false");
  }

  test_minus_double_double() async {
    await _assertValueDouble(3.2 - 2.3, "3.2 - 2.3");
  }

  test_minus_int_int() async {
    await _assertValueInt(1, "3 - 2");
  }

  test_negated_boolean() async {
    var result = await _getExpressionValue("-true");
    expect(result.isValid, isFalse);
  }

  test_negated_double() async {
    await _assertValueDouble(-42.3, "-42.3");
  }

  test_negated_integer() async {
    await _assertValueInt(-42, "-42");
  }

  test_notEqual_boolean_boolean() async {
    await _assertValueBool(true, "true != false");
  }

  test_notEqual_int_int() async {
    await _assertValueBool(true, "2 != 3");
  }

  test_notEqual_invalidLeft() async {
    var result = await _getExpressionValue("a != 3");
    expect(result.isValid, isFalse);
  }

  test_notEqual_invalidRight() async {
    var result = await _getExpressionValue("2 != a");
    expect(result.isValid, isFalse);
  }

  test_notEqual_string_string() async {
    await _assertValueBool(true, "'a' != 'b'");
  }

  test_object_enum() async {
    await resolveTestCode('''
enum E { v1, v2 }
const x1 = E.v1;
const x2 = E.v2;
''');

    _assertTopVarConstValue('x1', r'''
E
  _name: String v1
  index: int 0
''');

    _assertTopVarConstValue('x2', r'''
E
  _name: String v2
  index: int 1
''');
  }

  /// Enum constants can reference other constants.
  test_object_enum_enhanced_constants() async {
    await assertNoErrorsInCode('''
enum E {
  v1(42), v2(v1);
  final Object? a;
  const E([this.a]);
}
''');

    assertDartObjectText(findElement.field('v2').evaluationResult.value, r'''
E
  _name: String v2
  a: E
    _name: String v1
    a: int 42
    index: int 0
  index: int 1
''');
  }

  test_object_enum_enhanced_named() async {
    await resolveTestCode('''
enum E<T> {
  v1<double>.named(10),
  v2.named(20);
  final T f;
  const E.named(this.f);
}

const x1 = E.v1;
const x2 = E.v2;
''');

    _assertTopVarConstValue('x1', r'''
E<double>
  _name: String v1
  f: double 10.0
  index: int 0
''');

    _assertTopVarConstValue('x2', r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
''');
  }

  test_object_enum_enhanced_unnamed() async {
    await resolveTestCode('''
enum E<T> {
  v1<int>(10),
  v2(20),
  v3('abc');
  final T f;
  const E(this.f);
}

const x1 = E.v1;
const x2 = E.v2;
const x3 = E.v3;
''');

    _assertTopVarConstValue('x1', r'''
E<int>
  _name: String v1
  f: int 10
  index: int 0
''');

    _assertTopVarConstValue('x2', r'''
E<int>
  _name: String v2
  f: int 20
  index: int 1
''');

    _assertTopVarConstValue('x3', r'''
E<String>
  _name: String v3
  f: String abc
  index: int 2
''');
  }

  test_parenthesizedExpression() async {
    await _assertValueString("a", "('a')");
  }

  test_plus_double_double() async {
    await _assertValueDouble(2.3 + 3.2, "2.3 + 3.2");
  }

  test_plus_int_int() async {
    await _assertValueInt(5, "2 + 3");
  }

  test_plus_string_string() async {
    await _assertValueString("ab", "'a' + 'b'");
  }

  @failingTest
  test_prefixedIdentifier_invalid() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_prefixedIdentifier_valid() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_propertyAccess_invalid() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_propertyAccess_valid() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_simpleIdentifier_invalid() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  @failingTest
  test_simpleIdentifier_valid() async {
    var result = await _getExpressionValue("?");
    expect(result.isValid, isTrue);
    var value = result.value;
    expect(value, null);
  }

  test_stringLength_complex() async {
    await _assertValueInt(6, "('qwe' + 'rty').length");
  }

  test_stringLength_simple() async {
    await _assertValueInt(6, "'Dvorak'.length");
  }

  test_superFormalParameter_explicitSuper_hasNamedArgument_requiredNamed() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  final int b;
  const A({required this.a, required this.b});
}

class B extends A {
  final int c;
  const B(this.c, {required super.b}) : super(a: 1);
}

const x = B(3, b: 2);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
    b: int 2
  c: int 3
''');
  }

  test_superFormalParameter_explicitSuper_hasNamedArgument_requiredPositional() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  final int b;
  const A(this.a, {required this.b});
}

class B extends A {
  final int c;
  const B(super.a, {required this.c}) : super(b: 2);
}

const x = B(1, c: 3);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
    b: int 2
  c: int 3
''');
  }

  test_superFormalParameter_explicitSuper_requiredNamed() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B extends A {
  final int b;
  const B(this.b, {required super.a}) : super();
}

const x = B(2, a: 1);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_explicitSuper_requiredNamed_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B<T> extends A {
  final int b;
  const B(this.b, {required super.a}) : super();
}

const x = B<int>(2, a: 1);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_explicitSuper_requiredPositional() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B extends A {
  final int b;
  const B(super.a, this.b) : super();
}

const x = B(1, 2);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_explicitSuper_requiredPositional_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B<T> extends A {
  final int b;
  const B(super.a, this.b) : super();
}

const x = B<int>(1, 2);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_implicitSuper_requiredNamed() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B extends A {
  final int b;
  const B(this.b, {required super.a});
}

const x = B(2, a: 1);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_implicitSuper_requiredNamed_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A({required this.a});
}

class B<T> extends A {
  final int b;
  const B(this.b, {required super.a});
}

const x = B<int>(2, a: 1);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_implicitSuper_requiredPositional() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B extends A {
  final int b;
  const B(super.a, this.b);
}

const x = B(1, 2);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B
  (super): A
    a: int 1
  b: int 2
''');
  }

  test_superFormalParameter_implicitSuper_requiredPositional_generic() async {
    await assertNoErrorsInCode('''
class A {
  final int a;
  const A(this.a);
}

class B<T> extends A {
  final int b;
  const B(super.a, this.b);
}

const x = B<int>(1, 2);
''');

    var value = findElement.topVar('x').evaluationResult.value;
    assertDartObjectText(value, r'''
B<int>
  (super): A
    a: int 1
  b: int 2
''');
  }

  void _assertTopVarConstValue(String name, String expected) {
    assertDartObjectText(_topVarConstResult(name).value, expected);
  }

  Future<void> _assertValueBool(bool expectedValue, String contents) async {
    var result = await _getExpressionValue(contents);
    DartObject value = result.value!;
    assertType(value.type, "bool");
    expect(value.toBoolValue(), expectedValue);
  }

  Future<void> _assertValueDouble(double expectedValue, String contents) async {
    var result = await _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, "double");
    expect(value.toDoubleValue(), expectedValue);
  }

  Future<void> _assertValueInt(int expectedValue, String contents) async {
    var result = await _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value!;
    assertType(value.type, "int");
    expect(value.toIntValue(), expectedValue);
  }

  Future<void> _assertValueString(String expectedValue, String contents) async {
    var result = await _getExpressionValue(contents);
    DartObject value = result.value!;
    assertType(value.type, 'String');
  }

  Future<EvaluationResult> _getExpressionValue(String expressionCode,
      {String context = ''}) async {
    await resolveTestCode('''
var x = $expressionCode;

$context
''');

    var expression = findNode.variableDeclaration('x =').initializer!;

    var file = getFile(result.path);
    var evaluator = ConstantEvaluator(
      file.createSource(result.uri),
      result.libraryElement as LibraryElementImpl,
    );

    return evaluator.evaluate(expression);
  }

  EvaluationResultImpl _topVarConstResult(String name) {
    var element = findElement.topVar(name) as ConstTopLevelVariableElementImpl;
    return element.evaluationResult!;
  }
}

extension on VariableElement {
  EvaluationResultImpl get evaluationResult {
    var constVariable = this as ConstVariableElement;
    var evaluationResult = constVariable.evaluationResult;
    if (evaluationResult == null) {
      fail('Not evaluated: $this');
    }
    return evaluationResult;
  }
}
