// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';

class FindNode {
  final String content;
  final CompilationUnit unit;

  FindNode(this.content, this.unit);

  LibraryDirective get libraryDirective {
    return unit.directives.singleWhere((d) => d is LibraryDirective)
        as LibraryDirective;
  }

  List<MethodInvocation> get methodInvocations {
    var result = <MethodInvocation>[];
    unit.accept(
      FunctionAstVisitor(
        methodInvocation: result.add,
      ),
    );
    return result;
  }

  AdjacentStrings adjacentStrings(String search) {
    return _node(search, (n) => n is AdjacentStrings);
  }

  Annotation annotation(String search) {
    return _node(search, (n) => n is Annotation);
  }

  AstNode any(String search) {
    return _node(search, (n) => true);
  }

  ArgumentList argumentList(String search) {
    return _node(search, (n) => n is ArgumentList);
  }

  AsExpression as_(String search) {
    return _node(search, (n) => n is AsExpression);
  }

  AssertStatement assertStatement(String search) {
    return _node(search, (n) => n is AssertStatement);
  }

  AssignmentExpression assignment(String search) {
    return _node(search, (n) => n is AssignmentExpression);
  }

  AwaitExpression awaitExpression(String search) {
    return _node(search, (n) => n is AwaitExpression);
  }

  BinaryExpression binary(String search) {
    return _node(search, (n) => n is BinaryExpression);
  }

  Block block(String search) {
    return _node(search, (n) => n is Block);
  }

  BlockFunctionBody blockFunctionBody(String search) {
    return _node(search, (n) => n is BlockFunctionBody);
  }

  BooleanLiteral booleanLiteral(String search) {
    return _node(search, (n) => n is BooleanLiteral);
  }

  BreakStatement breakStatement(String search) {
    return _node(search, (n) => n is BreakStatement);
  }

  CascadeExpression cascade(String search) {
    return _node(search, (n) => n is CascadeExpression);
  }

  CatchClause catchClause(String search) {
    return _node(search, (n) => n is CatchClause);
  }

  ClassDeclaration classDeclaration(String search) {
    return _node(search, (n) => n is ClassDeclaration);
  }

  ClassTypeAlias classTypeAlias(String search) {
    return _node(search, (n) => n is ClassTypeAlias);
  }

  CollectionElement collectionElement(String search) {
    return _node(search, (n) => n is CollectionElement);
  }

  Comment comment(String search) {
    return _node(search, (n) => n is Comment);
  }

  CommentReference commentReference(String search) {
    return _node(search, (n) => n is CommentReference);
  }

  ConditionalExpression conditionalExpression(String search) {
    return _node(search, (n) => n is ConditionalExpression);
  }

  ConstructorDeclaration constructor(String search) {
    return _node(search, (n) => n is ConstructorDeclaration);
  }

  ConstructorFieldInitializer constructorFieldInitializer(String search) {
    return _node(search, (n) => n is ConstructorFieldInitializer);
  }

  ConstructorName constructorName(String search) {
    return _node(search, (n) => n is ConstructorName);
  }

  ConstructorReference constructorReference(String search) {
    return _node(search, (n) => n is ConstructorReference);
  }

  ConstructorSelector constructorSelector(String search) {
    return _node(search, (n) => n is ConstructorSelector);
  }

  ContinueStatement continueStatement(String search) {
    return _node(search, (n) => n is ContinueStatement);
  }

  DeclaredIdentifier declaredIdentifier(String search) {
    return _node(search, (n) => n is DeclaredIdentifier);
  }

  DefaultFormalParameter defaultParameter(String search) {
    return _node(search, (n) => n is DefaultFormalParameter);
  }

  DoStatement doStatement(String search) {
    return _node(search, (n) => n is DoStatement);
  }

  DoubleLiteral doubleLiteral(String search) {
    return _node(search, (n) => n is DoubleLiteral);
  }

  EnumConstantDeclaration enumConstantDeclaration(String search) {
    return _node(search, (n) => n is EnumConstantDeclaration);
  }

