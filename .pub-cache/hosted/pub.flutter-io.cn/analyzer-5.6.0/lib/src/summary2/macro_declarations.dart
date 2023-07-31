// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

class ClassDeclarationImpl extends macro.ClassDeclarationImpl {
  late final ClassElement element;

  ClassDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.typeParameters,
    required super.interfaces,
    required super.isAbstract,
    required super.isExternal,
    required super.mixins,
    required super.superclass,
  });
}

class DeclarationBuilder {
  final DeclarationBuilderFromNode fromNode = DeclarationBuilderFromNode();

  final DeclarationBuilderFromElement fromElement =
      DeclarationBuilderFromElement();

  /// Associate declarations that were previously created for nodes with the
  /// corresponding elements. So, we can access them uniformly via interfaces,
  /// mixins, etc.
  void transferToElements() {
    // TODO(scheglov) Make sure that these are only declarations?
    for (final entry in fromNode._referencedIdentifierMap.entries) {
      final element = entry.key.staticElement;
      if (element != null) {
        final declaration = entry.value;
        fromElement._identifierMap[element] = declaration;
      }
    }
    for (final entry in fromNode._declaredIdentifierMap.entries) {
      final element = entry.key;
      final declaration = entry.value;
      fromElement._identifierMap[element] = declaration;
    }

    for (final entry in fromNode._classMap.entries) {
      final element = entry.key.declaredElement!;
      final declaration = entry.value;
      declaration.element = element;
      fromElement._classMap[element] = declaration;
    }
  }
}

class DeclarationBuilderFromElement {
  final Map<Element, IdentifierImpl> _identifierMap = Map.identity();

  final Map<ClassElement, IntrospectableClassDeclarationImpl> _classMap =
      Map.identity();

  final Map<FieldElement, FieldDeclarationImpl> _fieldMap = Map.identity();

  final Map<TypeParameterElement, macro.TypeParameterDeclarationImpl>
      _typeParameterMap = Map.identity();

  macro.IntrospectableClassDeclarationImpl classElement(ClassElement element) {
    return _classMap[element] ??= _introspectableClassElement(element);
  }

  macro.FieldDeclarationImpl fieldElement(FieldElement element) {
    return _fieldMap[element] ??= _fieldElement(element);
  }

  macro.IdentifierImpl identifier(Element element) {
    return _identifierMap[element] ??= IdentifierImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      name: element.name!,
      element: element,
    );
  }

  macro.TypeParameterDeclarationImpl typeParameter(
    TypeParameterElement element,
  ) {
    return _typeParameterMap[element] ??= _typeParameter(element);
  }

  macro.TypeAnnotationImpl _dartType(DartType type) {
    if (type is InterfaceType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        identifier: identifier(type.element),
        typeArguments: type.typeArguments.map(_dartType).toList(),
      );
    } else if (type is TypeParameterType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        identifier: identifier(type.element),
        typeArguments: const [],
      );
    } else {
      // TODO(scheglov) other types
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  FieldDeclarationImpl _fieldElement(FieldElement element) {
    assert(!_fieldMap.containsKey(element));
    final enclosingClass = element.enclosingElement as ClassElement;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      isExternal: element.isExternal,
      isFinal: element.isFinal,
      isLate: element.isLate,
      type: _dartType(element.type),
      definingClass: identifier(enclosingClass),
      isStatic: element.isStatic,
    );
  }

  IntrospectableClassDeclarationImpl _introspectableClassElement(
      ClassElement element) {
    assert(!_classMap.containsKey(element));
    return IntrospectableClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      interfaces: element.interfaces
          .map(_dartType)
          .cast<macro.NamedTypeAnnotationImpl>()
          .toList(),
      isAbstract: element.isAbstract,
      isExternal: false,
      mixins: element.mixins
          .map(_dartType)
          .cast<macro.NamedTypeAnnotationImpl>()
          .toList(),
      superclass: element.supertype.mapOrNull(_dartType)
          as macro.NamedTypeAnnotationImpl?,
    )..element = element;
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    TypeParameterElement element,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      bound: element.bound.mapOrNull(_dartType),
    );
  }
}

class DeclarationBuilderFromNode {
  final Map<ast.SimpleIdentifier, IdentifierImpl> _referencedIdentifierMap =
      Map.identity();

  final Map<Element, IdentifierImpl> _declaredIdentifierMap = Map.identity();

  final Map<ast.ClassDeclaration, IntrospectableClassDeclarationImpl>
      _classMap = Map.identity();

  macro.ClassDeclarationImpl classDeclaration(
    ast.ClassDeclaration node,
  ) {
    return _classMap[node] ??= _introspectableClassDeclaration(node);
  }

