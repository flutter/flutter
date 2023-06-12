// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [InstanceCreationExpression] nodes.
///
/// This resolver is responsible for rewriting a given
/// [InstanceCreationExpression] as a [MethodInvocation] if the parsed
/// [ConstructorName]'s `type` resolves to a [FunctionReference] or
/// [ConstructorReference], instead of a [NamedType].
class InstanceCreationExpressionResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  InstanceCreationExpressionResolver(this._resolver);

  void resolve(InstanceCreationExpressionImpl node) {
    // The parser can parse certain code as [InstanceCreationExpression] when it
    // might be an invocation of a method on a [FunctionReference] or
    // [ConstructorReference]. In such a case, it is this resolver's
    // responsibility to rewrite. For example, given:
    //
    //     a.m<int>.apply();
    //
    // the parser will give an InstanceCreationExpression (`a.m<int>.apply()`)
    // with a name of `a.m<int>.apply` (ConstructorName) with a type of
    // `a.m<int>` (TypeName with a name of `a.m` (PrefixedIdentifier) and
    // typeArguments of `<int>`) and a name of `apply` (SimpleIdentifier). If
    // `a.m<int>` is actually a function reference, then the
    // InstanceCreationExpression needs to be rewritten as a MethodInvocation
    // with a target of `a.m<int>` (a FunctionReference) and a name of `apply`.
    if (node.keyword == null) {
      var typeNameTypeArguments = node.constructorName.type2.typeArguments;
      if (typeNameTypeArguments != null) {
        // This could be a method call on a function reference or a constructor
        // reference.
        _resolveWithTypeNameWithTypeArguments(node, typeNameTypeArguments);
        return;
      }
    }

    _resolveInstanceCreationExpression(node);
  }

  void _inferArgumentTypes(covariant InstanceCreationExpressionImpl node) {
    var constructorName = node.constructorName;
    var typeName = constructorName.type2;
    var typeArguments = typeName.typeArguments;
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      constructorName: constructorName,
      definingLibrary: _resolver.definingLibrary,
    );
    FunctionType? inferred;

    // If the constructor is generic, we'll have a ConstructorMember that
    // substitutes in type arguments (possibly `dynamic`) from earlier in
    // resolution.
    //
    // Otherwise we'll have a ConstructorElement, and we can skip inference
    // because there's nothing to infer in a non-generic type.
    if (elementToInfer != null) {
      // TODO(leafp): Currently, we may re-infer types here, since we
      // sometimes resolve multiple times.  We should really check that we
      // have not already inferred something.  However, the obvious ways to
      // check this don't work, since we may have been instantiated
      // to bounds in an earlier phase, and we *do* want to do inference
      // in that case.

      // Get back to the uninstantiated generic constructor.
      // TODO(jmesserly): should we store this earlier in resolution?
      // Or look it up, instead of jumping backwards through the Member?
      var rawElement = elementToInfer.element;
      var constructorType = elementToInfer.asType;

      inferred = _resolver.inferenceHelper.inferArgumentTypesForGeneric(
          node, constructorType, typeArguments,
          isConst: node.isConst, errorNode: node.constructorName);

      if (inferred != null) {
        var arguments = node.argumentList;
        InferenceContext.setType(arguments, inferred);
        // Fix up the parameter elements based on inferred method.
        arguments.correspondingStaticParameters =
            ResolverVisitor.resolveArgumentsToParameters(
                arguments, inferred.parameters, null);

        constructorName.type2.type = inferred.returnType;

        // Update the static element as well. This is used in some cases, such
        // as computing constant values. It is stored in two places.
        var constructorElement = ConstructorMember.from(
          rawElement,
          inferred.returnType as InterfaceType,
        );
        constructorName.staticElement = constructorElement;
      }
    }

    if (inferred == null) {
      var constructorElement = constructorName.staticElement;
      if (constructorElement != null) {
        var type = constructorElement.type;
        type = _resolver.toLegacyTypeIfOptOut(type) as FunctionType;
        InferenceContext.setType(node.argumentList, type);
      }
    }
  }

  void _resolveInstanceCreationExpression(InstanceCreationExpressionImpl node) {
    var whyNotPromotedList = <WhyNotPromotedGetter>[];
    node.constructorName.accept(_resolver);
    _inferArgumentTypes(node);
    _resolver.visitArgumentList(node.argumentList,
        whyNotPromotedList: whyNotPromotedList);
    node.accept(_resolver.elementResolver);
    node.accept(_resolver.typeAnalyzer);
    _resolver.checkForArgumentTypesNotAssignableInList(
        node.argumentList, whyNotPromotedList);
  }

  /// Resolve [node] which has a [NamedType] with type arguments (given as
  /// [typeNameTypeArguments]).
  ///
  /// The instance creation expression may actually be a method call on a
  /// type-instantiated function reference or constructor reference.
  void _resolveWithTypeNameWithTypeArguments(
    InstanceCreationExpressionImpl node,
    TypeArgumentListImpl typeNameTypeArguments,
  ) {
    var typeNameName = node.constructorName.type2.name;
    if (typeNameName is SimpleIdentifierImpl) {
      // TODO(srawlins): Lookup the name and potentially rewrite `node` as a
      // [MethodInvocation].
      _resolveInstanceCreationExpression(node);
      return;
    } else if (typeNameName is PrefixedIdentifierImpl) {
      // TODO(srawlins): Lookup the name and potentially rewrite `node` as a
      // [MethodInvocation].
      _resolveInstanceCreationExpression(node);
    } else {
      assert(
          false, 'Unexpected typeNameName type: ${typeNameName.runtimeType}');
      _resolveInstanceCreationExpression(node);
    }
  }
}
