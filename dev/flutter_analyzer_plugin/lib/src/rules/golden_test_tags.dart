// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_analysis_rule.dart';

const String _matchesGoldenFile = 'matchesGoldenFile';
const String _reducedTestSetTag = 'reduced-test-set';
const String _tagsAnnotation = 'Tags';

/// Files containing golden tests must be tagged using `@Tags(<String>['reduced-test-set'])`.
class GoldenTestTags extends FlutterAnalysisRule {
  GoldenTestTags() : super(name: code.name, description: ruleDescription);

  static const String ruleDescription =
      "Files containing golden tests must be tagged using @Tags(<String>['reduced-test-set']) "
      'at the top of the file before import statements.';

  static const LintCode code = LintCode(
    'golden_test_tags',
    ruleDescription,
    correctionMessage:
        'See https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md for details.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final String filePath = context.definingUnit.file.path.replaceAll(r'\', '/');
    // Only golden tests in packages/flutter (or test runner) are subject to reduced testing tags.
    if (!filePath.contains('packages/flutter/test') && !filePath.contains('/home/test')) {
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

  bool? _hasReducedTestSetTagCache;

  bool _isReducedTestSetTag(Annotation annotation) {
    final String name = switch (annotation.name) {
      SimpleIdentifier(:final String name) => name,
      PrefixedIdentifier(:final SimpleIdentifier identifier) => identifier.name,
    };
    if (name != _tagsAnnotation) {
      return false;
    }
    final ArgumentList? argumentList = annotation.arguments;
    if (argumentList == null) {
      return false;
    }
    for (final Argument argument in argumentList.arguments) {
      final Expression? expr = switch (argument) {
        NamedArgument(:final Expression argumentExpression) => argumentExpression,
        final Expression expression => expression,
        _ => null,
      };
      if (expr == null) {
        continue;
      }
      if (expr case StringLiteral(
        :final String? stringValue,
      ) when stringValue == _reducedTestSetTag) {
        return true;
      }
      if (expr
          case ListLiteral(:final NodeList<CollectionElement> elements) ||
              SetOrMapLiteral(:final NodeList<CollectionElement> elements)) {
        for (final element in elements) {
          if (element case StringLiteral(
            :final String? stringValue,
          ) when stringValue == _reducedTestSetTag) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _hasReducedTestSetTag(CompilationUnit unit) {
    return _hasReducedTestSetTagCache ??= _computeHasReducedTestSetTag(unit);
  }

  bool _computeHasReducedTestSetTag(CompilationUnit unit) {
    for (final Directive directive in unit.directives) {
      for (final Annotation annotation in directive.metadata) {
        if (_isReducedTestSetTag(annotation)) {
          return true;
        }
      }
    }
    for (final CompilationUnitMember declaration in unit.declarations) {
      for (final Annotation annotation in declaration.metadata) {
        if (_isReducedTestSetTag(annotation)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != _matchesGoldenFile) {
      return;
    }

    final CompilationUnit unit = context.currentUnit!.unit;
    if (!_hasReducedTestSetTag(unit)) {
      rule.reportAtNode(node);
    }
  }
}
