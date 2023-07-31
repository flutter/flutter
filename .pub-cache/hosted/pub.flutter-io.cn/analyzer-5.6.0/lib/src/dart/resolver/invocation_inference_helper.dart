// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Information about a constructor element to instantiate.
///
/// If the target is a [ClassElement], the [element] is a raw
/// [ConstructorElement] from the class, and [typeParameters] are the
/// type parameters of the class.
///
/// If the target is a [TypeAliasElement] with an [InterfaceType] as the
/// aliased type, the [element] is a [ConstructorMember] created from the
/// [ConstructorElement] of the corresponding class, and substituting
/// the class type parameters with the type arguments specified in the alias,
/// explicit types or the type parameters of the alias. The [typeParameters]
/// are the type parameters of the alias.
class ConstructorElementToInfer {
  /// The type parameters used in [element].
  final List<TypeParameterElement> typeParameters;

  /// The element, might be [ConstructorMember].
  final ConstructorElement element;

  ConstructorElementToInfer(this.typeParameters, this.element);

  /// Return the equivalent generic function type that we could use to
  /// forward to the constructor, or for a non-generic type simply returns
  /// the constructor type.
  ///
  /// For example given the type `class C<T> { C(T arg); }`, the generic
  /// function type is `<T>(T) -> C<T>`.
  FunctionType get asType {
    var typeParameters = this.typeParameters;
    return typeParameters.isEmpty
        ? element.type
        : FunctionTypeImpl(
            typeFormals: typeParameters,
            parameters: element.parameters,
            returnType: element.returnType,
            nullabilitySuffix: NullabilitySuffix.none,
          );
  }
}

class InvocationInferenceHelper {
  final ResolverVisitor _resolver;
  final ErrorReporter _errorReporter;
  final TypeSystemImpl _typeSystem;
  final MigrationResolutionHooks? _migrationResolutionHooks;
  final bool _genericMetadataIsEnabled;

  InvocationInferenceHelper({
    required ResolverVisitor resolver,
    required ErrorReporter errorReporter,
    required TypeSystemImpl typeSystem,
    required MigrationResolutionHooks? migrationResolutionHooks,
  })  : _resolver = resolver,
        _errorReporter = errorReporter,
        _typeSystem = typeSystem,
        _migrationResolutionHooks = migrationResolutionHooks,
        _genericMetadataIsEnabled = resolver.definingLibrary.featureSet
            .isEnabled(Feature.generic_metadata);

  /// If the constructor referenced by the [constructorName] is generic,
  /// and the [constructorName] does not have explicit type arguments,
  /// return the element and type parameters to infer. Otherwise return `null`.
  ConstructorElementToInfer? constructorElementToInfer({
    required ConstructorName constructorName,
    required LibraryElement definingLibrary,
  }) {
    List<TypeParameterElement> typeParameters;
    ConstructorElement? rawElement;

    var typeName = constructorName.type;
    var typeElement = typeName.name.staticElement;
    if (typeElement is InterfaceElement) {
      typeParameters = typeElement.typeParameters;
      var constructorIdentifier = constructorName.name;
      if (constructorIdentifier == null) {
        rawElement = typeElement.unnamedConstructor;
      } else {
        var name = constructorIdentifier.name;
        rawElement = typeElement.getNamedConstructor(name);
        if (rawElement != null && !rawElement.isAccessibleIn(definingLibrary)) {
          rawElement = null;
        }
      }
    } else if (typeElement is TypeAliasElement) {
      typeParameters = typeElement.typeParameters;
      var aliasedType = typeElement.aliasedType;
      if (aliasedType is InterfaceType) {
        var constructorIdentifier = constructorName.name;
        rawElement = aliasedType.lookUpConstructor(
          constructorIdentifier?.name,
          definingLibrary,
        );
      }
    } else {
      return null;
    }

    if (rawElement == null) {
      return null;
    }
    rawElement = _resolver.toLegacyElement(rawElement);
    return ConstructorElementToInfer(typeParameters, rawElement);
  }

  /// Given an uninstantiated generic function type, referenced by the
  /// [identifier] in the tear-off [expression], try to infer the instantiated
  /// generic function type from the surrounding context.
  DartType inferTearOff(Expression expression, SimpleIdentifierImpl identifier,
      DartType tearOffType,
      {required DartType? contextType}) {
    if (contextType is FunctionType && tearOffType is FunctionType) {
      var typeArguments = _typeSystem.inferFunctionTypeInstantiation(
        contextType,
        tearOffType,
        errorReporter: _errorReporter,
        errorNode: expression,
        genericMetadataIsEnabled: _genericMetadataIsEnabled,
      );
      identifier.tearOffTypeArgumentTypes = typeArguments;
      if (typeArguments.isNotEmpty) {
        return tearOffType.instantiate(typeArguments);
      }
    }
    return tearOffType;
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  void recordStaticType(ExpressionImpl expression, DartType type,
      {required DartType? contextType}) {
    var hooks = _migrationResolutionHooks;
    if (hooks != null) {
      type = hooks.modifyExpressionType(expression, type, contextType);
    }

    expression.staticType = type;
    if (_typeSystem.isBottom(type)) {
      _resolver.flowAnalysis.flow?.handleExit();
    }
  }

  /// Finish resolution of the [MethodInvocation].
  ///
  /// We have already found the invoked [ExecutableElement], and the [rawType]
  /// is its not yet instantiated type. Here we perform downwards inference,
  /// resolution of arguments, and upwards inference.
  void resolveMethodInvocation({
    required MethodInvocationImpl node,
    required FunctionType rawType,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
    required DartType? contextType,
  }) {
    var returnType = MethodInvocationInferrer(
      resolver: _resolver,
      node: node,
      argumentList: node.argumentList,
      contextType: contextType,
      whyNotPromotedList: whyNotPromotedList,
    ).resolveInvocation(rawType: rawType);

    recordStaticType(node, returnType, contextType: contextType);
  }
}
