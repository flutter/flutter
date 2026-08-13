// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class DeprecationSyntax extends AnalysisRule {
  DeprecationSyntax() : super(name: code.name, description: 'Verify deprecation syntax');

  static const LintCode code = LintCode(
    'deprecation_syntax',
    'Deprecation syntax must conform to flutter standards.',
    correctionMessage: 'See https://github.com/flutter/flutter/blob/main/docs/contributing/Tree-hygiene.md#handling-breaking-changes',
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

  static final RegExp deprecationVersionPattern = RegExp(
    r'This feature was deprecated after v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?<build>-\d+\.\d+\.pre)?\.$',
  );

  bool _hasInlineIgnore(AstNode node, Pattern ignorePattern) {
    final lineInfo = context.currentUnit!.unit.lineInfo;
    final int lineStartOffset = lineInfo.getOffsetOfLine(
      lineInfo.getLocation(node.offset).lineNumber - 1,
    );
    final String content = context.currentUnit!.content;

    // Check if previous line has the comment
    int prevLineNum = lineInfo.getLocation(node.offset).lineNumber - 2;
    if (prevLineNum >= 0) {
      final int prevLineStart = lineInfo.getOffsetOfLine(prevLineNum);
      final String prevLine = content.substring(prevLineStart, lineStartOffset);
      if (prevLine.contains(ignorePattern)) return true;
    }

    // Check current line as well after node? (The analyze.dart implementation checked the previous line OR the same line but technically before the node or after).
    // Let's just check the string of the content on both the node line (before it) and the line before.
    // And also we can check precedingComments. But let's just do a string substring to match exactly what analyze.dart did for backward compatibility.
    // However, analyze.dart did: textAfterNode = content.substring(node.offset, lineInfo.getOffsetOfLineAfter(node.offset) - 1).
    // And it checked if textAfterNode.contains(ignorePattern) for the skipTest version.
    // But for Ignore directives, it checked `hasInlineIgnore` with the previous line logic! Wait, `hasInlineIgnore` implementation:
    // It checked `compilationUnit.content.substring(node.offset, offsetOfLineAfter(node.offset) - 1)`. Wait! That is the line of the node itself AFTER the node starts.
    return content
            .substring(node.offset, lineInfo.getOffsetOfLineAfter(node.offset) - 1)
            .contains(ignorePattern) ||
        (prevLineNum >= 0 &&
            content
                .substring(lineInfo.getOffsetOfLine(prevLineNum), lineStartOffset)
                .contains(ignorePattern));
  }

  @override
  void visitAnnotation(Annotation node) {
    final bool shouldCheckAnnotation =
        node.name.name == 'Deprecated' &&
        !_hasInlineIgnore(node, _ignoreDeprecation) &&
        !_hasInlineIgnore(node, _legacyDeprecation);
    if (!shouldCheckAnnotation) {
      return;
    }

    final NodeList<Expression>? arguments = node.arguments?.arguments;
    if (arguments == null || arguments.length != 1) {
      // Different lint message? The legacy one had specific messages. We can just use rule.reportAtNode(node) with custom message, but rule.reportAtNode uses LintCode. Let's just report the one lint code.
      // Wait, standard Lintcodes do NOT support dynamic messages for the same code.
      // But we can report it anyway.
      rule.reportAtNode(node);
      return;
    }

    final Expression deprecationNotice = arguments.first;
    if (deprecationNotice is! AdjacentStrings) {
      rule.reportAtNode(node);
      return;
    }

    final List<StringLiteral> strings = deprecationNotice.strings;
    if (strings.isEmpty) {
      rule.reportAtNode(node);
      return;
    }

    final List<StringLiteral> messageLiterals = strings.sublist(0, strings.length - 1);
    final StringLiteral versionLiteral = strings.last;

    // Verify version literal
    final RegExpMatch? versionMatch = versionLiteral is SimpleStringLiteral
        ? deprecationVersionPattern.firstMatch(versionLiteral.value)
        : null;
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
      if (message is! SingleStringLiteral) {
        rule.reportAtNode(message);
        return;
      }
      if (!message.isSingleQuoted) {
        rule.reportAtNode(message);
        return;
      }
    }

    final String fullExplanation = messageLiterals
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
  }
}
