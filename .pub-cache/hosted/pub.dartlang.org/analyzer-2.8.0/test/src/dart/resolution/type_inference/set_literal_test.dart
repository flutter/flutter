// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetLiteralTest);
  });
}

@reflectiveTest
class SetLiteralTest extends PubPackageResolutionTest {
  AstNode setLiteral(String search) => findNode.setOrMapLiteral(search);

  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_expression_conflict() async {
    await assertErrorsInCode('''
Set<int> a = {'a'};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 14, 3),
    ]);
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
Set<int> a = {1};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements_fromParameterType() async {
    await assertNoErrorsInCode('''
void f() {
  useSet({});
}
void useSet(Set<int> _) {}
''');
    assertType(setLiteral('{});'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements_fromVariableType() async {
    await assertNoErrorsInCode('''
Set<String> a = {};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_noTypeArgs_noElements_fromVariableType_nested() async {
    await assertNoErrorsInCode('''
Set<Set<String>> a = {{}};
''');
    assertType(setLiteral('{}'), 'Set<String>');
    assertType(setLiteral('{{}}'), 'Set<Set<String>>');
  }

  test_context_noTypeArgs_noElements_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<Set<int>> f() {
  return {};
}
''');
    assertType(setLiteral('{};'), 'Set<int>');
  }

  test_context_noTypeArgs_noElements_typeParameter() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 38, 2),
      ],
      legacy: [
        error(CompileTimeErrorCode.INVALID_CAST_LITERAL_SET, 38, 2),
      ],
    );
    await assertErrorsInCode('''
class A<E extends Set<int>> {
  E a = {};
}
''', expectedErrors);
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_noTypeArgs_noElements_typeParameter_dynamic() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 42, 2),
      ],
      legacy: [
        error(CompileTimeErrorCode.INVALID_CAST_LITERAL_SET, 42, 2),
      ],
    );
    await assertErrorsInCode('''
class A<E extends Set<dynamic>> {
  E a = {};
}
''', expectedErrors);
    assertType(setLiteral('{}'), 'Set<dynamic>');
  }

  test_context_noTypeArgs_noEntries() async {
    await assertNoErrorsInCode('''
Set<String> a = {};
''');
    assertType(setOrMapLiteral('{'), 'Set<String>');
  }

  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    await assertNoErrorsInCode('''
class C<T extends Object?> {
  Set<T> a = {}; // 1
  Set<T>? b = {}; // 2
  Set<T?> c = {}; // 3
  Set<T?>? d = {}; // 4
}
''');
    assertType(setOrMapLiteral('{}; // 1'), 'Set<T>');
    assertType(setOrMapLiteral('{}; // 2'), 'Set<T>');
    assertType(setOrMapLiteral('{}; // 3'), 'Set<T?>');
    assertType(setOrMapLiteral('{}; // 4'), 'Set<T?>');
  }

  test_context_typeArgs_expression_conflictingExpression() async {
    await assertErrorsInCode('''
Set<String> a = <String>{0};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 25, 1),
    ]);
    assertType(setLiteral('{'), 'Set<String>');
  }

  @failingTest
  test_context_typeArgs_expression_conflictingTypeArgs() async {
    await assertNoErrorsInCode('''
Set<String> a = <int>{'a'};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
Set<String> a = <String>{'a'};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_context_typeArgs_noElements_conflict() async {
    await assertErrorsInCode('''
Set<String> a = <int>{};
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 16, 7),
    ]);
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_context_typeArgs_noElements_noConflict() async {
    await assertNoErrorsInCode('''
Set<String> a = <String>{};
''');
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfInt() async {
    await assertNoErrorsInCode('''
var a = {1, 2, 3};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNum() async {
    await assertNoErrorsInCode('''
var a = {1, 2.3, 4};
''');
    assertType(setLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObject() async {
    await assertNoErrorsInCode('''
var a = {1, '2', 3};
''');
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = {for (int e in c) e * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await assertNoErrorsInCode('''
List<int> c = [];
int b = 0;
var a = {for (b in c) b * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await assertNoErrorsInCode('''
var a = {for (var i = 0; i < 2; i++) i * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await assertNoErrorsInCode('''
int i = 0;
var a = {for (i = 0; i < 2; i++) i * 2};
''');
    assertType(setLiteral('{for'), 'Set<int>');
  }

  test_noContext_noTypeArgs_if() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfInt() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1 else 2};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNum() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1 else 2.3};
''');
    assertType(setLiteral('{'), 'Set<num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObject() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1 else '2'};
''');
    assertType(setLiteral('{'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = {...c};
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfInt() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<int> b = [];
var a = {...b, ...c};
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNum() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<double> b = [];
var a = {...b, ...c};
''');
    assertType(setLiteral('{...'), 'Set<num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObject() async {
    await assertNoErrorsInCode('''
List<int> c = [];
List<String> b = [];
var a = {...b, ...c};
''');
    assertType(setLiteral('{...'), 'Set<Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await assertNoErrorsInCode(r'''
mixin S on Set<int> {}

void f(S s1) {
  // ignore:unused_local_variable
  var s2 = {...s1};
}
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await assertNoErrorsInCode('''
List<int> c = [];
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(setLiteral('{if'), 'Set<dynamic>');
  }

  test_noContext_noTypeArgs_spread_never() async {
    await assertErrorsInCode('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0};
}
''', [
      error(HintCode.DEAD_CODE, 87, 12),
    ]);
    assertType(setLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    await assertErrorsInCode('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 77, 4),
      error(HintCode.DEAD_CODE, 88, 12),
    ]);
    assertType(setLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    await assertNoErrorsInCode('''
void f(Null a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
}
''');
    assertType(setLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull() async {
    await assertNoErrorsInCode('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1, ...?a, 2};
}
''');
    assertType(setLiteral('{1'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_never() async {
    await assertErrorsInCode('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 90, 4),
      error(HintCode.DEAD_CODE, 101, 12),
    ]);
    assertType(setLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_null() async {
    await assertNoErrorsInCode('''
void f<T extends Null>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0};
}
''');
    assertType(setLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsIterable() async {
    await assertNoErrorsInCode('''
void f<T extends List<int>>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''');
    assertType(setLiteral('{...'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_never() async {
    await assertErrorsInCode('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0};
}
''', [
      error(HintCode.DEAD_CODE, 100, 12),
    ]);
    assertType(setLiteral('{...'), 'Set<Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 73, 6),
    ]);
    assertType(setLiteral('{...'), 'dynamic');
  }

  test_noContext_noTypeArgs_spread_typeParameter_notImplementsIterable2() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a, 0};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 73, 9),
    ]);
    assertType(setLiteral('{...'), 'dynamic');
  }

  test_noContext_typeArgs_expression_conflict() async {
    await assertErrorsInCode('''
var a = <String>{1};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 17, 1),
    ]);
    assertType(setLiteral('{'), 'Set<String>');
  }

  test_noContext_typeArgs_expression_noConflict() async {
    await assertNoErrorsInCode('''
var a = <int>{1};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflict() async {
    await assertNoErrorsInCode('''
var a = <int, String>{1, 2};
''');
    assertType(setLiteral('{'), 'Set<int>');
  }

  test_noContext_typeArgs_noElements() async {
    await assertNoErrorsInCode('''
var a = <num>{};
''');
    assertType(setLiteral('{'), 'Set<num>');
  }
}
