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

// Pattern matching GitHub issue URLs starting with the Flutter issue creation prefix.
// Delimiters (whitespace, quotes, backslashes, parentheses, brackets) define the URL boundary.
final RegExp _issueUrlPattern = RegExp(
  r'''https:\/\/github\.com\/flutter\/flutter\/issues\/new[^\s'"\\)>]*''',
);

const String _issueLinkPrefix = 'https://github.com/flutter/flutter/issues/new';

const Set<String> _validTemplates = <String>{
  '01_activation.yml',
  '02_bug.yml',
  '03_feature_request.yml',
  '04_performance_others.yml',
  '05_performance_speed.yml',
  '06_infrastructure.yml',
  '07_design_doc.yml',
  '08_first_party_packages.yml',
  '09_wasm.yml',
  '10_google3_bug.yml',
  'config.yml',
};

/// Links to create GitHub issues must specify a valid template or use "/choose".
class IssueLinkSyntax extends AnalysisRule {
  IssueLinkSyntax() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      'GitHub issue links must specify a valid template or use "/choose".';

  static const LintCode code = LintCode(
    'issue_link_syntax',
    'GitHub issue link must specify a valid template or use "/choose".',
    correctionMessage:
        'Prefer to provide a link either to https://github.com/flutter/flutter/issues/new/choose '
        'or to a specific template directly (https://github.com/flutter/flutter/issues/new?template=...).',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path;
    if (filePath.endsWith('_test.dart') || filePath.endsWith('issue_link_syntax.dart')) {
      return;
    }
    final visitor = _Visitor(this);
    registry
      ..addAdjacentStrings(this, visitor)
      ..addCompilationUnit(this, visitor)
      ..addSimpleStringLiteral(this, visitor)
      ..addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  static bool _isValidIssueUrl(String url) {
    if (url == _issueLinkPrefix) {
      return false;
    }
    if (url == '$_issueLinkPrefix/choose') {
      return true;
    }
    if (url.startsWith('$_issueLinkPrefix?')) {
      final Uri? parsedUrl = Uri.tryParse(url);
      if (parsedUrl == null) {
        return false;
      }
      final List<String>? templates = parsedUrl.queryParametersAll['template'];
      if (templates == null || templates.length != 1) {
        return false;
      }
      if (!_validTemplates.contains(templates.single)) {
        return false;
      }
      if (parsedUrl.queryParametersAll.keys.length > 1) {
        return false;
      }
      return true;
    }
    return false;
  }

  static bool _hasInvalidIssueLink(String text) {
    for (final RegExpMatch match in _issueUrlPattern.allMatches(text)) {
      final String url = match[0]!;
      if (!_isValidIssueUrl(url)) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // In the Dart analyzer AST, non-doc comments (`// ...`) are not represented
    // as Comment AST nodes; they are attached to lexical tokens as precedingComments.
    // We walk the token stream from beginToken to ensure all comments are inspected.
    Token? token = node.beginToken;
    while (token != null) {
      Token? comment = token.precedingComments;
      while (comment != null) {
        if (_hasInvalidIssueLink(comment.lexeme)) {
          rule.reportAtToken(comment);
        }
        comment = comment.next;
      }
      if (token.isEof) {
        break;
      }
      token = token.next;
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // Ignore children of AdjacentStrings to avoid double-reporting;
    // visitAdjacentStrings inspects the full concatenated literal.
    if (node.parent is AdjacentStrings) {
      return;
    }
    if (_hasInvalidIssueLink(node.value)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    // Ignore children of AdjacentStrings to avoid double-reporting.
    if (node.parent is AdjacentStrings) {
      return;
    }
    for (final InterpolationElement element in node.elements) {
      if (element is InterpolationString && _hasInvalidIssueLink(element.value)) {
        rule.reportAtNode(node);
        return;
      }
    }
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    final String? value = node.stringValue;
    if (value != null && _hasInvalidIssueLink(value)) {
      rule.reportAtNode(node);
    }
  }
}
