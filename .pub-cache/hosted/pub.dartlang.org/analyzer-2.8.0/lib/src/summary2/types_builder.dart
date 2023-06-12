// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/default_types_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// Return `true` if [type] can be used as a class.
bool _isInterfaceTypeClass(InterfaceType type) {
  if (type.element.isMixin) {
    return false;
  }
  return _isInterfaceTypeInterface(type);
}

/// Return `true` if [type] can be used as an interface or a mixin.
bool _isInterfaceTypeInterface(InterfaceType type) {
  if (type.element.isEnum) {
    return false;
  }
  if (type.isDartCoreFunction || type.isDartCoreNull) {
    return false;
  }
  if (type.nullabilitySuffix == NullabilitySuffix.question) {
    return false;
  }
  return true;
}

List<InterfaceType> _toInterfaceTypeList(List<NamedType>? nodeList) {
  if (nodeList != null) {
    return nodeList
        .map((e) => e.type)
        .whereType<InterfaceType>()
        .where(_isInterfaceTypeInterface)
        .toList();
  }
  return const [];
}

class NodesToBuildType {
  final List<AstNode> declarations = [];
  final List<TypeBuilder> typeBuilders = [];

  void addDeclaration(AstNode node) {
    declarations.add(node);
  }

  void addTypeBuilder(TypeBuilder builder) {
    typeBuilders.add(builder);
  }
}

class TypesBuilder {
  final Linker _linker;

  TypesBuilder(this._linker);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  /// Build types for all type annotations, and set types for declarations.
  void build(NodesToBuildType nodes) {
    DefaultTypesBuilder(_linker).build(nodes.declarations);

    for (var builder in nodes.typeBuilders) {
      builder.build();
    }

    // TODO(scheglov) generalize
    _linker.elementNodes.forEach((element, node) {
      if (element is GenericFunctionTypeElementImpl &&
          node is GenericFunctionType) {
        element.returnType = node.returnType?.type ?? _dynamicType;
      }
      if (element is TypeParameterElementImpl && node is TypeParameter) {
        element.bound = node.bound?.type;
      }
    });

    for (var declaration in nodes.declarations) {
      _declaration(declaration);
    }

    _MixinsInference(_linker).perform(nodes.declarations);
  }

  FunctionType _buildFunctionType(
    TypeParameterList? typeParameterList,
    TypeAnnotation? returnTypeNode,
    FormalParameterList parameterList,
    NullabilitySuffix nullabilitySuffix,
  ) {
    var returnType = returnTypeNode?.type ?? _dynamicType;
    var typeParameters = _typeParameters(typeParameterList);
    var formalParameters = _formalParameters(parameterList);

    return FunctionTypeImpl(
      typeFormals: typeParameters,
      parameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  void _classDeclaration(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;

    var extendsClause = node.extendsClause;
    if (extendsClause != null) {
      var type = extendsClause.superclass2.type;
      if (type is InterfaceType && _isInterfaceTypeClass(type)) {
        element.supertype = type;
      } else {
        element.supertype = _objectType(element);
      }
    } else if (element.library.isDartCore && element.name == 'Object') {
      element.setModifier(Modifier.DART_CORE_OBJECT, true);
    } else {
      element.supertype = _objectType(element);
    }

    element.mixins = _toInterfaceTypeList(
      node.withClause?.mixinTypes2,
    );

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces2,
    );
  }

  void _classTypeAlias(ClassTypeAlias node) {
    var element = node.declaredElement as ClassElementImpl;

    var superType = node.superclass2.type;
    if (superType is InterfaceType && _isInterfaceTypeInterface(superType)) {
      element.supertype = superType;
    } else {
      element.supertype = _objectType(element);
    }

    element.mixins = _toInterfaceTypeList(
      node.withClause.mixinTypes2,
    );

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces2,
    );
  }

