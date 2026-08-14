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

// Pattern matching repository URLs from supported hosting domains.
// Delimiters (whitespace, quotes, backslashes, parentheses, brackets) define the URL boundary.
final RegExp _repoUrlPattern = RegExp(
  r'''https:\/\/(?:cs\.opensource\.google|github|raw\.githubusercontent|source\.chromium|([a-z0-9\-]+)\.googlesource)\.[^\s'"\\)>]+''',
);

// Repos whose default branch is still 'master'
const Set<String> _repoExceptions = <String>{
  'chromium/chromium',
  'clojure/clojure',
  'dart-lang/test', // TODO(guidezpl): remove when https://github.com/dart-lang/test/issues/2209 is closed
  'eseidelGoogle/bezier_perf',
  'flutter/devtools', // TODO(guidezpl): remove when https://github.com/flutter/devtools/issues/7551 is closed
  'flutter/platform_tests', // TODO(guidezpl): remove when subtask in https://github.com/flutter/flutter/issues/121564 is complete
  'flutter/web_installers',
  'glfw/glfw',
  'GoogleCloudPlatform/artifact-registry-maven-tools',
  'material-components/material-components-android', // TODO(guidezpl): remove when https://github.com/material-components/material-components-android/issues/4144 is closed
  'ninja-build/ninja',
  'torvalds/linux',
  'tpn/winsdk-10',
};

const String _bannedBranch = 'master';

/// Repository links must use the "main" branch rather than "master".
class RepositoryLinkSyntax extends AnalysisRule {
  RepositoryLinkSyntax() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      'Repository links must use the "main" branch rather than "master".';

  static const LintCode code = LintCode(
    'repository_link_syntax',
    'Repository link uses the banned "master" branch.',
    correctionMessage:
        'Use the "main" branch if it exists, otherwise add the repository to the list of exceptions.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry
      ..addAdjacentStrings(this, visitor)
      ..addCompilationUnit(this, visitor)
      ..addSimpleStringLiteral(this, visitor)
      ..addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static bool _hasBannedRepositoryLink(String text) {
    for (final RegExpMatch match in _repoUrlPattern.allMatches(text)) {
      final String url = match[0]!.replaceAll('\r', '');
      if (!_repoExceptions.any(url.contains) && url.contains(_bannedBranch)) {
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
        if (_hasBannedRepositoryLink(comment.lexeme)) {
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
    if (_hasBannedRepositoryLink(node.value)) {
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
      if (element is InterpolationString && _hasBannedRepositoryLink(element.value)) {
        rule.reportAtNode(node);
        return;
      }
    }
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    final String? value = node.stringValue;
    if (value != null && _hasBannedRepositoryLink(value)) {
      rule.reportAtNode(node);
    }
  }
}
