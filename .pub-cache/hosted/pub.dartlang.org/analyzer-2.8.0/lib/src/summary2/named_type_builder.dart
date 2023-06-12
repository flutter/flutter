// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// The type builder for a [NamedType].
class NamedTypeBuilder extends TypeBuilder {
  /// TODO(scheglov) Replace with `DartType` in `TypeAliasElementImpl`.
  static const _aliasedTypeKey = '_aliasedType';
  static DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  /// The linker that contains this type.
  final Linker linker;

  /// The type system of the library with the type name.
  final TypeSystemImpl typeSystem;

  @override
  final Element element;

  final List<DartType> arguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// The node for which this builder is created, or `null` if the builder
  /// was detached from its node, e.g. during computing default types for
  /// type parameters.
  final NamedTypeImpl? node;

  /// The actual built type, not a [TypeBuilder] anymore.
  ///
  /// When [build] is called, the type is built, stored into this field,
  /// and set for the [node].
  DartType? _type;

  NamedTypeBuilder(this.linker, this.typeSystem, this.element, this.arguments,
      this.nullabilitySuffix,
      {this.node});

  factory NamedTypeBuilder.of(
    Linker linker,
    TypeSystemImpl typeSystem,
    NamedTypeImpl node,
    Element element,
    NullabilitySuffix nullabilitySuffix,
  ) {
    List<DartType> arguments;
    var argumentList = node.typeArguments;
    if (argumentList != null) {
      arguments = argumentList.arguments.map((n) => n.typeOrThrow).toList();
    } else {
      arguments = <DartType>[];
    }

    return NamedTypeBuilder(
        linker, typeSystem, element, arguments, nullabilitySuffix,
        node: node);
  }

  /// TODO(scheglov) Only when enabled both in the element, and target?
  bool get _isNonFunctionTypeAliasesEnabled {
    return element.library!.featureSet.isEnabled(
      Feature.nonfunction_type_aliases,
    );
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    if (visitor is LinkingTypeVisitor<R>) {
      var visitor2 = visitor as LinkingTypeVisitor<R>;
      return visitor2.visitNamedTypeBuilder(this);
    } else {
      throw StateError('Should not happen outside linking.');
    }
  }

  @override
  DartType build() {
    if (_type != null) {
      return _type!;
    }

    final element = this.element;
    if (element is ClassElement) {
      var parameters = element.typeParameters;
      var arguments = _buildArguments(parameters);
      var type = element.instantiate(
        typeArguments: arguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = typeSystem.toLegacyType(type) as InterfaceType;
      _type = type;
    } else if (element is TypeAliasElementImpl) {
      var aliasedType = _getAliasedType(element);
      var parameters = element.typeParameters;
      var arguments = _buildArguments(parameters);
      element.aliasedType = aliasedType;
      var type = element.instantiate(
        typeArguments: arguments,
        nullabilitySuffix: nullabilitySuffix,
      );
      type = typeSystem.toLegacyType(type);
      _type = type;
    } else if (element is NeverElementImpl) {
      if (typeSystem.isNonNullableByDefault) {
        _type = NeverTypeImpl.instance.withNullability(nullabilitySuffix);
      } else {
        _type = typeSystem.typeProvider.nullType;
      }
    } else if (element is TypeParameterElement) {
      _type = TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: nullabilitySuffix,
      );
    } else {
      _type = _dynamicType;
    }

    node?.type = _type;
    return _type!;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write(element.displayName);
    if (arguments.isNotEmpty) {
      buffer.write('<');
      buffer.write(arguments.join(', '));
      buffer.write('>');
    }
    return buffer.toString();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) {
      return this;
    }