  void _declaration(AstNode node) {
    if (node is ClassDeclaration) {
      _classDeclaration(node);
    } else if (node is ClassTypeAlias) {
      _classTypeAlias(node);
    } else if (node is ExtensionDeclaration) {
      _extensionDeclaration(node);
    } else if (node is FieldFormalParameter) {
      _fieldFormalParameter(node);
    } else if (node is FunctionDeclaration) {
      var returnType = node.returnType?.type;
      if (returnType == null) {
        if (node.isSetter) {
          returnType = _voidType;
        } else {
          returnType = _dynamicType;
        }
      }
      var element = node.declaredElement as ExecutableElementImpl;
      element.returnType = returnType;
    } else if (node is FunctionTypeAlias) {
      _functionTypeAlias(node);
    } else if (node is FunctionTypedFormalParameter) {
      _functionTypedFormalParameter(node);
    } else if (node is GenericTypeAlias) {
      _genericTypeAlias(node);
    } else if (node is MethodDeclaration) {
      var returnType = node.returnType?.type;
      if (returnType == null) {
        if (node.isSetter) {
          returnType = _voidType;
        } else if (node.isOperator && node.name.name == '[]=') {
          returnType = _voidType;
        } else {
          returnType = _dynamicType;
        }
      }
      var element = node.declaredElement as ExecutableElementImpl;
      element.returnType = returnType;
    } else if (node is MixinDeclaration) {
      _mixinDeclaration(node);
    } else if (node is SimpleFormalParameter) {
      var element = node.declaredElement as ParameterElementImpl;
      element.type = node.type?.type ?? _dynamicType;
    } else if (node is VariableDeclarationList) {
      var type = node.type?.type;
      if (type != null) {
        for (var variable in node.variables) {
          (variable.declaredElement as VariableElementImpl).type = type;
        }
      }
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
  }

  void _extensionDeclaration(ExtensionDeclaration node) {
    var element = node.declaredElement as ExtensionElementImpl;
    element.extendedType = node.extendedType.typeOrThrow;
  }

  void _fieldFormalParameter(FieldFormalParameter node) {
    var element = node.declaredElement as FieldFormalParameterElementImpl;
    var parameterList = node.parameters;
    if (parameterList != null) {
      var type = _buildFunctionType(
        node.typeParameters,
        node.type,
        parameterList,
        _nullability(node, node.question != null),
      );
      element.type = type;
    } else {
      element.type = node.type?.type ?? _dynamicType;
    }
  }

  List<ParameterElement> _formalParameters(FormalParameterList node) {
    return node.parameters.asImpl.map((parameter) {
      return parameter.declaredElement!;
    }).toList();
  }

  void _functionTypeAlias(FunctionTypeAlias node) {
    var element = node.declaredElement as TypeAliasElementImpl;
    var function = element.aliasedElement as GenericFunctionTypeElementImpl;
    function.returnType = node.returnType?.type ?? _dynamicType;
    element.aliasedType = function.type;
  }

  void _functionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var type = _buildFunctionType(
      node.typeParameters,
      node.returnType,
      node.parameters,
      _nullability(node, node.question != null),
    );
    var element = node.declaredElement as ParameterElementImpl;
    element.type = type;
  }

  void _genericTypeAlias(GenericTypeAlias node) {
    var element = node.declaredElement as TypeAliasElementImpl;
    var featureSet = element.library.featureSet;

    var typeNode = node.type;
    if (featureSet.isEnabled(Feature.nonfunction_type_aliases)) {
      element.aliasedType = typeNode.typeOrThrow;
    } else if (typeNode is GenericFunctionType) {
      element.aliasedType = typeNode.typeOrThrow;
    } else {
      element.aliasedType = _errorFunctionType();
    }
  }

  bool _isNonNullableByDefault(AstNode node) {
    var unit = node.thisOrAncestorOfType<CompilationUnit>();
    return unit!.featureSet.isEnabled(Feature.non_nullable);
  }

  void _mixinDeclaration(MixinDeclaration node) {
    var element = node.declaredElement as MixinElementImpl;

    var constraints = _toInterfaceTypeList(
      node.onClause?.superclassConstraints2,
    );
    if (constraints.isEmpty) {
      constraints = [_objectType(element)];
    }
    element.superclassConstraints = constraints;

    element.interfaces = _toInterfaceTypeList(
      node.implementsClause?.interfaces2,
    );
  }

  NullabilitySuffix _nullability(AstNode node, bool hasQuestion) {
    if (_isNonNullableByDefault(node)) {
      if (hasQuestion) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    } else {
      return NullabilitySuffix.star;
    }
  }

  List<TypeParameterElement> _typeParameters(TypeParameterList? node) {
    if (node == null) {
      return const <TypeParameterElement>[];
    }

    return node.typeParameters
        .map<TypeParameterElement>((p) => p.declaredElement!)
        .toList();
  }

  /// The [FunctionType] to use when a function type is expected for a type
  /// alias, but the actual provided type annotation is not a function type.
  static FunctionTypeImpl _errorFunctionType() {
    return FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  static InterfaceType _objectType(ClassElementImpl element) {
    return element.library.typeProvider.objectType;
  }
}

/// Performs mixins inference in a [ClassDeclaration].
class _MixinInference {
  final ClassElementImpl element;
  final TypeSystemImpl typeSystem;
  final FeatureSet featureSet;
  final InterfaceType classType;

  late final InterfacesMerger interfacesMerger;

  _MixinInference(this.element, this.featureSet)
      : typeSystem = element.library.typeSystem,
        classType = element.thisType {
    interfacesMerger = InterfacesMerger(typeSystem);
    interfacesMerger.addWithSupertypes(element.supertype);
  }

  NullabilitySuffix get _noneOrStarSuffix {
    return _nonNullableEnabled
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  bool get _nonNullableEnabled => featureSet.isEnabled(Feature.non_nullable);

  void perform(WithClause? withClause) {
    if (withClause == null) return;

    for (var mixinNode in withClause.mixinTypes2) {
      var mixinType = _inferSingle(mixinNode as NamedTypeImpl);
      interfacesMerger.addWithSupertypes(mixinType);
    }
  }

  InterfaceType? _findInterfaceTypeForElement(
    ClassElement element,
    List<InterfaceType> interfaceTypes,
  ) {
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element == element) return interfaceType;
    }
    return null;
  }

