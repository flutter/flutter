// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
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

  void resolve(InstanceCreationExpressionImpl node,
      {required DartType? contextType}) {
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
      var typeNameTypeArguments = node.constructorName.type.typeArguments;
      if (typeNameTypeArguments != null) {
        // This could be a method call on a function reference or a constructor
        // reference.
        _resolveWithTypeNameWithTypeArguments(node, typeNameTypeArguments,
            contextType: contextType);
        return;
      }
    }

    _resolveInstanceCreationExpression(node, contextType: contextType);
  }

  void _resolveInstanceCreationExpression(InstanceCreationExpressionImpl node,
      {required DartType? contextType}) {
    var whyNotPromotedList = <WhyNotPromotedGetter>[];
    var constructorName = node.constructorName;
    constructorName.accept(_resolver);
    // Re-assign constructorName in case the node got replaced.
    constructorName = node.constructorName;
    _resolver.elementResolver.visitInstanceCreationExpression(node);
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      constructorName: constructorName,
      definingLibrary: _resolver.definingLibrary,
    );
    InstanceCreationInferrer(
            resolver: _resolver,
            node: node,
            argumentList: node.argumentList,
            contextType: contextType,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: elementToInfer?.asType);
    _resolver.inferenceHelper.recordStaticType(
        node, node.constructorName.type.type!,
        contextType: contextType);
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
      {required DartType? contextType}) {
    var typeNameName = node.constructorName.type.name;
    if (typeNameName is SimpleIdentifierImpl) {
      // TODO(srawlins): Lookup the name and potentially rewrite `node` as a
      // [MethodInvocation].
      _resolveInstanceCreationExpression(node, contextType: contextType);
      return;
    } else if (typeNameName is PrefixedIdentifierImpl) {
      // TODO(srawlins): Lookup the name and potentially rewrite `node` as a
      // [MethodInvocation].
      _resolveInstanceCreationExpression(node, contextType: contextType);
    } else {
      assert(
          false, 'Unexpected typeNameName type: ${typeNameName.runtimeType}');
      _resolveInstanceCreationExpression(node, contextType: contextType);
    }
  }
}
