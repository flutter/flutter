// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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
  Directory dataDir = Directory.fromUri(Platform.script.resolve(
      '../../../_fe_analyzer_shared/test/flow_analysis/reachability/data'));
  return runTests<Set<_ReachabilityAssertion>>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const _ReachabilityDataComputer(), [analyzerDefaultConfig]));
}

enum _ReachabilityAssertion {
  doesNotComplete,
  unreachable,
}

class _ReachabilityDataComputer
    extends DataComputer<Set<_ReachabilityAssertion>> {
  const _ReachabilityDataComputer();

  @override
  DataInterpreter<Set<_ReachabilityAssertion>> get dataValidator =>
      const _ReachabilityDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<Set<_ReachabilityAssertion>>> actualMap) {
    var unitElement = unit.declaredElement!;
    var flowResult = testingData.uriToFlowAnalysisData[unitElement.source.uri]!;
    _ReachabilityDataExtractor(unitElement.source.uri, actualMap, flowResult)
        .run(unit);
  }
}

class _ReachabilityDataExtractor
    extends AstDataExtractor<Set<_ReachabilityAssertion>> {
  final FlowAnalysisDataForTesting _flowResult;

  _ReachabilityDataExtractor(super.uri, super.actualMap, this._flowResult);

  @override
  Set<_ReachabilityAssertion>? computeNodeValue(Id id, AstNode node) {
    Set<_ReachabilityAssertion> result = {};
    if (node is Expression && node.parent is ExpressionStatement) {
      // The reachability of an expression statement and the statement it
      // contains should always be the same.  We check this with an assert
      // statement, and only annotate the expression statement, to reduce the
      // amount of redundancy in the test files.
      assert(_flowResult.unreachableNodes.contains(node) ==
          _flowResult.unreachableNodes.contains(node.parent));
    } else if (_flowResult.unreachableNodes.contains(node)) {
      result.add(_ReachabilityAssertion.unreachable);
    }
    if (node is FunctionDeclaration) {
      _checkBodyCompletion(node.functionExpression.body, result);
    } else if (node is ConstructorDeclaration) {
      _checkBodyCompletion(node.body, result);
    } else if (node is MethodDeclaration) {
      _checkBodyCompletion(node.body, result);
    }
    return result.isEmpty ? null : result;
  }

  void _checkBodyCompletion(
      FunctionBody? body, Set<_ReachabilityAssertion> result) {
    if (body != null &&
        _flowResult.functionBodiesThatDontComplete.contains(body)) {
      result.add(_ReachabilityAssertion.doesNotComplete);
    }
  }
}

class _ReachabilityDataInterpreter
    implements DataInterpreter<Set<_ReachabilityAssertion>> {
  const _ReachabilityDataInterpreter();

  @override
  String getText(Set<_ReachabilityAssertion> actualData,
          [String? indentation]) =>
      _sortedRepresentation(_toStrings(actualData));

  @override
  String? isAsExpected(
      Set<_ReachabilityAssertion> actualData, String? expectedData) {
    var actualStrings = _toStrings(actualData);
    var actualSorted = _sortedRepresentation(actualStrings);
    var expectedSorted = _sortedRepresentation(expectedData?.split(','));
    if (actualSorted == expectedSorted) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualSorted';
    }
  }

  @override
  bool isEmpty(Set<_ReachabilityAssertion> actualData) => actualData.isEmpty;

  String _sortedRepresentation(Iterable<String>? values) {
    var list = values == null || values.isEmpty ? ['none'] : values.toList();
    list.sort();
    return list.join(',');
  }

  List<String> _toStrings(Set<_ReachabilityAssertion> actualData) => actualData
      .map((flowAssertion) => flowAssertion.toString().split('.')[1])
      .toList();
}
