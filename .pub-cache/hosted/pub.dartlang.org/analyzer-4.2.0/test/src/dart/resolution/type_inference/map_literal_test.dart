// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapLiteralTest);
    defineReflectiveTests(MapLiteralWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MapLiteralTest extends PubPackageResolutionTest with MapLiteralTestCases {
  test_context_noTypeArgs_noEntries_typeParameterNullable() async {
    await assertNoErrorsInCode('''
class C<T extends Object?> {
  Map<String, T> a = {}; // 1
  Map<String, T>? b = {}; // 2
  Map<String, T?> c = {}; // 3
  Map<String, T?>? d = {}; // 4
}
''');
    assertType(setOrMapLiteral('{}; // 1'), 'Map<String, T>');
    assertType(setOrMapLiteral('{}; // 2'), 'Map<String, T>');
    assertType(setOrMapLiteral('{}; // 3'), 'Map<String, T?>');
    assertType(setOrMapLiteral('{}; // 4'), 'Map<String, T?>');
  }

  test_context_spread_nullAware() async {
    await assertNoErrorsInCode('''
T f<T>(T t) => t;

main() {
  <int, double>{...?f(null)};
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
          substitution: {T: Map<int, double>?}
        staticType: Null
    rightParenthesis: )
  staticInvokeType: Map<int, double>? Function(Map<int, double>?)
  staticType: Map<int, double>?
  typeArgumentTypes
    Map<int, double>?
''');
  }

  test_noContext_noTypeArgs_spread_never() async {
    await assertErrorsInCode('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0: throw 0};
}
''', [
      error(HintCode.DEAD_CODE, 87, 21),
    ]);
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_never() async {
    await assertErrorsInCode('''
void f(Never a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 77, 4),
      error(HintCode.DEAD_CODE, 88, 21),
    ]);
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_null() async {
    await assertErrorsInCode('''
void f(Null a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
}
''', [
      error(HintCode.DEAD_CODE, 99, 7),
    ]);
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_never() async {
    await assertErrorsInCode('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
}
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 90, 4),
      error(HintCode.DEAD_CODE, 101, 21),
    ]);
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_nullAware_typeParameter_null() async {
    await assertErrorsInCode('''
void f<T extends Null>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...?a, if (b) throw 0: throw 0};
}
''', [
      error(HintCode.DEAD_CODE, 112, 7),
    ]);
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }

  test_noContext_noTypeArgs_spread_typeParameter_never() async {
    await assertErrorsInCode('''
void f<T extends Never>(T a, bool b) async {
  // ignore:unused_local_variable
  var v = {...a, if (b) throw 0: throw 0};
}
''', [
      error(HintCode.DEAD_CODE, 100, 21),
    ]);
    assertType(setOrMapLiteral('{...'), 'Map<Never, Never>');
  }
}

