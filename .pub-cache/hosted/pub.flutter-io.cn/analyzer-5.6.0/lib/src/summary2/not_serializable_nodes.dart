// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';

FunctionExpressionImpl emptyFunctionExpression() {
  return FunctionExpressionImpl(
    typeParameters: null,
    parameters: FormalParameterListImpl(
      leftParenthesis: Tokens.openParenthesis(),
      parameters: [],
      leftDelimiter: null,
      rightDelimiter: null,
      rightParenthesis: Tokens.closeParenthesis(),
    ),
    body: BlockFunctionBodyImpl(
      keyword: null,
      star: null,
      block: BlockImpl(
        leftBracket: Tokens.openCurlyBracket(),
        statements: [],
        rightBracket: Tokens.closeCurlyBracket(),
      ),
    ),
  );
}

/// We cannot serialize [FunctionExpression], but we need to have some node
/// with the same source range for error reporting. So, we replace them with
/// empty [FunctionExpression]s that have the same offset and length.
ExpressionImpl replaceNotSerializableNodes(ExpressionImpl node) {
  if (node is FunctionExpressionImpl) {
    return FunctionExpressionReplacementVisitor._replacement(node);
  }
  node.accept(FunctionExpressionReplacementVisitor());
  return node;
}

class FunctionExpressionReplacementVisitor extends RecursiveAstVisitor<void> {
  @override
  void visitFunctionExpression(FunctionExpression node) {
    NodeReplacer.replace(node, _replacement(node));
  }

  static FunctionExpressionImpl _replacement(FunctionExpression from) {
    var to = emptyFunctionExpression();
    to.parameters?.leftParenthesis.offset = from.offset;

    var toBody = to.body;
    if (toBody is BlockFunctionBodyImpl) {
      toBody.block.rightBracket.offset = from.end - 1;
    }

    return to;
  }
}
