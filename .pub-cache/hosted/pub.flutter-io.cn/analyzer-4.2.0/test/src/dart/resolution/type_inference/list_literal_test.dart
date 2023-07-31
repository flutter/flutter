// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralTest);
    defineReflectiveTests(ListLiteralWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ListLiteralTest extends PubPackageResolutionTest
    with ListLiteralTestCases {
  test_context_spread_nullAware() async {
    await assertNoErrorsInCode('''
T f<T>(T t) => t;

main() {
  <int>[...?f(null)];
}
''');

    var node = findNode.methodInvocation('f(null)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: ParameterMember
          base: root::@parameter::t
          substitution: {T: Iterable<int>?}
        staticType: Null
    rightParenthesis: )
  staticInvokeType: Iterable<int>? Function(Iterable<int>?)
  staticType: Iterable<int>?
  typeArgumentTypes
    Iterable<int>?
''');
  }

  test_nested_hasNull_1() async {
    await assertNoErrorsInCode('''
main() {
  [[0], null];
}
''');
    assertType(findNode.listLiteral('[0'), 'List<int>');
    assertType(findNode.listLiteral('[[0'), 'List<List<int>?>');
  }

  test_nested_hasNull_2() async {
    await assertNoErrorsInCode('''
main() {
  [[0], [1, null]];
}
''');
    assertType(findNode.listLiteral('[0'), 'List<int>');
    assertType(findNode.listLiteral('[1,'), 'List<int?>');
    assertType(findNode.listLiteral('[[0'), 'List<List<int?>>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    await assertNoErrorsInCode('''
void f(Never a) async {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    await assertErrorsInCode('''
void f(Never a) async {
  // ignore:unused_local_variable
  var v = [...?a];
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 69, 4),
    ]);
    assertType(findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_implementsNever() async {
    await assertErrorsInCode('''
void f<T extends Never>(T a) async {
  // ignore:unused_local_variable
  var v = [...?a];
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 82, 4),
    ]);
    assertType(findNode.listLiteral('['), 'List<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsNever() async {
    await assertNoErrorsInCode('''
void f<T extends Never>(T a) async {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(findNode.listLiteral('['), 'List<Never>');
  }
}

mixin ListLiteralTestCases on PubPackageResolutionTest {
  test_context_noTypeArgs_expression_conflict() async {
    await assertErrorsInCode('''
List<int> a = ['a'];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 15, 3),
    ]);
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
List<int> a = [1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_noTypeArgs_noElements_fromReturnType() async {
    await assertNoErrorsInCode('''
List<int> f() {
  return [];
}
''');
    assertType(findNode.listLiteral('[]'), 'List<int>');
  }

  test_context_noTypeArgs_noElements_fromVariableType() async {
    await assertNoErrorsInCode('''
List<String> a = [];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 39, 2),
      ],
      legacy: [
        error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 39, 2),
      ],
    );
    await assertErrorsInCode('''
class A<E extends List<int>> {
  E a = [];
}
''', expectedErrors);
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 43, 2),
      ],
      legacy: [
        error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 43, 2),
      ],
    );
    await assertErrorsInCode('''
class A<E extends List<dynamic>> {
  E a = [];
}
''', expectedErrors);
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_context_typeArgs_expression_conflictingContext() async {
    await assertErrorsInCode('''
List<String> a = <int>[0];
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 17, 8),
    ]);
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    await assertErrorsInCode('''
List<String> a = <String>[0];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 26, 1),
    ]);
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  @failingTest
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    // Context type and element types both suggest `String`, so this should
    // override the explicit type argument.
    await assertNoErrorsInCode('''
List<String> a = <int>['a'];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
List<String> a = <String>['a'];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    await assertErrorsInCode('''
List<String> a = <int>[];
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 17, 7),
    ]);
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    await assertNoErrorsInCode('''
List<String> a = <String>[];
''');
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    await assertNoErrorsInCode('''
var a = [1, 2, 3];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    await assertNoErrorsInCode('''
var a = [1, 2.3, 4];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    await assertNoErrorsInCode('''
var a = [1, '2', 3];
''');
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_expressions_unresolved() async {
    await assertErrorsInCode('''
var a = [x];
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 9, 1),
    ]);
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_expressions_unresolved_multiple() async {
    await assertErrorsInCode('''
var a = [0, x, 2];
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 12, 1),
    ]);
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = [for (int e in c) e * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await assertNoErrorsInCode('''
List<int> c = [];
int b = 0;
var a = [for (b in c) b * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await assertNoErrorsInCode('''
var a = [for (var i = 0; i < 2; i++) i * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await assertNoErrorsInCode('''
int i = 0;
var a = [for (i = 0; i < 2; i++) i * 2];
''');
    assertType(findNode.listLiteral('[for'), 'List<int>');
  }

  test_noContext_noTypeArgs_if() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1 else 2];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1 else 2.3];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = [if (c) 1 else '2'];
''');
    assertType(findNode.listLiteral('['), 'List<Object>');
  }

  test_noContext_noTypeArgs_noElements() async {
    await assertNoErrorsInCode('''
var a = [];
''');
    assertType(findNode.listLiteral('['), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = [...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<int> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<double> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<String> b = [];
var a = [...b, ...c];
''');
    assertType(findNode.listLiteral('[...'), 'List<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await assertNoErrorsInCode(r'''
mixin L on List<int> {}

void f(L l1) {
  // ignore:unused_local_variable
  var l2 = [...l1];
}
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await assertNoErrorsInCode('''
List<int> c = [];
dynamic d;
var a = [if (0 < 1) ...c else ...d];
''');
    assertType(findNode.listLiteral('[if'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    await assertNoErrorsInCode('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = [...?a];
}
''');
    assertType(
      findNode.listLiteral('['),
      typeStringByNullability(
        nullable: 'List<Never>',
        legacy: 'List<Null>',
      ),
    );
  }

  test_noContext_noTypeArgs_spread_nullAware_null2() async {
    await assertNoErrorsInCode('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = [1, ...?a, 2];
}
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_implementsNull() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [],
      legacy: [
        error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 85, 1),
      ],
    );
    await assertErrorsInCode('''
void f<T extends Null>(T a) async {
  // ignore:unused_local_variable
  var v = [...?a];
}
''', expectedErrors);
    assertType(
      findNode.listLiteral('['),
      typeStringByNullability(
        nullable: 'List<Never>',
        legacy: 'List<dynamic>',
      ),
    );
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsIterable() async {
    await assertNoErrorsInCode('''
void f<T extends List<int>>(T a) {
  // ignore:unused_local_variable
  var v = [...a];
}
''');
    assertType(findNode.listLiteral('[...'), 'List<int>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = [...a];
}
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 77, 1),
    ]);
    assertType(findNode.listLiteral('[...'), 'List<dynamic>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable2() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = [...a, 0];
}
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 77, 1),
    ]);
    assertType(findNode.listLiteral('[...'), 'List<dynamic>');
  }

  test_noContext_typeArgs_expression_conflict() async {
    await assertErrorsInCode('''
var a = <String>[1];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 17, 1),
    ]);
    assertType(findNode.listLiteral('['), 'List<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
var a = <int>[1];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflict() async {
    await assertNoErrorsInCode('''
var a = <int, String>[1, 2];
''');
    assertType(findNode.listLiteral('['), 'List<int>');
  }

  test_noContext_typeArgs_noElements() async {
    await assertNoErrorsInCode('''
var a = <num>[];
''');
    assertType(findNode.listLiteral('['), 'List<num>');
  }
}

@reflectiveTest
class ListLiteralWithoutNullSafetyTest extends PubPackageResolutionTest
    with ListLiteralTestCases, WithoutNullSafetyMixin {}
