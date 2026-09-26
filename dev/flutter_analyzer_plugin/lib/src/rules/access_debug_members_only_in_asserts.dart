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
    final String name = lexeme;
    final searchStartIndex = name.startsWith('_') ? 1 : 0;
    return name.startsWith('debug', searchStartIndex) || name.startsWith('Debug', searchStartIndex);
  }
}

/// An [AnalysisRule] that verifies debug-only symbols (whose names start with
/// `debug`, `_debug`, `Debug`, or `_Debug`) are only accessed inside
/// `assert(...)` statements/initializers or inside another debug-only
/// declaration.
class AccessDebugMembersOnlyInAsserts extends FlutterAnalysisRule {
  AccessDebugMembersOnlyInAsserts()
    : super(name: code.name, description: 'No debug-only symbol access in production code.');

  static const LintCode code = LintCode(
    'access_debug_members_only_in_asserts',
    '{0} accessed outside of an assert.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerCustomNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _AccessDebugMembersOnlyInAssertsVisitor(this);
    registry
      ..addCompilationUnit(this, visitor)
      ..addAssertInitializer(this, visitor)
      ..addAssertStatement(this, visitor)
      ..addConstructorDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor)
      ..addNamedType(this, visitor)
      ..addSimpleIdentifier(this, visitor);
  }
}

// The goal of this visitor is to catch debug-only member accesses, as well as
// references to debug-only types in signatures.
class _AccessDebugMembersOnlyInAssertsVisitor extends SimpleAstVisitor<void> {
  _AccessDebugMembersOnlyInAssertsVisitor(this.rule);

  final AnalysisRule rule;

  // The end offset of the most recently entered exempt scope (an assert or a
  // debug-only function, method, or constructor declaration) in the current
  // compilation unit.
  //
  // Because `RuleVisitorRegistry` only notifies visitors when entering a node
  // (and not when exiting), `_exemptEndOffset` is not reset when traversal gets
  // out of the node. Instead, we check whether a visited node's `offset` is
  // before `_exemptEndOffset` (and only update `_exemptEndOffset` when a new
  // exempt node ends after the current one, so nested nodes do not shrink the
  // range).
  int _exemptEndOffset = -1;

  bool _isInExemptScope(AstNode node) => node.offset < _exemptEndOffset;

  void _recordExemptScope(AstNode node) {
    if (node.end > _exemptEndOffset) {
      _exemptEndOffset = node.end;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _exemptEndOffset = -1;
  }

  @override
  void visitAssertInitializer(AssertInitializer node) => _recordExemptScope(node);
  @override
  void visitAssertStatement(AssertStatement node) => _recordExemptScope(node);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name?._isDebugOnlySymbol ?? false) {
      _recordExemptScope(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      _recordExemptScope(node);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      _recordExemptScope(node);
    }
  }

  static bool _isAllowedDebugAccess(AstNode node) {
    for (AstNode? ancestor = node.parent; ancestor != null; ancestor = ancestor.parent) {
      final bool isExempt = switch (ancestor) {
        // We don't care about directives, comments, or metadata annotations.
        Directive() || Comment() || Annotation() => true,
        // When a variable declaration list's type is a debug-only type, all
        // declared variables must have a debug prefix.
        VariableDeclarationList(:final NodeList<VariableDeclaration> variables) => variables.every(
          (VariableDeclaration v) => v.name._isDebugOnlySymbol,
        ),
        // A debug-only concrete type can access debug-only members and types.
        ClassDeclaration(:final ClassNamePart namePart) ||
        EnumDeclaration(:final ClassNamePart namePart) ||
        ExtensionTypeDeclaration(
          :final ClassNamePart namePart,
        ) => namePart.typeName._isDebugOnlySymbol,
        MixinDeclaration(:final Token name) ||
        TypeAlias(:final Token name) ||
        VariableDeclaration(:final Token name) ||
        EnumConstantDeclaration(:final Token name) ||
        // Explicitly prevents debug-only type references in type parameters,
        // as those can be phantom types.
        TypeParameter(:final Token name) => name._isDebugOnlySymbol,
        _ => false,
      };
      if (isExempt) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitNamedType(NamedType node) {
    if (!_isInExemptScope(node) && node.name._isDebugOnlySymbol && !_isAllowedDebugAccess(node)) {
      rule.reportAtToken(node.name, arguments: <Object>[node.name.lexeme]);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_isInExemptScope(node) &&
        node.token._isDebugOnlySymbol &&
        !node.inDeclarationContext() &&
        !_isAllowedDebugAccess(node)) {
      rule.reportAtNode(node, arguments: <Object>[node.name]);
    }
  }
}
