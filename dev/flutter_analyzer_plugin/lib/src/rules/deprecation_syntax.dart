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

/// A rule that enforces standard Flutter deprecation notice syntax.
class DeprecationSyntax extends AnalysisRule {
  /// Creates a new [DeprecationSyntax] rule.
  DeprecationSyntax() : super(name: code.name, description: 'Verify deprecation syntax');

  /// The diagnostic code produced when deprecation syntax does not conform to Flutter standards.
  static const LintCode code = LintCode(
    'deprecation_syntax',
    'Deprecation syntax must conform to flutter standards.',
    correctionMessage:
        'See https://github.com/flutter/flutter/blob/main/docs/contributing/Tree-hygiene.md#handling-breaking-changes',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addAnnotation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static const String _ignoreDeprecation =
      '// flutter_ignore: deprecation_syntax (see analyze.dart)';
  static final RegExp _legacyDeprecation = RegExp(
    r'// flutter_ignore: deprecation_syntax, https://github\.com/flutter/flutter/issues/\d+',
  );

  static final RegExp _deprecationVersionPattern = RegExp(
    r'This feature was deprecated after v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?<build>-\d+\.\d+\.pre)?\.$',
  );

  bool _hasInlineIgnore(AstNode node, Pattern ignorePattern) {
    final LineInfo lineInfo = context.currentUnit!.unit.lineInfo;
    final int lineIndex = lineInfo.getLocation(node.offset).lineNumber - 1;
    final String content = context.currentUnit!.content;

    // Check preceding line.
    if (lineIndex > 0) {
      final String prevLine = content.substring(
        lineInfo.getOffsetOfLine(lineIndex - 1),
        lineInfo.getOffsetOfLine(lineIndex),
      );
      if (prevLine.contains(ignorePattern)) {
        return true;
      }
    }

    // Check the remainder of the current line.
    final int currentLineEnd =
        lineIndex + 1 < lineInfo.lineCount
            ? lineInfo.getOffsetOfLine(lineIndex + 1)
            : content.length;
    final String textAfterNode = content.substring(node.offset, currentLineEnd);
    return textAfterNode.contains(ignorePattern);
  }

  @override
  void visitAnnotation(Annotation node) {
    if (node.name.name != 'Deprecated') {
      return;
    }
    if (_hasInlineIgnore(node, _ignoreDeprecation) || _hasInlineIgnore(node, _legacyDeprecation)) {
      return;
    }

    if (node.arguments?.arguments case [
      AdjacentStrings(:final List<StringLiteral> strings),
    ] when strings.isNotEmpty) {
      final List<StringLiteral> messageLiterals = strings.sublist(0, strings.length - 1);
      final StringLiteral versionLiteral = strings.last;

      final RegExpMatch? versionMatch = switch (versionLiteral) {
        SimpleStringLiteral(:final String value) => _deprecationVersionPattern.firstMatch(value),
        _ => null,
      };
      if (versionMatch == null) {
        rule.reportAtNode(versionLiteral);
        return;
      }

      final int major = int.parse(versionMatch.namedGroup('major')!);
      final int minor = int.parse(versionMatch.namedGroup('minor')!);
      final int patch = int.parse(versionMatch.namedGroup('patch')!);
      final hasBuild = versionMatch.namedGroup('build') != null;
      final bool specialBeta = major == 3 && minor == 1 && patch == 0;
      if (!specialBeta && (major > 1 || (major == 1 && minor >= 20))) {
        if (!hasBuild) {
          rule.reportAtNode(versionLiteral);
          return;
        }
      }

      if (messageLiterals.isEmpty) {
        rule.reportAtNode(node);
        return;
      }

      for (final message in messageLiterals) {
        if (message case SingleStringLiteral(isSingleQuoted: true)) {
          continue;
        }
        rule.reportAtNode(message);
        return;
      }

      final String fullExplanation =
          messageLiterals
              .map((StringLiteral message) => message.stringValue ?? '')
              .join()
              .trimRight();
      if (fullExplanation.isEmpty) {
        rule.reportAtNode(messageLiterals.last);
        return;
      }

      final firstChar = String.fromCharCode(fullExplanation.runes.first);
      if (firstChar.toUpperCase() != firstChar) {
        rule.reportAtNode(messageLiterals.first);
        return;
      }

      if (!fullExplanation.endsWith('.') &&
          !fullExplanation.endsWith('?') &&
          !fullExplanation.endsWith('!')) {
        rule.reportAtNode(messageLiterals.last);
        return;
      }
    } else {
      rule.reportAtNode(node);
    }
  }
}