  List<InterfaceType>? _findInterfaceTypesForConstraints(
    List<InterfaceType> constraints,
    List<InterfaceType> interfaceTypes,
  ) {
    var result = <InterfaceType>[];
    for (var constraint in constraints) {
      var interfaceType = _findInterfaceTypeForElement(
        constraint.element,
        interfaceTypes,
      );

      // No matching interface type found, so inference fails.
      if (interfaceType == null) {
        return null;
      }

      result.add(interfaceType);
    }
    return result;
  }

  InterfaceType _inferSingle(NamedTypeImpl mixinNode) {
    var mixinType = _interfaceType(mixinNode.typeOrThrow);

    if (mixinNode.typeArguments != null) {
      return mixinType;
    }

    var mixinElement = mixinType.element;
    if (mixinElement.typeParameters.isEmpty) {
      return mixinType;
    }

    var mixinSupertypeConstraints =
        typeSystem.gatherMixinSupertypeConstraintsForInference(mixinElement);
    if (mixinSupertypeConstraints.isEmpty) {
      return mixinType;
    }

    var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
      mixinSupertypeConstraints,
      interfacesMerger.typeList,
    );

    // Note: if matchingInterfaceType is null, that's an error.  Also,
    // if there are multiple matching interface types that use
    // different type parameters, that's also an error.  But we can't
    // report errors from the linker, so we just use the
    // first matching interface type (if there is one).  The error
    // detection logic is implemented in the ErrorVerifier.
    if (matchingInterfaceTypes == null) {
      return mixinType;
    }

    // Try to pattern match matchingInterfaceTypes against
    // mixinSupertypeConstraints to find the correct set of type
    // parameters to apply to the mixin.
    var inferredTypeArguments = typeSystem.matchSupertypeConstraints(
      mixinElement,
      mixinSupertypeConstraints,
      matchingInterfaceTypes,
      genericMetadataIsEnabled:
          mixinElement.library.featureSet.isEnabled(Feature.generic_metadata),
    );
    if (inferredTypeArguments != null) {
      var inferredMixin = mixinElement.instantiate(
        typeArguments: inferredTypeArguments,
        nullabilitySuffix: _noneOrStarSuffix,
      );
      mixinType = inferredMixin;
      mixinNode.type = inferredMixin;
    }

    return mixinType;
  }

  InterfaceType _interfaceType(DartType type) {
    if (type is InterfaceType && _isInterfaceTypeInterface(type)) {
      return type;
    }
    return typeSystem.typeProvider.objectType;
  }
}

/// Performs mixin inference for all declarations.
class _MixinsInference {
  final Linker _linker;

  _MixinsInference(this._linker);

  void perform(List<AstNode> declarations) {
    for (var node in declarations) {
      if (node is ClassDeclaration || node is ClassTypeAlias) {
        var element = (node as Declaration).declaredElement as ClassElementImpl;
        element.mixinInferenceCallback = _callbackWhenRecursion;
      }
    }

    for (var declaration in declarations) {
      _inferDeclaration(declaration);
    }

    _resetHierarchies(declarations);
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are inferring the [element] now, i.e. there is a loop.
  ///
  /// This is an error. So, we return the empty list, and break the loop.
  List<InterfaceType> _callbackWhenLoop(ClassElementImpl element) {
    element.mixinInferenceCallback = null;
    return <InterfaceType>[];
  }

  /// This method is invoked when mixins are asked from the [element], and
  /// we are not inferring the [element] now, i.e. there is no loop.
  List<InterfaceType>? _callbackWhenRecursion(ClassElementImpl element) {
    var node = _linker.getLinkingNode(element);
    if (node != null) {
      _inferDeclaration(node);
    }
    // The inference was successful, let the element return actual mixins.
    return null;
  }

  void _infer(ClassElementImpl element, WithClause? withClause) {
    if (withClause != null) {
      element.mixinInferenceCallback = _callbackWhenLoop;
      try {
        var featureSet = element.library.featureSet;
        _MixinInference(element, featureSet).perform(withClause);
      } finally {
        element.mixinInferenceCallback = null;
        element.mixins = _toInterfaceTypeList(
          withClause.mixinTypes2,
        );
      }
    }
  }

  void _inferDeclaration(AstNode node) {
    if (node is ClassDeclaration) {
      var element = node.declaredElement as ClassElementImpl;
      _infer(element, node.withClause);
    } else if (node is ClassTypeAlias) {
      var element = node.declaredElement as ClassElementImpl;
      _infer(element, node.withClause);
    }
  }

  /// When a loop is detected during mixin inference, we pretend that the list
  /// of mixins of the class is empty. But if this happens during building a
  /// class hierarchy, we cache such incomplete hierarchy. So, here we reset
  /// hierarchies for all classes being linked, indiscriminately.
  void _resetHierarchies(List<AstNode> declarations) {
    for (var declaration in declarations) {
      if (declaration is ClassOrMixinDeclaration) {
        var element = declaration.declaredElement as ClassElementImpl;
        var sessionImpl = element.library.session as AnalysisSessionImpl;
        sessionImpl.classHierarchy.remove(element);
      }
    }
  }
}
