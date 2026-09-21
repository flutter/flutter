// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../flutter_analysis_rule.dart';

extension _HasDebugPrefix on Token {
  bool get _isDebugOnlySymbol {
    final String lowerCased = lexeme.toLowerCase();
    return lowerCased.startsWith('debug') || lowerCased.startsWith('_debug');
  }
}

/// An [AnalysisRule] that verifies debug-only symbols (whose names start with
/// `debug`, `_debug`, `Debug`, or `_Debug`) are only accessed inside
/// `assert(...)` statements/initializers or inside another debug-only
/// declaration.
class AccessDebugOnlyInAssert extends FlutterAnalysisRule {
  AccessDebugOnlyInAssert()
    : super(name: code.name, description: 'No debug-only symbol access in production code.');

  static const LintCode code = LintCode(
    'access_debug_only_in_assert',
    '{0} accessed outside of an assert.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _AccessDebugOnlyInAssertVisitor(this));
  }
}

class _AccessDebugOnlyInAssertVisitor extends GeneralizingAstVisitor<void> {
  _AccessDebugOnlyInAssertVisitor(this.rule);

  final AnalysisRule rule;

  // Accessing debug symbols in asserts (either in the condition or in the message)
  // is always allowed.
  @override
  void visitAssertInitializer(AssertInitializer node) {}
  @override
  void visitAssertStatement(AssertStatement node) {}

  // We don't care about directives, comments, or metadata annotations.
  @override
  void visitDirective(Directive node) {}
  @override
  void visitComment(Comment node) {}
  @override
  void visitAnnotation(Annotation node) {}

  // This rule also ignores parameter names. This prevents the rule from flagging certain
  // constructor declarations such as `LabeledGlobalKey(this._debugLabel);`
  // Accessing the _debugLabel field will still get flagged which is intended.
  @override
  void visitFormalParameterList(FormalParameterList node) {}

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.variables.every((VariableDeclaration v) => v.name._isDebugOnlySymbol)) {
      return;
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitDeclaration(Declaration node) {
    final bool isDebugDeclaration = switch (node) {
      ClassDeclaration(:final namePart) ||
      EnumDeclaration(:final namePart) ||
      ExtensionTypeDeclaration(:final namePart) => namePart.typeName._isDebugOnlySymbol,
      MixinDeclaration(:final name) ||
      FunctionDeclaration(:final name) ||
      TypeAlias(:final name) ||
      MethodDeclaration(:final name) ||
      VariableDeclaration(:final name) ||
      EnumConstantDeclaration(:final name) ||
      DeclaredIdentifier(:final name) ||
      TypeParameter(:final name) => name._isDebugOnlySymbol,
      ExtensionDeclaration(:final name) ||
      ConstructorDeclaration(:final name) => name?._isDebugOnlySymbol ?? false,
      // Every FieldDeclaration and TopLevelVariableDeclaration node must have a VariableDeclarationList child.
      FieldDeclaration() || TopLevelVariableDeclaration() || PrimaryConstructorBody() => false,
      _ => throw UnimplementedError('Unhandled Declaration subtype: ${node.runtimeType}'),
    };
    if (isDebugDeclaration) {
      return;
    }
    super.visitDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.name._isDebugOnlySymbol) {
      rule.reportAtToken(node.name, arguments: <Object>[node.name.lexeme]);
    }
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.token._isDebugOnlySymbol) {
      rule.reportAtNode(node, arguments: <Object>[node.name]);
    }
  }
}
