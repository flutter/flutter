// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types, omit_obvious_local_variable_types, always_put_control_body_on_new_line, sort_constructors_first, inference_failure_on_function_return_type, directives_ordering
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final Pattern _skipTestIntentionalPattern = RegExp(r'// .*\[intended\]');
final Pattern _skipTestTrackingBugPattern = RegExp(
  r'// .*https+?://github.com/.*/issues/\d+',
);

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

  bool _hasInlineIgnore(
    AstNode node,
    Pattern ignoreDirectivePattern,
  ) {
    final compilationUnit = context.currentUnit!;
    final lineInfo = compilationUnit.unit.lineInfo;

    final String textAfterNode = compilationUnit.content.substring(
      node.offset,
      lineInfo.getOffsetOfLineAfter(node.offset) - 1,
    );
    if (textAfterNode.contains(ignoreDirectivePattern)) {
      return true;
    }

    final int lineNumber = lineInfo.getLocation(node.offset).lineNumber - 1;
    if (lineNumber <= 0) {
      return false;
    }
    return compilationUnit.content
        .substring(lineInfo.getOffsetOfLine(lineNumber - 1), lineInfo.getOffsetOfLine(lineNumber))
        .trimLeft()
        .contains(ignoreDirectivePattern);
  }

  bool _hasValidJustificationComment(AstNode skipLabel) {
    return _hasInlineIgnore(skipLabel, _skipTestIntentionalPattern) ||
           _hasInlineIgnore(skipLabel, _skipTestTrackingBugPattern);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!context.currentUnit!.file.path.endsWith('_test.dart')) {
      return;
    }

    if (_isTestMethod(node.methodName.name)) {
      for (final Expression argument in node.argumentList.arguments) {
        if (argument is NamedExpression &&
            argument.name.label.name == 'skip' &&
            !_hasValidJustificationComment(argument.name.label)) {
          rule.reportAtNode(argument);
        }
      }
    }
  }
}