  EnumDeclaration enumDeclaration(String search) {
    return _node(search, (n) => n is EnumDeclaration);
  }

  ExportDirective export(String search) {
    return _node(search, (n) => n is ExportDirective);
  }

  Expression expression(String search) {
    return _node(search, (n) => n is Expression);
  }

  ExpressionFunctionBody expressionFunctionBody(String search) {
    return _node(search, (n) => n is ExpressionFunctionBody);
  }

  ExpressionStatement expressionStatement(String search) {
    return _node(search, (n) => n is ExpressionStatement);
  }

  ExtendsClause extendsClause(String search) {
    return _node(search, (n) => n is ExtendsClause);
  }

  ExtensionDeclaration extensionDeclaration(String search) {
    return _node(search, (n) => n is ExtensionDeclaration);
  }

  ExtensionOverride extensionOverride(String search) {
    return _node(search, (n) => n is ExtensionOverride);
  }

  FieldDeclaration fieldDeclaration(String search) {
    return _node(search, (n) => n is FieldDeclaration);
  }

  FieldFormalParameter fieldFormalParameter(String search) {
    return _node(search, (n) => n is FieldFormalParameter);
  }

  ForEachPartsWithDeclaration forEachPartsWithDeclaration(String search) {
    return _node(search, (n) => n is ForEachPartsWithDeclaration);
  }

  ForEachPartsWithIdentifier forEachPartsWithIdentifier(String search) {
    return _node(search, (n) => n is ForEachPartsWithIdentifier);
  }

  FormalParameterList formalParameterList(String search) {
    return _node(search, (n) => n is FormalParameterList);
  }

  ForPartsWithDeclarations forPartsWithDeclarations(String search) {
    return _node(search, (n) => n is ForPartsWithDeclarations);
  }

  ForPartsWithExpression forPartsWithExpression(String search) {
    return _node(search, (n) => n is ForPartsWithExpression);
  }

  ForStatement forStatement(String search) {
    return _node(search, (n) => n is ForStatement);
  }

  FunctionBody functionBody(String search) {
    return _node(search, (n) => n is FunctionBody);
  }

  FunctionDeclaration functionDeclaration(String search) {
    return _node(search, (n) => n is FunctionDeclaration);
  }

  FunctionDeclarationStatement functionDeclarationStatement(String search) {
    return _node(search, (n) => n is FunctionDeclarationStatement);
  }

  FunctionExpression functionExpression(String search) {
    return _node(search, (n) => n is FunctionExpression);
  }

  FunctionExpressionInvocation functionExpressionInvocation(String search) {
    return _node(search, (n) => n is FunctionExpressionInvocation);
  }

  FunctionReference functionReference(String search) {
    return _node(search, (n) => n is FunctionReference);
  }

  FunctionTypeAlias functionTypeAlias(String search) {
    return _node(search, (n) => n is FunctionTypeAlias);
  }

  FunctionTypedFormalParameter functionTypedFormalParameter(String search) {
    return _node(search, (n) => n is FunctionTypedFormalParameter);
  }

  GenericFunctionType genericFunctionType(String search) {
    return _node(search, (n) => n is GenericFunctionType);
  }

  GenericTypeAlias genericTypeAlias(String search) {
    return _node(search, (n) => n is GenericTypeAlias);
  }

  HideCombinator hideCombinator(String search) {
    return _node(search, (n) => n is HideCombinator);
  }

  IfElement ifElement(String search) {
    return _node(search, (n) => n is IfElement);
  }

  IfStatement ifStatement(String search) {
    return _node(search, (n) => n is IfStatement);
  }

  ImplementsClause implementsClause(String search) {
    return _node(search, (n) => n is ImplementsClause);
  }

  ImplicitCallReference implicitCallReference(String search) {
    return _node(search, (n) => n is ImplicitCallReference);
  }

  ImportDirective import(String search) {
    return _node(search, (n) => n is ImportDirective);
  }

  IndexExpression index(String search) {
    return _node(search, (n) => n is IndexExpression);
  }

