// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Compute the set of external names referenced in the [unit].
Set<String> computeReferencedNames(CompilationUnit unit) {
  _ReferencedNamesComputer computer = _ReferencedNamesComputer();
  unit.accept(computer);
  return computer.names;
}

/// Compute the set of names which are used in `extends`, `with` or `implements`
/// clauses in the file. Import prefixes and type arguments are not included.
Set<String> computeSubtypedNames(CompilationUnit unit) {
  Set<String> subtypedNames = <String>{};

  void addSubtypedName(NamedType? type) {
    if (type != null) {
      Identifier name = type.name;
      if (name is SimpleIdentifier) {
        subtypedNames.add(name.name);
      } else if (name is PrefixedIdentifier) {
        subtypedNames.add(name.identifier.name);
      }
    }
  }

  void addSubtypedNames(List<NamedType>? types) {
    types?.forEach(addSubtypedName);
  }

  for (CompilationUnitMember declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      addSubtypedName(declaration.extendsClause?.superclass);
      addSubtypedNames(declaration.withClause?.mixinTypes);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is ClassTypeAlias) {
      addSubtypedName(declaration.superclass);
      addSubtypedNames(declaration.withClause.mixinTypes);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is EnumDeclaration) {
      addSubtypedNames(declaration.withClause?.mixinTypes);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    } else if (declaration is MixinDeclaration) {
      addSubtypedNames(declaration.onClause?.superclassConstraints);
      addSubtypedNames(declaration.implementsClause?.interfaces);
    }
  }

  return subtypedNames;
}

/// Chained set of local names, that hide corresponding external names.
class _LocalNameScope {
  final _LocalNameScope? enclosing;
  Set<String>? names;

  _LocalNameScope(this.enclosing);

  factory _LocalNameScope.forBlock(_LocalNameScope enclosing, Block node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    for (Statement statement in node.statements) {
      if (statement is FunctionDeclarationStatement) {
        scope.add(statement.functionDeclaration.name);
      } else if (statement is VariableDeclarationStatement) {
        scope.addVariableNames(statement.variables);
      }
    }
    return scope;
  }

  factory _LocalNameScope.forClass(
      _LocalNameScope enclosing, ClassDeclaration node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    for (ClassMember member in node.members) {
      if (member is FieldDeclaration) {
        scope.addVariableNames(member.fields);
      } else if (member is MethodDeclaration) {
        scope.add(member.name);
      }
    }
    return scope;
  }

  factory _LocalNameScope.forClassTypeAlias(
      _LocalNameScope enclosing, ClassTypeAlias node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    return scope;
  }

  factory _LocalNameScope.forConstructor(
      _LocalNameScope enclosing, ConstructorDeclaration node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addFormalParameters(node.parameters);
    return scope;
  }

  factory _LocalNameScope.forFunction(
      _LocalNameScope enclosing, FunctionDeclaration node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.functionExpression.typeParameters);
    scope.addFormalParameters(node.functionExpression.parameters);
    return scope;
  }

  factory _LocalNameScope.forFunctionTypeAlias(
      _LocalNameScope enclosing, FunctionTypeAlias node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    return scope;
  }

  factory _LocalNameScope.forMethod(
      _LocalNameScope enclosing, MethodDeclaration node) {
    _LocalNameScope scope = _LocalNameScope(enclosing);
    scope.addTypeParameters(node.typeParameters);
    scope.addFormalParameters(node.parameters);
    return scope;
  }

  factory _LocalNameScope.forUnit(CompilationUnit node) {
    _LocalNameScope scope = _LocalNameScope(null);
    for (CompilationUnitMember declaration in node.declarations) {
      if (declaration is NamedCompilationUnitMember) {
        scope.add(declaration.name);
      } else if (declaration is TopLevelVariableDeclaration) {
        scope.addVariableNames(declaration.variables);
      }
    }
    return scope;
  }

  void add(Token? token) {
    if (token != null) {
      (names ??= <String>{}).add(token.lexeme);
    }
  }

  void addFormalParameters(FormalParameterList? parameterList) {
    if (parameterList != null) {
      parameterList.parameters
          .map((p) => p is NormalFormalParameter ? p.name : null)
          .forEach(add);
    }
  }

  void addTypeParameters(TypeParameterList? typeParameterList) {
    if (typeParameterList != null) {
      typeParameterList.typeParameters.map((p) => p.name).forEach(add);
    }
  }

  void addVariableNames(VariableDeclarationList variableList) {
    for (VariableDeclaration variable in variableList.variables) {
      add(variable.name);
    }
  }

  bool contains(String name) {
    if (names != null && names!.contains(name)) {
      return true;
    }
    if (enclosing != null) {
      return enclosing!.contains(name);
    }
    return false;
  }
}

class _ReferencedNamesComputer extends GeneralizingAstVisitor<void> {
  final Set<String> names = <String>{};
  final Set<String> importPrefixNames = <String>{};

  _LocalNameScope localScope = _LocalNameScope(null);

  @override
  void visitBlock(Block node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forBlock(localScope, node);
      super.visitBlock(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forClass(localScope, node);
      super.visitClassDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forClassTypeAlias(localScope, node);
      super.visitClassTypeAlias(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    localScope = _LocalNameScope.forUnit(node);
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forConstructor(localScope, node);
      super.visitConstructorDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    if (node.parent is! ConstructorDeclaration) {
      super.visitConstructorName(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forFunction(localScope, node);
      super.visitFunctionDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forFunctionTypeAlias(localScope, node);
      super.visitFunctionTypeAlias(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var prefix = node.prefix;
    if (prefix != null) {
      importPrefixNames.add(prefix.name);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _LocalNameScope outerScope = localScope;
    try {
      localScope = _LocalNameScope.forMethod(localScope, node);
      super.visitMethodDeclaration(node);
    } finally {
      localScope = outerScope;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Ignore all declarations.
    if (node.inDeclarationContext()) {
      return;
    }
    // Ignore class names references from constructors.
    var parent = node.parent!;
    if (parent is ConstructorDeclaration && parent.returnType == node) {
      return;
    }
    // Prepare name.
    String name = node.name;
    // Ignore names shadowed by local elements.
    if (node.isQualified || _isNameExpressionLabel(parent)) {
      // Cannot be local.
    } else {
      if (localScope.contains(name)) {
        return;
      }
      if (importPrefixNames.contains(name)) {
        return;
      }
    }
    // Do add the name.
    names.add(name);
  }

  static bool _isNameExpressionLabel(AstNode parent) {
    if (parent is Label) {
      var parent2 = parent.parent;
      return parent2 is NamedExpression && parent2.name == parent;
    }
    return false;
  }
}
