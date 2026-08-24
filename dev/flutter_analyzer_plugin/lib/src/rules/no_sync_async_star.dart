// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_analysis_rule.dart';

/// A rule that enforces explanation comments for `sync*` and `async*` methods.
class NoSyncAsyncStar extends FlutterAnalysisRule {
  /// Creates a new [NoSyncAsyncStar] rule.
  NoSyncAsyncStar()
    : super(
        name: code.name,
        description: 'Verify that we do not use sync*/async* methods without an explanation.',
      );

  /// The diagnostic code produced when `sync*` or `async*` is used without an explanation.
  static const LintCode code = LintCode(
    'no_sync_async_star',
    'Do not use sync*/async* methods without an explanation comment.',
    correctionMessage:
        'See https://github.com/flutter/flutter/blob/main/docs/contributing/Style-guide-for-Flutter-repo.md#avoid-syncasync for details.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path.replaceAll(r'\', '/');
    if (!filePath.startsWith('/home/test') &&
        (!filePath.contains('/packages/') && !filePath.contains('/examples/'))) {
      return;
    }
    if (!filePath.startsWith('/home/test') &&
        (filePath.contains('/test/') ||
            filePath.endsWith('_test.dart') ||
            filePath.contains('flutter_test'))) {
      return;
    }
    final visitor = _Visitor(this, context);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;
  static final RegExp _ignorePattern = RegExp(r'^\s*?// The following uses a?sync\* because:? ');

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkFunctionBody(node.functionExpression.body, node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkFunctionBody(node.body, node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      _checkFunctionBody(node.body, node);
    }
  }

  void _checkFunctionBody(FunctionBody body, AstNode node) {
    if (body.isGenerator && !_hasExplanationComment(node, body)) {
      rule.reportAtNode(node);
    }
  }

  bool _hasExplanationComment(AstNode node, FunctionBody body) {
    bool hasMatch(Token? startToken) {
      for (
        Token? comment = startToken?.precedingComments;
        comment != null;
        comment = comment.next
      ) {
        if (_ignorePattern.hasMatch(comment.lexeme)) {
          return true;
        }
      }
      return false;
    }

    final Token firstToken =
        node is AnnotatedNode ? node.firstTokenAfterCommentAndMetadata : node.beginToken;

    for (
      Token? token = firstToken;
      token != null && token.offset <= body.beginToken.offset;
      token = token.next
    ) {
      if (hasMatch(token)) {
        return true;
      }
    }

    return hasMatch(node.beginToken) || hasMatch(node.parent?.beginToken);
  }
}