mixin MapLiteralTestCases on PubPackageResolutionTest {
  AstNode setOrMapLiteral(String search) => findNode.setOrMapLiteral(search);

  test_context_noTypeArgs_entry_conflictingKey() async {
    await assertErrorsInCode('''
Map<int, int> a = {'a' : 1};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 19, 3),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_conflictingValue() async {
    await assertErrorsInCode('''
Map<int, int> a = {1 : 'a'};
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 23, 3),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_entry_noConflict() async {
    await assertNoErrorsInCode('''
Map<int, int> a = {1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_noTypeArgs_noElements_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<Map<int, String>> f() {
  return {};
}
''');
    assertType(setOrMapLiteral('{};'), 'Map<int, String>');
  }

  test_context_noTypeArgs_noEntries_fromParameterType() async {
    await assertNoErrorsInCode('''
void f() {
  useMap({});
}
void useMap(Map<int, String> _) {}
''');
    assertType(setOrMapLiteral('{})'), 'Map<int, String>');
  }

  test_context_noTypeArgs_noEntries_fromVariableType() async {
    await assertNoErrorsInCode('''
Map<String, String> a = {};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_noTypeArgs_noEntries_typeParameters() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 46, 2),
      ],
      legacy: [
        error(CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP, 46, 2),
      ],
    );
    await assertErrorsInCode('''
class A<E extends Map<int, String>> {
  E a = {};
}
''', expectedErrors);
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_noTypeArgs_noEntries_typeParameters_dynamic() async {
    var expectedErrors = expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 51, 2),
      ],
      legacy: [
        error(CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP, 51, 2),
      ],
    );
    await assertErrorsInCode('''
class A<E extends Map<dynamic, dynamic>> {
  E a = {};
}
''', expectedErrors);
    assertType(setOrMapLiteral('{}'), 'Map<dynamic, dynamic>');
  }

  test_context_typeArgs_entry_conflictingKey() async {
    await assertErrorsInCode('''
Map<String, String> a = <String, String>{0 : 'a'};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 41, 1),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_conflictingValue() async {
    await assertErrorsInCode('''
Map<String, String> a = <String, String>{'a' : 1};
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 47, 1),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_entry_noConflict() async {
    await assertNoErrorsInCode('''
Map<String, String> a = <String, String>{'a' : 'b'};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_context_typeArgs_noEntries_conflict() async {
    await assertErrorsInCode('''
Map<String, String> a = <int, int>{};
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 24, 12),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_context_typeArgs_noEntries_noConflict() async {
    await assertNoErrorsInCode('''
Map<String, String> a = <String, String>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<String, String>');
  }

  test_default_constructor_param_typed() async {
    await assertNoErrorsInCode('''
class C {
  const C({x = const <String, int>{}});
}
''');
  }

  test_default_constructor_param_untyped() async {
    await assertNoErrorsInCode('''
class C {
  const C({x = const {}});
}
''');
  }

  test_noContext_noTypeArgs_expressions_lubOfIntAndString() async {
    await assertNoErrorsInCode('''
var a = {1 : 'a', 2 : 'b', 3 : 'c'};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_expressions_lubOfNumAndNum() async {
    await assertNoErrorsInCode('''
var a = {1 : 2, 3.0 : 4, 5 : 6.0};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_expressions_lubOfObjectAndObject() async {
    await assertNoErrorsInCode('''
var a = {1 : '1', '2' : 2, 3 : '3'};
''');
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_forEachWithDeclaration() async {
    await assertNoErrorsInCode('''
List<int> c = [];
var a = {for (int e in c) e : e * 2};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forEachWithIdentifier() async {
    await assertNoErrorsInCode('''
List<int> c = [];
int b = 0;
var a = {for (b in c) b * 2 : b};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithDeclaration() async {
    await assertNoErrorsInCode('''
var a = {for (var i = 0; i < 2; i++) i : i * 2};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_forWithExpression() async {
    await assertNoErrorsInCode('''
int i = 0;
var a = {for (i = 0; i < 2; i++) i * 2 : i};
''');
    assertType(setOrMapLiteral('{for'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_if() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfIntAndInt() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1 : 3 else 2 : 4};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfNumAndNum() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1.0 : 3 else 2 : 4.0};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_ifElse_lubOfObjectAndObject() async {
    await assertNoErrorsInCode('''
bool c = true;
var a = {if (c) 1 : '1' else '2': 2 };
''');
    assertType(setOrMapLiteral('{'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_noEntries() async {
    await assertNoErrorsInCode('''
var a = {};
''');
    assertType(setOrMapLiteral('{'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread() async {
    await assertNoErrorsInCode('''
Map<int, int> c = {};
var a = {...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_dynamic() async {
    await assertNoErrorsInCode('''
var c = {};
var a = {...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_lubOfIntAndInt() async {
    await assertNoErrorsInCode('''
Map<int, int> c = {};
Map<int, int> b = {};
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, int>');
  }

  test_noContext_noTypeArgs_spread_lubOfNumAndNum() async {
    await assertNoErrorsInCode('''
Map<int, double> c = {};
Map<double, int> b = {};
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<num, num>');
  }

  test_noContext_noTypeArgs_spread_lubOfObjectObject() async {
    await assertNoErrorsInCode('''
Map<int, int> c = {};
Map<String, String> b = {};
var a = {...b, ...c};
''');
    assertType(setOrMapLiteral('{...'), 'Map<Object, Object>');
  }

  test_noContext_noTypeArgs_spread_mixin() async {
    await assertNoErrorsInCode(r'''
mixin M on Map<String, int> {}

void f(M m1) {
  // ignore:unused_local_variable
  var m2 = {...m1};
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<String, int>');
  }

  test_noContext_noTypeArgs_spread_nestedInIf_oneAmbiguous() async {
    await assertNoErrorsInCode('''
Map<String, int> c = {};
dynamic d;
var a = {if (0 < 1) ...c else ...d};
''');
    assertType(setOrMapLiteral('{if'), 'Map<dynamic, dynamic>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_map() async {
    await assertNoErrorsInCode('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1 : 'a', ...?a, 2 : 'b'};
}
''');
    assertType(setOrMapLiteral('{1'), 'Map<int, String>');
  }

  test_noContext_noTypeArgs_spread_nullAware_nullAndNotNull_set() async {
    await assertNoErrorsInCode('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {1, ...?a, 2};
}
''');
    assertType(setOrMapLiteral('{1'), 'Set<int>');
  }

  test_noContext_noTypeArgs_spread_nullAware_onlyNull() async {
    await assertErrorsInCode('''
void f(Null a) {
  // ignore:unused_local_variable
  var v = {...?a};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 61, 7),
    ]);
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_noTypeArgs_spread_typeParameter_implementsMap() async {
    await assertNoErrorsInCode('''
void f<T extends Map<int, String>>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''');
    assertType(setOrMapLiteral('{...'), 'Map<int, String>');
  }

  /// TODO(scheglov) Should report [CompileTimeErrorCode.NOT_ITERABLE_SPREAD].
  test_noContext_noTypeArgs_spread_typeParameter_notImplementsMap() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 73, 6),
    ]);
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  /// TODO(scheglov) Should report [CompileTimeErrorCode.NOT_ITERABLE_SPREAD].
  test_noContext_noTypeArgs_spread_typeParameter_notImplementsMap2() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  // ignore:unused_local_variable
  var v = {...a, 0: 1};
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER, 73, 12),
    ]);
    assertType(setOrMapLiteral('{...'), 'dynamic');
  }

  test_noContext_typeArgs_entry_conflictingKey() async {
    await assertErrorsInCode('''
var a = <String, int>{1 : 2};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 22, 1),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_conflictingValue() async {
    await assertErrorsInCode('''
var a = <String, int>{'a' : 'b'};
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 28, 3),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<String, int>');
  }

  test_noContext_typeArgs_entry_noConflict() async {
    await assertNoErrorsInCode('''
var a = <int, int>{1 : 2};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_expression_conflictingElement() async {
    await assertErrorsInCode('''
var a = <int, String>{1};
''', [
      error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 22, 1),
    ]);
    assertType(setOrMapLiteral('{'), 'Map<int, String>');
  }

  @failingTest
  test_noContext_typeArgs_expressions_conflictingTypeArgs() async {
    await assertNoErrorsInCode('''
var a = <int>{1 : 2, 3 : 4};
''');
    assertType(setOrMapLiteral('{'), 'Map<int, int>');
  }

  test_noContext_typeArgs_noEntries() async {
    await assertNoErrorsInCode('''
var a = <num, String>{};
''');
    assertType(setOrMapLiteral('{'), 'Map<num, String>');
  }
}

@reflectiveTest
class MapLiteralWithoutNullSafetyTest extends PubPackageResolutionTest
    with MapLiteralTestCases, WithoutNullSafetyMixin {}
