// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: prefer_final_locals, always_put_control_body_on_new_line, specify_nonobvious_local_variable_types, unused_local_variable
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoSyncAsyncStar extends AnalysisRule {
  NoSyncAsyncStar()
    : super(
        name: code.name,
        description: 'Verify that we do not use sync*/async* methods without an explanation.',
      );

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
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
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
    if (body.isGenerator) {
      if (!_hasExplanationComment(node)) {
        rule.reportAtNode(node);
      }
    }
  }

  bool _hasExplanationComment(AstNode node) {
    final lineInfo = context.currentUnit!.unit.lineInfo;
    final int lineStartOffset = lineInfo.getOffsetOfLine(
      lineInfo.getLocation(node.offset).lineNumber - 1,
    );
    

    // We can just check the string of the content on both the node line (before it) and the lines before,
    // actually, let's just use token precedingComments stream - it reads all previous comments accurately!
    Token? token = node.beginToken;
    Token? comment = token.precedingComments;
    while (comment != null) {
      if (_ignorePattern.hasMatch(comment.lexeme)) {
        return true;
      }
      comment = comment.next;
    }
    // As a fallback, check the previous comment on the parent's beginToken in case this node's token doesn't capture the doc comment cleanly
    Token? parentToken = node.parent?.beginToken;
    Token? parentComment = parentToken?.precedingComments;
    while (parentComment != null) {
      if (_ignorePattern.hasMatch(parentComment.lexeme)) {
        return true;
      }
      parentComment = parentComment.next;
    }
    return false;
  }
}