  InstanceCreationExpression instanceCreation(String search) {
    return _node(search, (n) => n is InstanceCreationExpression);
  }

  IntegerLiteral integerLiteral(String search) {
    return _node(search, (n) => n is IntegerLiteral);
  }

  InterpolationExpression interpolationExpression(String search) {
    return _node(search, (n) => n is InterpolationExpression);
  }

  IsExpression isExpression(String search) {
    return _node(search, (n) => n is IsExpression);
  }

  Label label(String search) {
    return _node(search, (n) => n is Label);
  }

  LabeledStatement labeledStatement(String search) {
    return _node(search, (n) => n is LabeledStatement);
  }

  LibraryDirective library(String search) {
    return _node(search, (n) => n is LibraryDirective);
  }

  LibraryAugmentationDirective libraryAugmentation(String search) {
    return _node(search, (n) => n is LibraryAugmentationDirective);
  }

  LibraryIdentifier libraryIdentifier(String search) {
    return _node(search, (n) => n is LibraryIdentifier);
  }

  ListLiteral listLiteral(String search) {
    return _node(search, (n) => n is ListLiteral);
  }

  MapLiteralEntry mapLiteralEntry(String search) {
    return _node(search, (n) => n is MapLiteralEntry);
  }

  MethodDeclaration methodDeclaration(String search) {
    return _node(search, (n) => n is MethodDeclaration);
  }

  MethodInvocation methodInvocation(String search) {
    return _node(search, (n) => n is MethodInvocation);
  }

  MixinDeclaration mixin(String search) {
    return _node(search, (n) => n is MixinDeclaration);
  }

  MixinDeclaration mixinDeclaration(String search) {
    return _node(search, (n) => n is MixinDeclaration);
  }

  NamedExpression namedExpression(String search) {
    return _node(search, (n) => n is NamedExpression);
  }

  NamedType namedType(String search) {
    return _node(search, (n) => n is NamedType);
  }

  NativeClause nativeClause(String search) {
    return _node(search, (n) => n is NativeClause);
  }

  NativeFunctionBody nativeFunctionBody(String search) {
    return _node(search, (n) => n is NativeFunctionBody);
  }

  NullLiteral nullLiteral(String search) {
    return _node(search, (n) => n is NullLiteral);
  }

  /// Return the unique offset where the [search] string occurs in [content].
  /// Throws if not found, or if not unique.
  int offset(String search) {
    var offset = content.indexOf(search);
    if (content.contains(search, offset + 1)) {
      throw StateError('The pattern |$search| is not unique in:\n$content');
    }
    if (offset < 0) {
      throw StateError('The pattern |$search| is not found in:\n$content');
    }
    return offset;
  }

  ParenthesizedExpression parenthesized(String search) {
    return _node(search, (n) => n is ParenthesizedExpression);
  }

  PartDirective part(String search) {
    return _node(search, (n) => n is PartDirective);
  }

  PartOfDirective partOf(String search) {
    return _node(search, (n) => n is PartOfDirective);
  }

  PostfixExpression postfix(String search) {
    return _node(search, (n) => n is PostfixExpression);
  }

  PrefixExpression prefix(String search) {
    return _node(search, (n) => n is PrefixExpression);
  }

  PrefixedIdentifier prefixed(String search) {
    return _node(search, (n) => n is PrefixedIdentifier);
  }

  PropertyAccess propertyAccess(String search) {
    return _node(search, (n) => n is PropertyAccess);
  }

  RedirectingConstructorInvocation redirectingConstructorInvocation(
      String search) {
    return _node(search, (n) => n is RedirectingConstructorInvocation);
  }

  RethrowExpression rethrow_(String search) {
    return _node(search, (n) => n is RethrowExpression);
  }

  ReturnStatement returnStatement(String search) {
    return _node(search, (n) => n is ReturnStatement);
  }

  SetOrMapLiteral setOrMapLiteral(String search) {
    return _node(search, (n) => n is SetOrMapLiteral);
  }

