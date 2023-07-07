// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(
      Platform.script.resolve('../../../_fe_analyzer_shared/test/flow_analysis/'
          'why_not_promoted/data'));
  return runTests<String?>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const _WhyNotPromotedDataComputer(), [analyzerDefaultConfig]));
}

class _WhyNotPromotedDataComputer extends DataComputer<String?> {
  const _WhyNotPromotedDataComputer();

  @override
  DataInterpreter<String?> get dataValidator =>
      const _WhyNotPromotedDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String?>> actualMap) {
    var flowResult =
        testingData.uriToFlowAnalysisData[unit.declaredElement!.source.uri]!;
    _WhyNotPromotedDataExtractor(
            unit.declaredElement!.source.uri, actualMap, flowResult)
        .run(unit);
  }
}

class _WhyNotPromotedDataExtractor extends AstDataExtractor<String?> {
  final FlowAnalysisDataForTesting _flowResult;

  _WhyNotPromotedDataExtractor(super.uri, super.actualMap, this._flowResult);

  @override
  String? computeNodeValue(Id id, AstNode node) {
    String? nonPromotionReason = _flowResult.nonPromotionReasons[node];
    if (nonPromotionReason != null) {
      return 'notPromoted($nonPromotionReason)';
    }
    return _flowResult.nonPromotionReasonTargets[node];
  }
}

class _WhyNotPromotedDataInterpreter implements DataInterpreter<String?> {
  const _WhyNotPromotedDataInterpreter();

  @override
  String getText(String? actualData, [String? indentation]) =>
      actualData.toString();

  @override
  String? isAsExpected(String? actualData, String? expectedData) {
    if (actualData == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(String? actualData) => actualData == null;
}
