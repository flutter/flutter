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

  bool _hasInlineIgnore(int offset, Pattern ignoreDirectivePattern) {
    final RuleContextUnit compilationUnit = context.currentUnit!;
    final LineInfo lineInfo = compilationUnit.unit.lineInfo;
    final int lineNumber = lineInfo.getLocation(offset).lineNumber;
    final String content = compilationUnit.content;

    final int endOffset =
        lineNumber < lineInfo.lineCount ? lineInfo.getOffsetOfLine(lineNumber) : content.length;
    final String textAfterNode = content.substring(offset, endOffset);
    if (textAfterNode.contains(ignoreDirectivePattern)) {
      return true;
    }

    final int previousLineNumber = lineNumber - 1;
    if (previousLineNumber <= 0) {
      return false;
    }
    return content
        .substring(
          lineInfo.getOffsetOfLine(previousLineNumber - 1),
          lineInfo.getOffsetOfLine(previousLineNumber),
        )
        .trimLeft()
        .contains(ignoreDirectivePattern);
  }

  bool _hasValidJustificationComment(int offset) {
    return _hasInlineIgnore(offset, _skipTestIntentionalPattern) ||
        _hasInlineIgnore(offset, _skipTestTrackingBugPattern);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isTestMethod(node.methodName.name)) {
      for (final Argument argument in node.argumentList.arguments) {
        if (argument is NamedArgument &&
            argument.name.lexeme == 'skip' &&
            !_hasValidJustificationComment(argument.name.offset)) {
          rule.reportAtNode(argument);
        }
      }
    }
  }
}
