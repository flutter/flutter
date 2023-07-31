// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableTest);
    defineReflectiveTests(TopLevelVariableWithoutNullSafetyTest);
  });
}

@reflectiveTest
class TopLevelVariableTest extends PubPackageResolutionTest
    with TopLevelVariableTestCases {
  /// See https://github.com/dart-lang/sdk/issues/51137
  test_initializer_contextType_dontUseInferredType() async {
    await assertErrorsInCode('''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final x = f(g, (z) => z.length);
''', [
      error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
          108, 6),
    ]);
    final node = findNode.variableDeclaration('x =');
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T? Function<T>(T Function(), int Function(T))
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: g
          parameter: ParameterMember
            base: root::@parameter::a
            substitution: {T: String}
          staticElement: self::@function::g
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: SimpleFormalParameter
              name: z
              declaredElement: @99::@parameter::z
              declaredElementType: Object?
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: z
                staticElement: @99::@parameter::z
                staticType: Object?
              period: .
              identifier: SimpleIdentifier
                token: length
                staticElement: <null>
                staticType: dynamic
              staticElement: <null>
              staticType: dynamic
          declaredElement: @99
          parameter: ParameterMember
            base: root::@parameter::b
            substitution: {T: String}
          staticType: int Function(Object?)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredElement: self::@variable::x
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/51137
  test_initializer_contextType_typeAnnotation() async {
    await assertNoErrorsInCode('''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final String? x = f(g, (z) => z.length);
''');
    final node = findNode.variableDeclaration('x =');
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T? Function<T>(T Function(), int Function(T))
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: g
          parameter: ParameterMember
            base: root::@parameter::a
            substitution: {T: String}
          staticElement: self::@function::g
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: SimpleFormalParameter
              name: z
              declaredElement: @107::@parameter::z
              declaredElementType: String
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: z
                staticElement: @107::@parameter::z
                staticType: String
              period: .
              identifier: SimpleIdentifier
                token: length
                staticElement: dart:core::@class::String::@getter::length
                staticType: int
              staticElement: dart:core::@class::String::@getter::length
              staticType: int
          declaredElement: @107
          parameter: ParameterMember
            base: root::@parameter::b
            substitution: {T: String}
          staticType: int Function(String)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredElement: self::@variable::x
''');
  }

  test_type_inferred_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
var a = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

var v = a;
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertType(findElement.topVar('v').type, 'int');
  }
}

mixin TopLevelVariableTestCases on PubPackageResolutionTest {
  test_session_getterSetter() async {
    await resolveTestCode('''
var v = 0;
''');
    var getter = findElement.topGet('v');
    expect(getter.session, result.session);

    var setter = findElement.topSet('v');
    expect(setter.session, result.session);
  }

  test_type_inferred_int() async {
    await resolveTestCode('''
var v = 0;
''');
    assertType(findElement.topVar('v').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
var v = throw 42;
''');
    assertType(
      findElement.topVar('v').type,
      typeStringByNullability(
        nullable: 'Never',
        legacy: 'dynamic',
      ),
    );
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
var v;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
var v = null;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }
}

@reflectiveTest
class TopLevelVariableWithoutNullSafetyTest extends PubPackageResolutionTest
    with TopLevelVariableTestCases, WithoutNullSafetyMixin {}
