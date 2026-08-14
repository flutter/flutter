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

const Set<String> _stops = <String>{'\n', ' ', "'", '"', r'\', ')', '>'};

final RegExp _repoPattern = RegExp(
  r'^(https:\/\/(?:cs\.opensource\.google|github|raw\.githubusercontent|source\.chromium|([a-z0-9\-]+)\.googlesource)\.)',
);

// Repos whose default branch is still 'master'
const Set<String> _repoExceptions = <String>{
  'chromium/chromium',
  'clojure/clojure',
  'dart-lang/test', // TODO(guidezpl): remove when https://github.com/dart-lang/test/issues/2209 is closed
  'eseidelGoogle/bezier_perf',
  'flutter/devtools', // TODO(guidezpl): remove when https://github.com/flutter/devtools/issues/7551 is closed
  'flutter/flutter-intellij', // TODO(guidezpl): remove when https://github.com/flutter/flutter-intellij/issues/7342 is closed
  'flutter/platform_tests', // TODO(guidezpl): remove when subtask in https://github.com/flutter/flutter/issues/121564 is complete
  'flutter/web_installers',
  'glfw/glfw',
  'GoogleCloudPlatform/artifact-registry-maven-tools',
  'material-components/material-components-android', // TODO(guidezpl): remove when https://github.com/material-components/material-components-android/issues/4144 is closed
  'ninja-build/ninja',
  'torvalds/linux',
  'tpn/winsdk-10',
};

const String _httpsPrefix = 'https://';
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
    var start = 0;
    while ((start = text.indexOf(_httpsPrefix, start)) >= 0) {
      int end = start + _httpsPrefix.length;
      while (end < text.length && !_stops.contains(text[end])) {
        end += 1;
      }
      final String url = text.substring(start, end).replaceAll('\r', '');

      if (_repoPattern.hasMatch(url) && !_repoExceptions.any(url.contains)) {
        if (url.contains(_bannedBranch)) {
          return true;
        }
      }
      start = end;
    }
    return false;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
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
    if (node.parent is AdjacentStrings) {
      return;
    }
    if (_hasBannedRepositoryLink(node.value)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
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