  macro.IdentifierImpl _declaredIdentifier(Token name, Element element) {
    return _declaredIdentifierMap[element] ??= _DeclaredIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name.lexeme,
      element: element,
    );
  }

  macro.FunctionTypeParameterImpl _formalParameter(
    ast.FormalParameter node,
  ) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotation(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FunctionTypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      name: node.name?.lexeme,
      type: typeAnnotation,
    );
  }

  IntrospectableClassDeclarationImpl _introspectableClassDeclaration(
    ast.ClassDeclaration node,
  ) {
    assert(!_classMap.containsKey(node));
    return IntrospectableClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, node.declaredElement!),
      typeParameters: _typeParameters(node.typeParameters),
      interfaces: _typeAnnotations(node.implementsClause?.interfaces),
      isAbstract: node.abstractKeyword != null,
      isExternal: false,
      mixins: _typeAnnotations(node.withClause?.mixinTypes),
      superclass: node.extendsClause?.superclass.mapOrNull(
        _typeAnnotation,
      ),
    );
  }

  macro.IdentifierImpl _referencedIdentifier(ast.Identifier node) {
    final ast.SimpleIdentifier simpleIdentifier;
    if (node is ast.SimpleIdentifier) {
      simpleIdentifier = node;
    } else {
      simpleIdentifier = (node as ast.PrefixedIdentifier).identifier;
    }
    return _referencedIdentifierMap[simpleIdentifier] ??=
        _ReferencedIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: simpleIdentifier.name,
      node: simpleIdentifier,
    );
  }

  T _typeAnnotation<T extends macro.TypeAnnotationImpl>(
      ast.TypeAnnotation? node) {
    if (node == null) {
      return macro.OmittedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
      ) as T;
    } else if (node is ast.GenericFunctionType) {
      return macro.FunctionTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: node.question != null,
        namedParameters: node.parameters.parameters
            .where((e) => e.isNamed)
            .map(_formalParameter)
            .toList(),
        positionalParameters: node.parameters.parameters
            .where((e) => e.isPositional)
            .map(_formalParameter)
            .toList(),
        returnType: _typeAnnotation(node.returnType),
        typeParameters: _typeParameters(node.typeParameters),
      ) as T;
    } else if (node is ast.NamedType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: _referencedIdentifier(node.name),
        isNullable: node.question != null,
        typeArguments: _typeAnnotations(node.typeArguments?.arguments),
      ) as T;
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  List<T> _typeAnnotations<T extends macro.TypeAnnotationImpl>(
    List<ast.TypeAnnotation>? elements,
  ) {
    if (elements != null) {
      return List.generate(
          elements.length, (i) => _typeAnnotation(elements[i]));
    } else {
      return const [];
    }
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    ast.TypeParameter node,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, node.declaredElement!),
      bound: node.bound.mapOrNull(_typeAnnotation),
    );
  }

  List<macro.TypeParameterDeclarationImpl> _typeParameters(
    ast.TypeParameterList? typeParameterList,
  ) {
    if (typeParameterList != null) {
      return typeParameterList.typeParameters.map(_typeParameter).toList();
    } else {
      return const [];
    }
  }
}

class FieldDeclarationImpl extends macro.FieldDeclarationImpl {
  FieldDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.isExternal,
    required super.isFinal,
    required super.isLate,
    required super.type,
    required super.definingClass,
    required super.isStatic,
  });
}

abstract class IdentifierImpl extends macro.IdentifierImpl {
  IdentifierImpl({
    required super.id,
    required super.name,
  });

  Element? get element;
}

class IdentifierImplFromElement extends IdentifierImpl {
  @override
  final Element element;

  IdentifierImplFromElement({
    required super.id,
    required super.name,
    required this.element,
  });
}

class IntrospectableClassDeclarationImpl
    extends macro.IntrospectableClassDeclarationImpl {
  late final ClassElement element;

  IntrospectableClassDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.typeParameters,
    required super.interfaces,
    required super.isAbstract,
    required super.isExternal,
    required super.mixins,
    required super.superclass,
  });
}

class _DeclaredIdentifierImpl extends IdentifierImpl {
  @override
  final Element element;

  _DeclaredIdentifierImpl({
    required super.id,
    required super.name,
    required this.element,
  });
}

class _ReferencedIdentifierImpl extends IdentifierImpl {
  final ast.SimpleIdentifier node;

  _ReferencedIdentifierImpl({
    required super.id,
    required super.name,
    required this.node,
  });

  @override
  Element? get element => node.staticElement;
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}
