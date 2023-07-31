// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/constant/from_environment_evaluator.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_analysis_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FromEnvironmentEvaluatorTest);
  });
}

@reflectiveTest
class FromEnvironmentEvaluatorTest {
  static const String _defaultValue = 'defaultValue';

  late final TypeProvider typeProvider;
  late final TypeSystemImpl typeSystem;

  DartObjectImpl get _boolValueFalse {
    return DartObjectImpl(
      typeSystem,
      typeProvider.boolType,
      BoolState.FALSE_STATE,
    );
  }

  DartObjectImpl get _boolValueTrue {
    return DartObjectImpl(
      typeSystem,
      typeProvider.boolType,
      BoolState.TRUE_STATE,
    );
  }

  DartObjectImpl get _nullValue {
    return DartObjectImpl(
      typeSystem,
      typeProvider.nullType,
      NullState.NULL_STATE,
    );
  }

  void setUp() {
    var analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProviderLegacy;
    typeSystem = analysisContext.typeSystemLegacy;
  }

  void test_getBool_default() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({}),
    );
    var object = _getBool(
      variables,
      name,
      {_defaultValue: _boolValueFalse},
    );
    expect(object, _boolValueFalse);
  }

  void test_getBool_false() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({name: 'false'}),
    );
    var object = _getBool(
      variables,
      name,
      {_defaultValue: _boolValueFalse},
    );
    expect(object, _boolValueFalse);
  }

  void test_getBool_invalid() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({name: 'not bool'}),
    );
    var object = _getBool(
      variables,
      name,
      {_defaultValue: _boolValueFalse},
    );
    expect(object, _boolValueFalse);
  }

  void test_getBool_true() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({name: 'true'}),
    );
    var object = _getBool(
      variables,
      name,
      {_defaultValue: _boolValueFalse},
    );
    expect(object, _boolValueTrue);
  }

  void test_getInt_invalid() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({name: 'four score and seven years'}),
    );
    var object = _getInt(
      variables,
      name,
      {_defaultValue: _intValue(0)},
    );
    expect(object, _intValue(0));
  }

  void test_getInt_undefined_defaultNull() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    var object = _getInt(
      variables,
      name,
      {_defaultValue: _nullValue},
    );
    expect(object, _nullValue);
  }

  void test_getInt_undefined_defaultZero() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    var object = _getInt(
      variables,
      name,
      {_defaultValue: _intValue(0)},
    );
    expect(object, _intValue(0));
  }

  void test_getInt_valid() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({name: '23'}),
    );
    var object = _getInt(
      variables,
      name,
      {_defaultValue: _intValue(0)},
    );
    expect(object, _intValue(23));
  }

  void test_getString_defined() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({name: 'bar'}),
    );
    var object = _getString(
      variables,
      name,
      {_defaultValue: _nullValue},
    );
    expect(object, _stringValue('bar'));
  }

  void test_getString_undefined_defaultEmpty() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    var object = _getString(
      variables,
      name,
      {_defaultValue: _stringValue('')},
    );
    expect(object, _stringValue(''));
  }

  void test_getString_undefined_defaultNull() {
    var name = 'foo';
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    var object = _getString(
      variables,
      name,
      {_defaultValue: _nullValue},
    );
    expect(object, _nullValue);
  }

  DartObjectImpl _getBool(
    FromEnvironmentEvaluator variables,
    String name,
    Map<String, DartObjectImpl> namedValues,
  ) {
    return variables.getBool2(
      name,
      namedValues,
      typeProvider.boolElement.getNamedConstructor('fromEnvironment')!,
    );
  }

  DartObjectImpl _getInt(
    FromEnvironmentEvaluator variables,
    String name,
    Map<String, DartObjectImpl> namedValues,
  ) {
    return variables.getInt2(
      name,
      namedValues,
      typeProvider.intElement.getNamedConstructor('fromEnvironment')!,
    );
  }

  DartObjectImpl _getString(
    FromEnvironmentEvaluator variables,
    String name,
    Map<String, DartObjectImpl> namedValues,
  ) {
    return variables.getString2(
      name,
      namedValues,
      typeProvider.stringElement.getNamedConstructor('fromEnvironment')!,
    );
  }

  DartObjectImpl _intValue(int value) {
    return DartObjectImpl(
      typeSystem,
      typeProvider.intType,
      IntState(value),
    );
  }

  DartObjectImpl _stringValue(String value) {
    return DartObjectImpl(
      typeSystem,
      typeProvider.stringType,
      StringState(value),
    );
  }
}
