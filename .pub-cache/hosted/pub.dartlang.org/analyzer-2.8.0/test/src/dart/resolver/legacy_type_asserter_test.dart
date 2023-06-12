// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/legacy_type_asserter.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LegacyTypeAsserterTest);
  });
}

@reflectiveTest
class LegacyTypeAsserterTest {
  late final TypeProvider typeProvider;

  void setUp() {
    var analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProviderLegacy;
  }

  test_nullableUnit_expressionStaticType_bottom() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = NeverTypeImpl.instance;
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_bottomQuestion() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = NeverTypeImpl.instanceNullable;
    LegacyTypeAsserter.assertLegacyTypes(unit);
  }

  test_nullableUnit_expressionStaticType_dynamic() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = typeProvider.dynamicType;
    LegacyTypeAsserter.assertLegacyTypes(unit);
  }

  test_nullableUnit_expressionStaticType_nonNull() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = (typeProvider.intType as TypeImpl)
        .withNullability(NullabilitySuffix.none);
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_nonNullTypeArgument() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = typeProvider.listType(
        (typeProvider.intType as TypeImpl)
            .withNullability(NullabilitySuffix.question));

    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_nonNullTypeParameter() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = typeProvider.listElement.instantiate(
      typeArguments: [
        TypeParameterElementImpl('E', 0).instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_nonNullTypeParameterBound() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    var T = TypeParameterElementImpl.synthetic('T');
    T.bound = (typeProvider.intType as TypeImpl)
        .withNullability(NullabilitySuffix.none);
    identifier.staticType = TypeParameterTypeImpl(
      element: T,
      nullabilitySuffix: NullabilitySuffix.star,
    );
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_null() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = typeProvider.nullType;
    LegacyTypeAsserter.assertLegacyTypes(unit);
  }

  test_nullableUnit_expressionStaticType_question() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = (typeProvider.intType as TypeImpl)
        .withNullability(NullabilitySuffix.question);
    expect(() {
      LegacyTypeAsserter.assertLegacyTypes(unit);
    }, throwsStateError);
  }

  test_nullableUnit_expressionStaticType_star() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = (typeProvider.intType as TypeImpl)
        .withNullability(NullabilitySuffix.star);
    LegacyTypeAsserter.assertLegacyTypes(unit);
  }

  test_nullableUnit_expressionStaticType_void() async {
    var identifier = AstTestFactory.identifier3('foo');
    var unit = _wrapExpression(identifier);
    identifier.staticType = VoidTypeImpl.instance;
    LegacyTypeAsserter.assertLegacyTypes(unit);
  }

  CompilationUnit _wrapExpression(Expression e, {bool nonNullable = false}) {
    return AstTestFactory.compilationUnit9(
      declarations: [
        AstTestFactory.functionDeclaration(
            null,
            null,
            'f',
            AstTestFactory.functionExpression2(
                AstTestFactory.formalParameterList(),
                AstTestFactory.expressionFunctionBody(e)))
      ],
      featureSet: nonNullable
          ? FeatureSet.latestLanguageVersion()
          : FeatureSet.fromEnableFlags2(
              sdkLanguageVersion: Version.parse('2.9.0'),
              flags: [],
            ),
    );
  }
}