  ShowCombinator showCombinator(String search) {
    return _node(search, (n) => n is ShowCombinator);
  }

  SimpleIdentifier simple(String search) {
    return _node(search, (_) => true);
  }

  SimpleFormalParameter simpleFormalParameter(String search) {
    return _node(search, (n) => n is SimpleFormalParameter);
  }

  SimpleFormalParameter simpleParameter(String search) {
    return _node(search, (n) => n is SimpleFormalParameter);
  }

  Statement statement(String search) {
    return _node(search, (n) => n is Statement);
  }

  StringInterpolation stringInterpolation(String search) {
    return _node(search, (n) => n is StringInterpolation);
  }

  StringLiteral stringLiteral(String search) {
    return _node(search, (n) => n is StringLiteral);
  }

  SuperExpression super_(String search) {
    return _node(search, (n) => n is SuperExpression);
  }

  SuperConstructorInvocation superConstructorInvocation(String search) {
    return _node(search, (n) => n is SuperConstructorInvocation);
  }

  SuperFormalParameter superFormalParameter(String search) {
    return _node(search, (n) => n is SuperFormalParameter);
  }

  SwitchCase switchCase(String search) {
    return _node(search, (n) => n is SwitchCase);
  }

  SwitchDefault switchDefault(String search) {
    return _node(search, (n) => n is SwitchDefault);
  }

  SwitchStatement switchStatement(String search) {
    return _node(search, (n) => n is SwitchStatement);
  }

  SymbolLiteral symbolLiteral(String search) {
    return _node(search, (n) => n is SymbolLiteral);
  }

  ThisExpression this_(String search) {
    return _node(search, (n) => n is ThisExpression);
  }

  ThrowExpression throw_(String search) {
    return _node(search, (n) => n is ThrowExpression);
  }

  TopLevelVariableDeclaration topLevelVariableDeclaration(String search) {
    return _node(search, (n) => n is TopLevelVariableDeclaration);
  }

  VariableDeclaration topVariableDeclarationByName(String name) {
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    throw StateError(name);
  }

  TryStatement tryStatement(String search) {
    return _node(search, (n) => n is TryStatement);
  }

  TypeAnnotation typeAnnotation(String search) {
    return _node(search, (n) => n is TypeAnnotation);
  }

  TypeArgumentList typeArgumentList(String search) {
    return _node(search, (n) => n is TypeArgumentList);
  }

  TypedLiteral typedLiteral(String search) {
    return _node(search, (n) => n is TypedLiteral);
  }

  TypeLiteral typeLiteral(String search) {
    return _node(search, (n) => n is TypeLiteral);
  }

  TypeParameter typeParameter(String search) {
    return _node(search, (n) => n is TypeParameter);
  }

  TypeParameterList typeParameterList(String search) {
    return _node(search, (n) => n is TypeParameterList);
  }

  VariableDeclaration variableDeclaration(String search) {
    return _node(search, (n) => n is VariableDeclaration);
  }

  VariableDeclarationList variableDeclarationList(String search) {
    return _node(search, (n) => n is VariableDeclarationList);
  }

  VariableDeclarationStatement variableDeclarationStatement(String search) {
    return _node(search, (n) => n is VariableDeclarationStatement);
  }

  WhileStatement whileStatement(String search) {
    return _node(search, (n) => n is WhileStatement);
  }

  WithClause withClause(String search) {
    return _node(search, (n) => n is WithClause);
  }

  YieldStatement yieldStatement(String search) {
    return _node(search, (n) => n is YieldStatement);
  }

  T _node<T>(String search, bool Function(AstNode) predicate) {
    int offset = this.offset(search);

    var node = NodeLocator2(offset).searchWithin(unit);
    if (node == null) {
      throw StateError(
          'The pattern |$search| had no corresponding node in:\n$content');
    }

    var result = node.thisOrAncestorMatching(predicate);
    if (result == null) {
      throw StateError(
          'The node for |$search| had no matching ancestor in:\n$content\n$unit');
    }
    return result as T;
  }
}
