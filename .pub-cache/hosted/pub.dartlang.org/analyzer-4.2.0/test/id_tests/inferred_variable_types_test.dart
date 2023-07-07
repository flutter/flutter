// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(
      Platform.script.resolve('../../../_fe_analyzer_shared/test/inference/'
          'inferred_variable_types/data'));
  return runTests<DartType>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const _InferredVariableTypesDataComputer(), [analyzerDefaultConfig]));
}

class _InferredVariableTypesDataComputer extends DataComputer<DartType> {
  const _InferredVariableTypesDataComputer();

  @override
  DataInterpreter<DartType> get dataValidator =>
      const _InferredVariableTypesDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<DartType>> actualMap) {
    _InferredVariableTypesDataExtractor(
            unit.declaredElement!.source.uri, actualMap)
        .run(unit);
  }
}

class _InferredVariableTypesDataExtractor extends AstDataExtractor<DartType> {
  _InferredVariableTypesDataExtractor(super.uri, super.actualMap);

  @override
  DartType? computeNodeValue(Id id, AstNode node) {
    if (node is VariableDeclaration) {
      var element = node.declaredElement!;
      if (element.hasImplicitType) {
        return element.type;
      }
    } else if (node is FormalParameter) {
      var element = node.declaredElement!;
      if (element.hasImplicitType) {
        return element.type;
      }
    } else if (node is FunctionDeclarationStatement) {
      var element = node.functionDeclaration.declaredElement!;
      if (element.hasImplicitReturnType) {
        return element.returnType;
      }
    } else if (node is FunctionExpression &&
        node.parent is! FunctionDeclaration) {
      var element = node.declaredElement!;
      if (element.hasImplicitReturnType) {
        return element.returnType;
      }
    }
    return null;
  }
}

class _InferredVariableTypesDataInterpreter
    implements DataInterpreter<DartType> {
  const _InferredVariableTypesDataInterpreter();

  @override
  String getText(DartType actualData, [String? indentation]) {
    return actualData.getDisplayString(withNullability: true);
  }

  @override
  String? isAsExpected(DartType actualData, String? expectedData) {
    var actualDataText = getText(actualData);
    if (actualDataText == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualDataText';
    }
  }

  @override
  bool isEmpty(DartType? actualData) => actualData == null;
}
