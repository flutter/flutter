// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import '../util/feature_sets.dart';
import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormalParameterParserTest);
  });
}

/// The class [FormalParameterParserTest] defines parser tests that test
/// the parsing of formal parameters.
@reflectiveTest
class FormalParameterParserTest extends FastaParserTestCase {
  FormalParameter parseNNBDFormalParameter(String code, ParameterKind kind,
      {List<ExpectedError>? errors}) {
    String parametersCode;
    if (kind == ParameterKind.REQUIRED) {
      parametersCode = '($code)';
    } else if (kind == ParameterKind.POSITIONAL) {
      parametersCode = '([$code])';
    } else if (kind == ParameterKind.NAMED) {
      parametersCode = '({$code})';
    } else {
      fail('$kind');
    }
    createParser(parametersCode);
    FormalParameterList list =
        parserProxy.parseFormalParameterList(inFunctionType: false);
    assertErrors(errors: errors);
    return list.parameters.single;
  }

  void test_fieldFormalParameter_function_nullable() {
    var parameter =
        parseNNBDFormalParameter('void this.a()?', ParameterKind.REQUIRED);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var functionParameter = parameter as FieldFormalParameter;
    expect(functionParameter.type, isNotNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
    expect(functionParameter.endToken, functionParameter.question);
  }

  void test_functionTyped_named_nullable() {
    ParameterKind kind = ParameterKind.NAMED;
    var defaultParameter =
        parseNNBDFormalParameter('a()? : null', kind) as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    assertNoErrors();
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isNamed, isTrue);
    expect(functionParameter.question, isNotNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_functionTyped_named_nullable_disabled() {
    ParameterKind kind = ParameterKind.NAMED;
    var defaultParameter = parseFormalParameter('a()? : null', kind,
            featureSet: FeatureSets.language_2_9,
            errorCodes: [ParserErrorCode.EXPERIMENT_NOT_ENABLED])
        as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isNamed, isTrue);
    expect(functionParameter.question, isNotNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_functionTyped_positional_nullable_disabled() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    var defaultParameter = parseFormalParameter('a()? = null', kind,
            featureSet: FeatureSets.language_2_9,
            errorCodes: [ParserErrorCode.EXPERIMENT_NOT_ENABLED])
        as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isOptionalPositional, isTrue);
    expect(functionParameter.question, isNotNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_functionTyped_required_nullable_disabled() {
    ParameterKind kind = ParameterKind.REQUIRED;
    var functionParameter = parseFormalParameter('a()?', kind,
            featureSet: FeatureSets.language_2_9,
            errorCodes: [ParserErrorCode.EXPERIMENT_NOT_ENABLED])
        as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isRequiredPositional, isTrue);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseConstructorParameter_this() {
    parseCompilationUnit('''
class C {
  final int field;
  C(this.field);
}''');
  }

  void test_parseConstructorParameter_this_Function() {
    parseCompilationUnit('''
class C {
  final Object Function(int, double) field;
  C(String Function(num, Object) this.field);
}''');
  }

  void test_parseConstructorParameter_this_int() {
    parseCompilationUnit('''
class C {
  final int field;
  C(int this.field);
}''');
  }

  void test_parseFormalParameter_covariant_final_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant final a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_final_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('covariant final a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_final_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant final a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_covariant_final_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant final A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_final_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('covariant final A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_final_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant final A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_covariant_required_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseNNBDFormalParameter(
        'covariant required A a : null', kind,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 12, 8)]);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_type_function() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('covariant String Function(int) a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isGenericFunctionType);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('covariant A<B<C>> a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_covariant_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseFormalParameter('covariant var a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_covariant_var_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('covariant var a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_covariant_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter =
        parseFormalParameter('covariant var a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_external() {
    parseNNBDFormalParameter('external int i', ParameterKind.REQUIRED, errors: [
      expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 1, 8),
    ]);
  }

  void test_parseFormalParameter_final_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('final a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_final_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('final a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_final_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('final a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_final_required_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseNNBDFormalParameter(
        'final required a : null', kind,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 8, 8)]);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_final_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('final A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_final_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('final A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_final_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('final A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_required_covariant_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required covariant A a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNotNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_final_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required final a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required A a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_required_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter =
        parseNNBDFormalParameter('required var a : null', kind);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_type_function() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter =
        parseFormalParameter('String Function(int) a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isGenericFunctionType);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_type_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('A a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_type_named_noDefault() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNull);
    expect(defaultParameter.defaultValue, isNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_type_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_type_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('A a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_type_positional_noDefault() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('A a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNull);
    expect(defaultParameter.defaultValue, isNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseFormalParameter('var a : null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameter_var_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    FormalParameter parameter = parseFormalParameter('var a', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isRequired, isTrue);
  }

  void test_parseFormalParameter_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    FormalParameter parameter = parseFormalParameter('var a = null', kind);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isOptionalPositional, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isOptionalPositional, isTrue);
  }

  void test_parseFormalParameter_var_required_named() {
    ParameterKind kind = ParameterKind.NAMED;
    FormalParameter parameter = parseNNBDFormalParameter(
        'var required a : null', kind,
        errors: [expectedError(ParserErrorCode.MODIFIER_OUT_OF_ORDER, 6, 8)]);
    expect(parameter, isNotNull);
    expect(parameter, isDefaultFormalParameter);
    var defaultParameter = parameter as DefaultFormalParameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.requiredKeyword, isNotNull);
    expect(simpleParameter.name, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.isNamed, isTrue);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseFormalParameterList_empty() {
    FormalParameterList list = parseFormalParameterList('()');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(0));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_multiple() {
    FormalParameterList list =
        parseFormalParameterList('({A a : 1, B b, C c : 3})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_single() {
    FormalParameterList list = parseFormalParameterList('({A a})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_trailing_comma() {
    FormalParameterList list = parseFormalParameterList('(A a, {B b,})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_multiple() {
    FormalParameterList list = parseFormalParameterList('(A a, B b, C c)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_named() {
    FormalParameterList list = parseFormalParameterList('(A a, {B b})');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_named_inFunctionType() {
    FormalParameterList list =
        parseFormalParameterList('(A, {B b})', inFunctionType: true);
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
    NodeList<FormalParameter> parameters = list.parameters;
    expect(parameters, hasLength(2));

    expect(parameters[0], isSimpleFormalParameter);
    var required = parameters[0] as SimpleFormalParameter;
    expect(required.name, isNull);
    expect(required.type, isNamedType);
    expect((required.type as NamedType).name.name, 'A');

    expect(parameters[1], isDefaultFormalParameter);
    var named = parameters[1] as DefaultFormalParameter;
    expect(named.name, isNotNull);
    expect(named.parameter, isSimpleFormalParameter);
    var simple = named.parameter as SimpleFormalParameter;
    expect(simple.type, isNamedType);
    expect((simple.type as NamedType).name.name, 'B');
  }

  void test_parseFormalParameterList_normal_positional() {
    FormalParameterList list = parseFormalParameterList('(A a, [B b])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single() {
    FormalParameterList list = parseFormalParameterList('(A a)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single_Function() {
    FormalParameterList list = parseFormalParameterList('(Function f)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single_trailing_comma() {
    FormalParameterList list = parseFormalParameterList('(A a,)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_multiple() {
    FormalParameterList list =
        parseFormalParameterList('([A a = null, B b, C c = null])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_single() {
    FormalParameterList list = parseFormalParameterList('([A a = null])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_trailing_comma() {
    FormalParameterList list = parseFormalParameterList('(A a, [B b,])');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType() {
    FormalParameterList list = parseFormalParameterList('(io.File f)');
    expect(list, isNotNull);
    assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.parameters[0].toSource(), 'io.File f');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_missingName() {
    FormalParameterList list = parseFormalParameterList('(io.File)',
        errors: [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1)]);
    expect(list, isNotNull);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    // TODO(danrubel): Investigate and improve recovery of parameter type/name.
    var parameter = list.parameters[0] as SimpleFormalParameter;
    expect(parameter.toSource(), 'io.File ');
    expect(parameter.name!.isSynthetic, isTrue);
    var type = parameter.type as NamedType;
    var typeName = type.name as PrefixedIdentifier;
    expect(typeName.prefix.token.isSynthetic, isFalse);
    expect(typeName.identifier.token.isSynthetic, isFalse);
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_partial() {
    FormalParameterList list = parseFormalParameterList('(io.)', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)
    ]);
    expect(list, isNotNull);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    // TODO(danrubel): Investigate and improve recovery of parameter type/name.
    var parameter = list.parameters[0] as SimpleFormalParameter;
    expect(parameter.toSource(), 'io. ');
    expect(parameter.name!.isSynthetic, isTrue);
    var type = parameter.type as NamedType;
    var typeName = type.name as PrefixedIdentifier;
    expect(typeName.prefix.token.isSynthetic, isFalse);
    expect(typeName.identifier.token.isSynthetic, isTrue);
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_partial2() {
    FormalParameterList list = parseFormalParameterList('(io.,a)', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 4, 1)
    ]);
    expect(list, isNotNull);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(2));
    expect(list.parameters[0].toSource(), 'io. ');
    expect(list.parameters[1].toSource(), 'a');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseNormalFormalParameter_field_const_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('const this.a',
        errorCodes: [ParserErrorCode.EXTRANEOUS_MODIFIER]);
    expect(parameter, isNotNull);
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_const_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter(
        'const A this.a',
        errorCodes: [ParserErrorCode.EXTRANEOUS_MODIFIER]);
    expect(parameter, isNotNull);
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_noType() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('final this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_type() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('final A this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_function_nested() {
    NormalFormalParameter parameter = parseNormalFormalParameter('this.a(B b)');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.name, isNotNull);
    FormalParameterList parameterList = fieldParameter.parameters!;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(1));
  }

  void test_parseNormalFormalParameter_field_function_noNested() {
    NormalFormalParameter parameter = parseNormalFormalParameter('this.a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.name, isNotNull);
    FormalParameterList parameterList = fieldParameter.parameters!;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void test_parseNormalFormalParameter_field_function_withDocComment() {
    var parameter = parseNormalFormalParameter('/// Doc\nthis.f()');
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  void test_parseNormalFormalParameter_field_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_var() {
    NormalFormalParameter parameter = parseNormalFormalParameter('var this.a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFieldFormalParameter);
    var fieldParameter = parameter as FieldFormalParameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.name, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_withDocComment() {
    var parameter = parseNormalFormalParameter('/// Doc\nthis.a');
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  void test_parseNormalFormalParameter_function_named() {
    ParameterKind kind = ParameterKind.NAMED;
    var defaultParameter =
        parseFormalParameter('a() : null', kind) as DefaultFormalParameter;
    var functionParameter =
        defaultParameter.parameter as FunctionTypedFormalParameter;
    assertNoErrors();
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.isNamed, isTrue);
    expect(functionParameter.question, isNull);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.isNamed, isTrue);
  }

  void test_parseNormalFormalParameter_function_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_noType_covariant() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('covariant a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.covariantKeyword, isNotNull);
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_noType_nullable() {
    var parameter = parseNNBDFormalParameter('a()?', ParameterKind.REQUIRED)
        as NormalFormalParameter;
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
    expect(functionParameter.endToken, functionParameter.question);
  }

  void test_parseNormalFormalParameter_function_noType_typeParameters() {
    NormalFormalParameter parameter = parseNormalFormalParameter('a<E>()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type_typeParameters() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A a<E>()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_typeVoid_covariant() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('covariant void a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.covariantKeyword, isNotNull);
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void() {
    NormalFormalParameter parameter = parseNormalFormalParameter('void a()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void_typeParameters() {
    NormalFormalParameter parameter = parseNormalFormalParameter('void a<E>()');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isFunctionTypedFormalParameter);
    var functionParameter = parameter as FunctionTypedFormalParameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.name, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void test_parseNormalFormalParameter_function_withDocComment() {
    var parameter = parseFormalParameter('/// Doc\nf()', ParameterKind.REQUIRED)
        as FunctionTypedFormalParameter;
    expectCommentText(parameter.documentationComment, '/// Doc');
  }

  void test_parseNormalFormalParameter_simple_const_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('const a',
        errorCodes: [ParserErrorCode.EXTRANEOUS_MODIFIER]);
    expect(parameter, isNotNull);
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.name, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_const_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('const A a',
        errorCodes: [ParserErrorCode.EXTRANEOUS_MODIFIER]);
    expect(parameter, isNotNull);
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.name, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('final a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.name, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('final A a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.name, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_noName() {
    NormalFormalParameter parameter =
        parseNormalFormalParameter('a', inFunctionType: true);
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.name, isNull);
  }

  void test_parseNormalFormalParameter_simple_noType() {
    NormalFormalParameter parameter = parseNormalFormalParameter('a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.name, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_noType_namedCovariant() {
    NormalFormalParameter parameter = parseNormalFormalParameter('covariant');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.covariantKeyword, isNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.name, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_type() {
    NormalFormalParameter parameter = parseNormalFormalParameter('A a');
    expect(parameter, isNotNull);
    assertNoErrors();
    expect(parameter, isSimpleFormalParameter);
    var simpleParameter = parameter as SimpleFormalParameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.name, isNotNull);
  }
}
