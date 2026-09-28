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

/// An [AnalysisRule] that verifies debug-only members / types (whose names start with
/// `debug`, `_debug`, `Debug`, or `_Debug`) are only accessed / referenced inside
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
    registry.addCompilationUnit(this, _AccessDebugMembersOnlyInAssertsVisitor(this));
  }
}

class _AccessDebugMembersOnlyInAssertsVisitor extends SimpleAstVisitor<void> {
  _AccessDebugMembersOnlyInAssertsVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.declarations.accept(_DebugMemberVisitor(rule));
  }
}

// The goal of this visitor is to catch debug-only member accesses (by checking SimpleIdentifiers),
// and references to debug-only types in signatures (by checking NamedTypes).
class _DebugMemberVisitor extends RecursiveAstVisitor<void> {
  _DebugMemberVisitor(this.rule);

  final AnalysisRule rule;

  // Asserts, annotations, and comments can't have violations.
  @override
  void visitAssertInitializer(AssertInitializer node) {}

  @override
  void visitAssertStatement(AssertStatement node) {}

  @override
  void visitAnnotation(Annotation node) {}

  @override
  void visitComment(Comment node) {}

  // Types declarations. These can't have violations if they are debug-only
  // themselves.
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.namePart.typeName._isDebugOnlySymbol) {
      return;
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (node.namePart.typeName._isDebugOnlySymbol) {
      return;
    }
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.namePart.typeName._isDebugOnlySymbol) {
      return;
    }
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitMixinDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitClassTypeAlias(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitTypeParameter(node);
  }

  // Executable declarations (constructors, functions, and methods).
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name?._isDebugOnlySymbol ?? false) {
      return;
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitMethodDeclaration(node);
  }

  // Variable and enum constant declarations.
  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.variables.every((VariableDeclaration v) => v.name._isDebugOnlySymbol)) {
      return;
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (node.name._isDebugOnlySymbol) {
      return;
    }
    super.visitEnumConstantDeclaration(node);
  }

  // These 2 visitor methods are only called for nodes in non-debug-only context,
  // where debug-only references are illegal.
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
    super.visitSimpleIdentifier(node);
  }
}
