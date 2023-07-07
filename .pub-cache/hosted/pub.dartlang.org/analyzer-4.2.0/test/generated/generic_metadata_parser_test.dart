// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/feature_sets.dart';
import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericMetadataEnabledParserTest);
    defineReflectiveTests(GenericMetadataDisabledParserTest);
  });
}

@reflectiveTest
class GenericMetadataDisabledParserTest extends FastaParserTestCase
    with GenericMetadataParserTest {
  @override
  CompilationUnit _parseCompilationUnit(String content,
      {List<ExpectedError>? errors, required ExpectedError? disabledError}) {
    var combinedErrors =
        disabledError == null ? errors : [disabledError, ...?errors];
    return parseCompilationUnit(
      content,
      errors: combinedErrors,
      featureSet: FeatureSets.language_2_12,
    );
  }
}

@reflectiveTest
class GenericMetadataEnabledParserTest extends FastaParserTestCase
    with GenericMetadataParserTest {
  @override
  CompilationUnit _parseCompilationUnit(String content,
          {List<ExpectedError>? errors,
          required ExpectedError? disabledError}) =>
      parseCompilationUnit(content, errors: errors);
}

mixin GenericMetadataParserTest on FastaParserTestCase {
  void test_className_prefixed_constructorName_absent() {
    var compilationUnit = _parseCompilationUnit('@p.A<B>() class C {}',
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 1));
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as PrefixedIdentifier;
    expect(className.prefix.name, 'p');
    expect(className.identifier.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    var typeArgumentName = typeArgument.name as SimpleIdentifier;
    expect(typeArgumentName.name, 'B');
    expect(annotation.constructorName, isNull);
  }

  void test_className_prefixed_constructorName_present() {
    var compilationUnit = _parseCompilationUnit('@p.A<B>.ctor() class C {}',
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 1));
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as PrefixedIdentifier;
    expect(className.prefix.name, 'p');
    expect(className.identifier.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    var typeArgumentName = typeArgument.name as SimpleIdentifier;
    expect(typeArgumentName.name, 'B');
    expect(annotation.constructorName!.name, 'ctor');
  }

  void test_className_unprefixed_constructorName_absent() {
    var compilationUnit = _parseCompilationUnit('@A<B>() class C {}',
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 2, 1));
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as SimpleIdentifier;
    expect(className.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    var typeArgumentName = typeArgument.name as SimpleIdentifier;
    expect(typeArgumentName.name, 'B');
    expect(annotation.constructorName, isNull);
  }

  void test_className_unprefixed_constructorName_present() {
    var compilationUnit = _parseCompilationUnit('@A<B>.ctor() class C {}',
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 2, 1));
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as SimpleIdentifier;
    expect(className.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    var typeArgumentName = typeArgument.name as SimpleIdentifier;
    expect(typeArgumentName.name, 'B');
    expect(annotation.constructorName!.name, 'ctor');
  }

  void test_reference_prefixed() {
    var compilationUnit = _parseCompilationUnit('@p.x<A> class C {}',
        errors: [
          expectedError(
              ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED,
              6,
              1),
        ],
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 4, 1));
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var name = annotation.name as PrefixedIdentifier;
    expect(name.prefix.name, 'p');
    expect(name.identifier.name, 'x');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    var typeArgumentName = typeArgument.name as SimpleIdentifier;
    expect(typeArgumentName.name, 'A');
    expect(annotation.constructorName, isNull);
  }

  void test_reference_unprefixed() {
    var compilationUnit = _parseCompilationUnit('@x<A> class C {}',
        errors: [
          expectedError(
              ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED,
              4,
              1),
        ],
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 2, 1));
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var name = annotation.name as SimpleIdentifier;
    expect(name.name, 'x');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    var typeArgumentName = typeArgument.name as SimpleIdentifier;
    expect(typeArgumentName.name, 'A');
    expect(annotation.constructorName, isNull);
  }

  test_typeArguments_after_constructorName() {
    _parseCompilationUnit('@p.A.ctor<B>() class C {}',
        errors: [
          expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 9, 1),
          expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 10, 1),
          expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
          expectedError(ParserErrorCode.TOP_LEVEL_OPERATOR, 11, 1),
          expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 15, 5),
        ],
        disabledError: null);
  }

  test_typeArguments_after_prefix() {
    _parseCompilationUnit('@p<A>.B.ctor() class C {}',
        errors: [
          expectedError(
              ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED,
              6,
              1),
          expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 7, 1),
          expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 15, 5),
        ],
        disabledError:
            expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 2, 1));
  }

  CompilationUnit _parseCompilationUnit(String content,
      {List<ExpectedError>? errors, required ExpectedError? disabledError});
}
