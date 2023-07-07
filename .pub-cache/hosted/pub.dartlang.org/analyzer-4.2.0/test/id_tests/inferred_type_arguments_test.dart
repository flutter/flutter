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
          'inferred_type_arguments/data'));
  return runTests<List<DartType>>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const _InferredTypeArgumentsDataComputer(), [analyzerDefaultConfig]));
}

class _InferredTypeArgumentsDataComputer extends DataComputer<List<DartType>> {
  const _InferredTypeArgumentsDataComputer();

  @override
  DataInterpreter<List<DartType>> get dataValidator =>
      const _InferredTypeArgumentsDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<List<DartType>>> actualMap) {
    _InferredTypeArgumentsDataExtractor(
            unit.declaredElement!.source.uri, actualMap)
        .run(unit);
  }
}

class _InferredTypeArgumentsDataExtractor
    extends AstDataExtractor<List<DartType>> {
  _InferredTypeArgumentsDataExtractor(super.uri, super.actualMap);

  @override
  List<DartType>? computeNodeValue(Id id, AstNode node) {
    TypeArgumentList? typeArguments;
    List<DartType> typeArgumentTypes;
    if (node is InstanceCreationExpression) {
      typeArguments = node.constructorName.type.typeArguments;
      typeArgumentTypes =
          (node.constructorName.type.type as InterfaceType).typeArguments;
    } else if (node is InvocationExpression) {
      typeArguments = node.typeArguments;
      typeArgumentTypes = node.typeArgumentTypes!;
    } else if (node is TypedLiteral) {
      typeArguments = node.typeArguments;
      typeArgumentTypes = (node.staticType as InterfaceType).typeArguments;
    } else {
      return null;
    }
    if (typeArguments == null && typeArgumentTypes.isNotEmpty) {
      return typeArgumentTypes;
    }
    return null;
  }
}

class _InferredTypeArgumentsDataInterpreter
    implements DataInterpreter<List<DartType>> {
  const _InferredTypeArgumentsDataInterpreter();

  @override
  String getText(List<DartType> actualData, [String? indentation]) {
    StringBuffer sb = StringBuffer();
    if (actualData.isNotEmpty) {
      sb.write('<');
      for (int i = 0; i < actualData.length; i++) {
        if (i > 0) {
          sb.write(',');
        }
        sb.write(actualData[i].getDisplayString(withNullability: true));
      }
      sb.write('>');
    }
    return sb.toString();
  }

  @override
  String? isAsExpected(List<DartType> actualData, String? expectedData) {
    var actualDataText = getText(actualData);
    if (actualDataText == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualDataText';
    }
  }

  @override
  bool isEmpty(List<DartType>? actualData) =>
      actualData == null || actualData.isEmpty;
}