    return NamedTypeBuilder(
        linker, typeSystem, element, arguments, nullabilitySuffix,
        node: node);
  }

  DartType _buildAliasedType(TypeAnnotation? node) {
    if (_isNonFunctionTypeAliasesEnabled) {
      if (node != null) {
        return _buildType(node.typeOrThrow);
      } else {
        return _dynamicType;
      }
    } else {
      if (node is GenericFunctionType) {
        return _buildType(node.typeOrThrow);
      } else {
        return FunctionTypeImpl(
          typeFormals: const <TypeParameterElement>[],
          parameters: const <ParameterElement>[],
          returnType: _dynamicType,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
  }

  /// Build arguments that correspond to the type [parameters].
  List<DartType> _buildArguments(List<TypeParameterElement> parameters) {
    if (parameters.isEmpty) {
      return const <DartType>[];
    } else if (arguments.isNotEmpty) {
      if (arguments.length == parameters.length) {
        return List.generate(arguments.length, (index) {
          var type = arguments[index];
          return _buildType(type);
        });
      } else {
        return _listOfDynamic(parameters.length);
      }
    } else {
      return List.generate(parameters.length, (index) {
        var parameter = parameters[index] as TypeParameterElementImpl;
        var defaultType = parameter.defaultType!;
        return _buildType(defaultType);
      });
    }
  }

  DartType _buildFormalParameterType(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      return _buildFormalParameterType(node.parameter);
    } else if (node is FunctionTypedFormalParameter) {
      return _buildFunctionType(
        typeParameterList: node.typeParameters,
        returnTypeNode: node.returnType,
        parameterList: node.parameters,
        hasQuestion: node.question != null,
      );
    } else if (node is SimpleFormalParameter) {
      return _buildNodeType(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  FunctionType _buildFunctionType({
    required TypeParameterList? typeParameterList,
    required TypeAnnotation? returnTypeNode,
    required FormalParameterList parameterList,
    required bool hasQuestion,
  }) {
    var returnType = _buildNodeType(returnTypeNode);
    var typeParameters = _typeParameters(typeParameterList);
    var formalParameters = _formalParameters(parameterList);

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: _getNullabilitySuffix(hasQuestion),
    );
  }

  DartType _buildNodeType(TypeAnnotation? node) {
    if (node == null) {
      return _dynamicType;
    } else {
      return _buildType(node.typeOrThrow);
    }
  }

  List<ParameterElementImpl> _formalParameters(FormalParameterList node) {
    return node.parameters.asImpl.map((parameter) {
      return ParameterElementImpl.synthetic(
        parameter.identifier?.name ?? '',
        _buildFormalParameterType(parameter),
        parameter.kind,
      );
    }).toList();
  }

  DartType _getAliasedType(TypeAliasElementImpl element) {
    var typedefNode = linker.getLinkingNode(element);

    // If the element is not being linked, the types have already been built.
    if (typedefNode == null) {
      return element.aliasedType;
    }

    // Break a possible recursion.
    var existing = typedefNode.getProperty(_aliasedTypeKey) as DartType?;
    if (existing != null) {
      return existing;
    } else {
      _setAliasedType(typedefNode, _dynamicType);
    }

    if (typedefNode is FunctionTypeAlias) {
      var result = _buildFunctionType(
        typeParameterList: null,
        returnTypeNode: typedefNode.returnType,
        parameterList: typedefNode.parameters,
        hasQuestion: false,
      );
      _setAliasedType(typedefNode, result);
      return result;
    } else if (typedefNode is GenericTypeAlias) {
      var aliasedTypeNode = typedefNode.type;
      var aliasedType = _buildAliasedType(aliasedTypeNode);
      _setAliasedType(typedefNode, aliasedType);
      return aliasedType;
    } else {
      throw StateError('(${element.runtimeType}) $element');
    }
  }

  NullabilitySuffix _getNullabilitySuffix(bool hasQuestion) {
    if (hasQuestion) {
      return NullabilitySuffix.question;
    } else if (typeSystem.isNonNullableByDefault) {
      return NullabilitySuffix.none;
    } else {
      return NullabilitySuffix.star;
    }
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static DartType _buildType(DartType type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }

  static List<DartType> _listOfDynamic(int length) {
    return List<DartType>.filled(length, _dynamicType);
  }

  static void _setAliasedType(AstNode node, DartType type) {
    node.setProperty(_aliasedTypeKey, type);
  }

  static List<TypeParameterElement> _typeParameters(TypeParameterList? node) {
    if (node != null) {
      return node.typeParameters
          .map<TypeParameterElement>((p) => p.declaredElement!)
          .toList();
    } else {
      return const <TypeParameterElement>[];
    }
  }
}
