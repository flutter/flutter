// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/record_type_builder.dart';
import 'package:analyzer/src/summary2/types_builder.dart';

/// Recursive visitor of [LinkedNode]s that resolves explicit type annotations
/// in outlines.  This includes resolving element references in identifiers
/// in type annotation, and setting [LinkedNodeType]s for corresponding type
/// annotation nodes.
///
/// Declarations that have type annotations, e.g. return types of methods, get
/// the corresponding type set (so, if there is an explicit type annotation,
/// the type is set, otherwise we keep it empty, so we will attempt to infer
/// it later).
class ReferenceResolver extends ThrowingAstVisitor<void> {
  final Linker linker;
  final TypeSystemImpl _typeSystem;
  final NodesToBuildType nodesToBuildType;

  /// Indicates whether the library is opted into NNBD.
  final bool isNNBD;

  Scope scope;

  ReferenceResolver(
    this.linker,
    this.nodesToBuildType,
    LibraryOrAugmentationElementImpl container,
  )   : _typeSystem = container.library.typeSystem,
        scope = container.scope,
        isNNBD = container.isNonNullableByDefault;

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as ClassElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.typeParameters?.accept(this);
    node.extendsClause?.accept(this);
    node.implementsClause?.accept(this);
    node.withClause?.accept(this);

    scope = InterfaceScope(scope, element);
    LinkingNodeContext(node, scope);

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    var outerScope = scope;

    var element = node.declaredElement as ClassElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);
    LinkingNodeContext(node, scope);

    node.typeParameters?.accept(this);
    node.superclass.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    LinkingNodeContext(node, scope);
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as ConstructorElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);
    LinkingNodeContext(node, scope);

    node.parameters.accept(this);

    scope = outerScope;
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as EnumElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.typeParameters?.accept(this);
    node.implementsClause?.accept(this);
    node.withClause?.accept(this);

    scope = InterfaceScope(scope, element);
    LinkingNodeContext(node, scope);

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {}

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as ExtensionElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.typeParameters?.accept(this);
    node.extendedType.accept(this);

    scope = ExtensionScope(scope, element);
    LinkingNodeContext(node, scope);

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    node.fields.accept(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var outerScope = scope;

    var element = node.declaredElement as FieldFormalParameterElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as ExecutableElementImpl;

    scope = TypeParameterScope(outerScope, element.typeParameters);
    LinkingNodeContext(node, scope);

    node.returnType?.accept(this);
    node.functionExpression.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    var outerScope = scope;

    var element = node.declaredElement as TypeAliasElementImpl;

    scope = TypeParameterScope(outerScope, element.typeParameters);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);

    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var outerScope = scope;

    var element = node.declaredElement as ParameterElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var nodeImpl = node as GenericFunctionTypeImpl;
    var outerScope = scope;

    var element = node.declaredElement as GenericFunctionTypeElementImpl;
    scope = TypeParameterScope(outerScope, element.typeParameters);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);

    var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
    var builder = FunctionTypeBuilder.of(isNNBD, nodeImpl, nullabilitySuffix);
    nodeImpl.type = builder;
    nodesToBuildType.addTypeBuilder(builder);

    scope = outerScope;
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var outerScope = scope;

    var element = node.declaredElement as TypeAliasElementImpl;

    scope = TypeParameterScope(outerScope, element.typeParameters);

    node.typeParameters?.accept(this);
    node.type.accept(this);
    nodesToBuildType.addDeclaration(node);

    var aliasedType = node.type;
    if (aliasedType is GenericFunctionTypeImpl) {
      element.encloseElement(
        aliasedType.declaredElement as GenericFunctionTypeElementImpl,
      );
    }

    scope = outerScope;
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as ExecutableElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);
    LinkingNodeContext(node, scope);

    node.returnType?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    var outerScope = scope;

    var element = node.declaredElement as MixinElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.typeParameters?.accept(this);
    node.onClause?.accept(this);
    node.implementsClause?.accept(this);

    scope = InterfaceScope(scope, element);
    LinkingNodeContext(node, scope);

    node.members.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitNamedType(covariant NamedTypeImpl node) {
    var typeIdentifier = node.name;

    Element? element;
    if (typeIdentifier is PrefixedIdentifierImpl) {
      var prefix = typeIdentifier.prefix;
      var prefixName = prefix.name;
      var prefixElement = scope.lookup(prefixName).getter;
      prefix.staticElement = prefixElement;

      if (prefixElement is PrefixElement) {
        var nameNode = typeIdentifier.identifier;
        var name = nameNode.name;

        element = prefixElement.scope.lookup(name).getter;
        nameNode.staticElement = element;
      }
    } else {
      var nameNode = typeIdentifier as SimpleIdentifierImpl;
      var name = nameNode.name;

      if (name == 'void') {
        node.type = VoidTypeImpl.instance;
        return;
      }

      element = scope.lookup(name).getter;
      nameNode.staticElement = element;
    }

    node.typeArguments?.accept(this);

    var nullabilitySuffix = _getNullabilitySuffix(node.question != null);
    if (element == null) {
      node.type = DynamicTypeImpl.instance;
    } else if (element is TypeParameterElement) {
      node.type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      var builder = NamedTypeBuilder.of(
        linker,
        _typeSystem,
        node,
        element,
        nullabilitySuffix,
      );
      node.type = builder;
      nodesToBuildType.addTypeBuilder(builder);
    }
  }

  @override
  void visitOnClause(OnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitRecordTypeAnnotation(covariant RecordTypeAnnotationImpl node) {
    node.positionalFields.accept(this);
    node.namedFields?.accept(this);

    final builder = RecordTypeBuilder.of(_typeSystem, node);
    node.type = builder;
    nodesToBuildType.addTypeBuilder(builder);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.fields.accept(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.type?.accept(this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    var outerScope = scope;

    var element = node.declaredElement as SuperFormalParameterElementImpl;

    scope = TypeParameterScope(scope, element.typeParameters);

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
    nodesToBuildType.addDeclaration(node);

    scope = outerScope;
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.accept(this);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    var bound = node.bound;
    if (bound != null) {
      bound.accept(this);
      var element = node.declaredElement as TypeParameterElementImpl;
      element.bound = bound.type;
    }
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    node.type?.accept(this);
    nodesToBuildType.addDeclaration(node);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes.accept(this);
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (isNNBD) {
      if (hasQuestion) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    } else {
      return NullabilitySuffix.star;
    }
  }
}
