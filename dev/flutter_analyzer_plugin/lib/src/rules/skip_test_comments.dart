// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';

final Pattern _skipTestIntentionalPattern = RegExp(r'// .*\[intended\]');
final Pattern _skipTestTrackingBugPattern = RegExp(r'// .*https?://github.com/.*/issues/\d+');

/// Skipped tests should have a justification comment.
class SkipTestComments extends AnalysisRule {
  SkipTestComments() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      'Skipped tests must have a justification comment, such as a tracking bug link or "[intended]".';

  static const LintCode code = LintCode(
    'skip_test_comments',
    ruleDescription,
    correctionMessage: 'Add a comment with a GitHub issue link or "[intended]".',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path;
    // Skip test comments rule only applies to test files.
    if (!filePath.startsWith('/home/test') && !filePath.endsWith('_test.dart')) {
      return;
    }
    final visitor = _Visitor(this, context);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static bool _isTestMethod(String name) {
    return name.startsWith('test') || name == 'group' || name == 'expect';
  }

  static bool _isNonSkippingExpression(Expression expr) {
    return expr is SimpleIdentifier || (expr is BooleanLiteral && !expr.value);
  }

  bool _hasInlineIgnore(NamedArgument argument, Pattern ignoreDirectivePattern) {
    final RuleContextUnit compilationUnit = context.currentUnit!;
    final LineInfo lineInfo = compilationUnit.unit.lineInfo;
    final int startLine = lineInfo.getLocation(argument.offset).lineNumber;
    final int endLine = lineInfo.getLocation(argument.end).lineNumber;
    final String content = compilationUnit.content;

    final int scanStartLine = (startLine - 1).clamp(1, lineInfo.lineCount);
    final int scanStartOffset = lineInfo.getOffsetOfLine(scanStartLine - 1);
    final int scanEndOffset =
        endLine < lineInfo.lineCount ? lineInfo.getOffsetOfLine(endLine) : content.length;

    final String text = content.substring(scanStartOffset, scanEndOffset);
    return text.contains(ignoreDirectivePattern);
  }

  bool _hasValidJustificationComment(NamedArgument argument) {
    return _hasInlineIgnore(argument, _skipTestIntentionalPattern) ||
        _hasInlineIgnore(argument, _skipTestTrackingBugPattern);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isTestMethod(node.methodName.name)) {
      for (final Argument argument in node.argumentList.arguments) {
        if (argument is NamedArgument &&
            argument.name.lexeme == 'skip' &&
            !_isNonSkippingExpression(argument.argumentExpression) &&
            !_hasValidJustificationComment(argument)) {
          rule.reportAtNode(argument);
        }
      }
    }
  }
}
