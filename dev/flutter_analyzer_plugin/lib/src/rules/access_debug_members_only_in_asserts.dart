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
      switch (ancestor) {
        // We don't care about directives, comments, or metadata annotations.
        case Directive() || Comment() || Annotation():
        // Ignores parameter names and default values (since they must be const).
        // This prevents the rule from flagging certain constructor declarations such as `LabeledGlobalKey(this._debugLabel);`
        // Accessing the _debugLabel field will still get flagged which is intended.
        case FormalParameterList():
          return true;
        // This is the case where a variable declaration list's type is a DebugOnly type.
        // We enforce that all declared variables must have a debug prefix.
        case VariableDeclarationList(:final NodeList<VariableDeclaration> variables):
          return variables.every((VariableDeclaration v) => v.name._isDebugOnlySymbol);
        case ClassDeclaration(:final ClassNamePart namePart) ||
            EnumDeclaration(:final ClassNamePart namePart) ||
            ExtensionTypeDeclaration(:final ClassNamePart namePart):
          return namePart.typeName._isDebugOnlySymbol;
        case MixinDeclaration(:final Token name) ||
            TypeAlias(:final Token name) ||
            VariableDeclaration(:final Token name) ||
            EnumConstantDeclaration(:final Token name):
          return name._isDebugOnlySymbol;
        case ExtensionDeclaration() || FunctionDeclaration():
          return false;
        case DeclaredIdentifier(:final Token name) || TypeParameter(:final Token name):
          if (name._isDebugOnlySymbol) {
            return true;
          }
        // Every FieldDeclaration and TopLevelVariableDeclaration node must have a VariableDeclarationList child,
        // and non-debug class members defer to their enclosing type declaration.
        case FieldDeclaration() ||
            TopLevelVariableDeclaration() ||
            MethodDeclaration() ||
            ConstructorDeclaration() ||
            PrimaryConstructorBody():
          break;
        case Declaration():
          // The Declaration class isn't sealed. Throw a runtime error to indicate this rule
          // needs updating.
          throw UnimplementedError('Unhandled Declaration subtype: ${ancestor.runtimeType}');
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
