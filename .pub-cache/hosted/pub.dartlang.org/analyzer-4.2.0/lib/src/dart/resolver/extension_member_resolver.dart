// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/util/either.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

class ExtensionMemberResolver {
  final ResolverVisitor _resolver;

  ExtensionMemberResolver(this._resolver);

  DartType get _dynamicType => _typeProvider.dynamicType;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _genericMetadataIsEnabled =>
      _resolver.definingLibrary.featureSet.isEnabled(Feature.generic_metadata);

  bool get _isNonNullableByDefault =>
      _resolver.definingLibrary.featureSet.isEnabled(Feature.non_nullable);

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Set the type context for the receiver of the override.
  ///
  /// The context of the invocation that is made through the override does
  /// not affect the type inference of the override and the receiver.
  DartType? computeOverrideReceiverContextType(ExtensionOverride node) {
    var element = node.staticElement!;
    var typeParameters = element.typeParameters;

    var arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      return null;
    }

    List<DartType> typeArgumentTypes;
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        typeArgumentTypes = arguments.map((a) => a.typeOrThrow).toList();
      } else {
        typeArgumentTypes = _listOfDynamic(typeParameters);
      }
    } else {
      typeArgumentTypes = List.filled(
        typeParameters.length,
        UnknownInferredType.instance,
      );
    }

    return Substitution.fromPairs(
      typeParameters,
      typeArgumentTypes,
    ).substituteType(element.extendedType);
  }

  /// Return the most specific extension in the current scope for this [type],
  /// that defines the member with the given [name].
  ///
  /// If no applicable extensions, return [ResolutionResult.none].
  ///
  /// If the match is ambiguous, report an error on the [nameEntity], and
  /// return [ResolutionResult.ambiguous].
  ResolutionResult findExtension(
    DartType type,
    SyntacticEntity nameEntity,
    String name,
  ) {
    var extensions = _resolver.definingLibrary.accessibleExtensions
        .hasMemberWithBaseName(name)
        .applicableTo(
          targetLibrary: _resolver.definingLibrary,
          targetType: type,
        );

    if (extensions.isEmpty) {
      return ResolutionResult.none;
    }

    if (extensions.length == 1) {
      return extensions[0].asResolutionResult;
    }

    var mostSpecific = _chooseMostSpecific(extensions);
    return mostSpecific.map(
      (extension) {
        return extension.asResolutionResult;
      },
      (noneMoreSpecific) {
        _errorReporter.reportErrorForOffset(
          CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS,
          nameEntity.offset,
          nameEntity.length,
          [
            name,
            noneMoreSpecific.map((e) {
              var name = e.extension.name;
              if (name != null) {
                return "extension '$name'";
              }
              var type = e.extension.extendedType
                  .getDisplayString(withNullability: _isNonNullableByDefault);
              return "unnamed extension on '$type'";
            }).commaSeparatedWithAnd,
          ],
        );
        return ResolutionResult.ambiguous;
      },
    );
  }

  /// Resolve the [name] (without `=`) to the corresponding getter and setter
  /// members of the extension [node].
  ///
  /// The [node] is fully resolved, and its type arguments are set.
  ResolutionResult getOverrideMember(ExtensionOverride node, String name) {
    var element = node.extensionName.staticElement as ExtensionElement;

    ExecutableElement? getter;
    ExecutableElement? setter;
    if (name == '[]') {
      getter = element.getMethod('[]');
      setter = element.getMethod('[]=');
    } else {
      getter = element.getGetter(name) ?? element.getMethod(name);
      setter = element.getSetter(name);
    }

    if (getter == null && setter == null) {
      return ResolutionResult.none;
    }

    var substitution = Substitution.fromPairs(
      element.typeParameters,
      node.typeArgumentTypes!,
    );

    var getterMember =
        getter != null ? ExecutableMember.from2(getter, substitution) : null;
    var setterMember =
        setter != null ? ExecutableMember.from2(setter, substitution) : null;

    getterMember = _resolver.toLegacyElement(getterMember);
    setterMember = _resolver.toLegacyElement(setterMember);

    return ResolutionResult(getter: getterMember, setter: setterMember);
  }

  /// Perform upward inference for the override.
  void resolveOverride(
      ExtensionOverride node, List<WhyNotPromotedGetter> whyNotPromotedList) {
    var nodeImpl = node as ExtensionOverrideImpl;
    var element = node.staticElement!;
    var typeParameters = element.typeParameters;

    if (!_isValidContext(node)) {
      if (!_isCascadeTarget(node)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.EXTENSION_OVERRIDE_WITHOUT_ACCESS,
          node,
        );
      }
      nodeImpl.staticType = _dynamicType;
    }

    var arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_EXTENSION_ARGUMENT_COUNT,
        node.argumentList,
      );
      nodeImpl.typeArgumentTypes = _listOfDynamic(typeParameters);
      nodeImpl.extendedType = _dynamicType;
      return;
    }

    var receiverExpression = arguments[0];
    var receiverType = receiverExpression.typeOrThrow;

    if (node.isNullAware) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    var typeArgumentTypes = _inferTypeArguments(node, receiverType)!;
    nodeImpl.typeArgumentTypes = typeArgumentTypes;

    var substitution = Substitution.fromPairs(
      typeParameters,
      typeArgumentTypes,
    );

    var extendedType = nodeImpl.extendedType =
        substitution.substituteType(element.extendedType);

    _checkTypeArgumentsMatchingBounds(
      typeParameters,
      node.typeArguments,
      typeArgumentTypes,
      substitution,
    );

    if (receiverType.isVoid) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, receiverExpression);
    } else if (!_typeSystem.isAssignableTo(receiverType, extendedType)) {
      var whyNotPromoted =
          whyNotPromotedList.isEmpty ? null : whyNotPromotedList[0];
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE,
        receiverExpression,
        [receiverType, extendedType],
        _resolver.computeWhyNotPromotedMessages(
            receiverExpression, whyNotPromoted?.call()),
      );
    }
  }

  void _checkTypeArgumentsMatchingBounds(
    List<TypeParameterElement> typeParameters,
    TypeArgumentList? typeArgumentList,
    List<DartType> typeArgumentTypes,
    Substitution substitution,
  ) {
    if (typeArgumentList != null) {
      for (var i = 0; i < typeArgumentTypes.length; i++) {
        var argument = typeArgumentTypes[i];
        var parameter = typeParameters[i];
        var parameterBound = parameter.bound;
        if (parameterBound != null) {
          parameterBound = substitution.substituteType(parameterBound);
          parameterBound = _typeSystem.toLegacyTypeIfOptOut(parameterBound);
          if (!_typeSystem.isSubtypeOf(argument, parameterBound)) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
              typeArgumentList.arguments[i],
              [argument, parameter.name, parameterBound],
            );
          }
        }
      }
    }
  }

  /// Return either the most specific extension, or a list of the extensions
  /// that are ambiguous.
  Either2<InstantiatedExtensionWithMember,
          List<InstantiatedExtensionWithMember>>
      _chooseMostSpecific(List<InstantiatedExtensionWithMember> extensions) {
    InstantiatedExtensionWithMember? bestSoFar;
    var noneMoreSpecific = <InstantiatedExtensionWithMember>[];
    for (var candidate in extensions) {
      if (noneMoreSpecific.isNotEmpty) {
        var isMostSpecific = true;
        var hasMoreSpecific = false;
        for (var other in noneMoreSpecific) {
          if (!_isMoreSpecific(candidate, other)) {
            isMostSpecific = false;
          }
          if (_isMoreSpecific(other, candidate)) {
            hasMoreSpecific = true;
          }
        }
        if (isMostSpecific) {
          bestSoFar = candidate;
          noneMoreSpecific.clear();
        } else if (!hasMoreSpecific) {
          noneMoreSpecific.add(candidate);
        }
      } else if (bestSoFar == null) {
        bestSoFar = candidate;
      } else if (_isMoreSpecific(bestSoFar, candidate)) {
        // already
      } else if (_isMoreSpecific(candidate, bestSoFar)) {
        bestSoFar = candidate;
      } else {
        noneMoreSpecific.add(bestSoFar);
        noneMoreSpecific.add(candidate);
        bestSoFar = null;
      }
    }

    if (bestSoFar != null) {
      return Either2.t1(bestSoFar);
    } else {
      return Either2.t2(noneMoreSpecific);
    }
  }

  /// Given the generic [element] element, either return types specified
  /// explicitly in [typeArguments], or infer type arguments from the given
  /// [receiverType].
  ///
  /// If the number of explicit type arguments is different than the number
  /// of extension's type parameters, or inference fails, return `dynamic`
  /// for all type parameters.
  List<DartType>? _inferTypeArguments(
    ExtensionOverride node,
    DartType receiverType,
  ) {
    var element = node.staticElement!;
    var typeParameters = element.typeParameters;
    var typeArguments = node.typeArguments;

    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        if (typeParameters.isEmpty) {
          return const <DartType>[];
        }
        return arguments.map((a) => a.typeOrThrow).toList();
      } else {
        // We can safely assume `element.name` is non-`null` because type
        // arguments can only be applied to explicit extension overrides, and
        // explicit extension overrides cannot refer to unnamed extensions.
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION,
          typeArguments,
          [element.name!, typeParameters.length, arguments.length],
        );
        return _listOfDynamic(typeParameters);
      }
    } else {
      var inferrer = GenericInferrer(_typeSystem, typeParameters,
          errorReporter: _errorReporter,
          errorNode: node.extensionName,
          genericMetadataIsEnabled: _genericMetadataIsEnabled);
      inferrer.constrainArgument(
        receiverType,
        element.extendedType,
        'extendedType',
      );
      return inferrer.upwardsInfer();
    }
  }

  /// Instantiate the extended type of the [extension] to the bounds of the
  /// type formals of the extension.
  DartType _instantiateToBounds(ExtensionElement extension) {
    var typeParameters = extension.typeParameters;
    return Substitution.fromPairs(
      typeParameters,
      _typeSystem.instantiateTypeFormalsToBounds(typeParameters),
    ).substituteType(extension.extendedType);
  }

  /// Return `true` is [e1] is more specific than [e2].
  bool _isMoreSpecific(
      InstantiatedExtensionWithMember e1, InstantiatedExtensionWithMember e2) {
    // 1. The latter extension is declared in a platform library, and the
    //    former extension is not.
    // 2. They are both declared in platform libraries, or both declared in
    //    non-platform libraries.
    var e1_isInSdk = e1.extension.library.isInSdk;
    var e2_isInSdk = e2.extension.library.isInSdk;
    if (e1_isInSdk && !e2_isInSdk) {
      return false;
    } else if (!e1_isInSdk && e2_isInSdk) {
      return true;
    }

    var extendedType1 = e1.extendedType;
    var extendedType2 = e2.extendedType;

    // 3. The instantiated type (the type after applying type inference from
    //    the receiver) of T1 is a subtype of the instantiated type of T2,
    //    and either...
    if (!_isSubtypeOf(extendedType1, extendedType2)) {
      return false;
    }

    // 4. ...not vice versa, or...
    if (!_isSubtypeOf(extendedType2, extendedType1)) {
      return true;
    }

    // 5. ...the instantiate-to-bounds type of T1 is a subtype of the
    //    instantiate-to-bounds type of T2 and not vice versa.
    // TODO(scheglov) store instantiated types
    var extendedTypeBound1 = _instantiateToBounds(e1.extension);
    var extendedTypeBound2 = _instantiateToBounds(e2.extension);
    return _isSubtypeOf(extendedTypeBound1, extendedTypeBound2) &&
        !_isSubtypeOf(extendedTypeBound2, extendedTypeBound1);
  }

  /// Ask the type system for a subtype check.
  bool _isSubtypeOf(DartType type1, DartType type2) =>
      _typeSystem.isSubtypeOf(type1, type2);

  List<DartType> _listOfDynamic(List<TypeParameterElement> parameters) {
    return List<DartType>.filled(parameters.length, _dynamicType);
  }

  static bool _isCascadeTarget(ExtensionOverride node) {
    var parent = node.parent;
    return parent is CascadeExpression && parent.target == node;
  }

  /// Return `true` if the extension override [node] is being used as a target
  /// of an operation that might be accessing an instance member.
  static bool _isValidContext(ExtensionOverride node) {
    var parent = node.parent;
    return parent is BinaryExpression && parent.leftOperand == node ||
        parent is FunctionExpressionInvocation && parent.function == node ||
        parent is IndexExpression && parent.target == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixExpression ||
        parent is PropertyAccess && parent.target == node;
  }
}
