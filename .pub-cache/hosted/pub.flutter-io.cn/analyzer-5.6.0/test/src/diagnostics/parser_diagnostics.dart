// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';

import '../../generated/test_support.dart';
import '../../util/feature_sets.dart';
import '../dart/resolution/node_text_expectations.dart';
import '../summary/resolved_ast_printer.dart';

class ParserDiagnosticsTest {
  /// TODO(scheglov) Enable [withCheckingLinking] everywhere.
  void assertParsedNodeText(
    AstNode node,
    String expected, {
    bool withCheckingLinking = false,
    bool withOffsets = false,
  }) {
    var actual = _parsedNodeText(
      node,
      withCheckingLinking: withCheckingLinking,
      withOffsets: withOffsets,
    );
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  ExpectedError error(
    ErrorCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages = const [],
  }) {
    return ExpectedError(
      code,
      offset,
      length,
      correctionContains: correctionContains,
      message: text,
      messageContains: messageContains,
      expectedContextMessages: contextMessages,
    );
  }

  ParseStringResult parseStringWithErrors(String content) {
    return parseString(
      content: content,
      featureSet: FeatureSets.latestWithExperiments,
      throwIfDiagnostics: false,
    );
  }

  String _parsedNodeText(
    AstNode node, {
    required bool withCheckingLinking,
    required bool withOffsets,
  }) {
    var buffer = StringBuffer();
    node.accept(
      ResolvedAstPrinter(
        selfUriStr: null,
        sink: buffer,
        indent: '',
        withCheckingLinking: withCheckingLinking,
        withResolution: false,
        withOffsets: withOffsets,
      ),
    );
    return buffer.toString();
  }
}

extension ParseStringResultExtension on ParseStringResult {
  FindNode get findNode {
    return FindNode(content, unit);
  }

  void assertErrors(List<ExpectedError> expectedErrors) {
    var errorListener = GatheringErrorListener();
    errorListener.addAll(errors);
    errorListener.assertErrors(expectedErrors);
  }

  void assertNoErrors() {
    assertErrors(const []);
  }
}
