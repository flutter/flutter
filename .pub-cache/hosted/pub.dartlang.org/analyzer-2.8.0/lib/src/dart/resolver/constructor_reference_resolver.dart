// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [ConstructorReference] nodes.
class ConstructorReferenceResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  ConstructorReferenceResolver(this._resolver);

  void resolve(ConstructorReferenceImpl node) {
    if (!_resolver.isConstructorTearoffsEnabled &&
        node.constructorName.type2.typeArguments == null) {
      // Only report this if [node] has no explicit type arguments; otherwise
      // the parser has already reported an error.
      _resolver.errorReporter.reportErrorForNode(
          HintCode.SDK_VERSION_CONSTRUCTOR_TEAROFFS, node, []);
    }
    node.constructorName.accept(_resolver);
    var element = node.constructorName.staticElement;
    if (element != null &&
        !element.isFactory &&
        element.enclosingElement.isAbstract) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode
            .TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS,
        node,
        [],
      );
    }
    var name = node.constructorName.name;
    if (element == null &&
        name != null &&
        _resolver.isConstructorTearoffsEnabled) {
      // The illegal construction, which looks like a type-instantiated
      // constructor tearoff, may be an attempt to reference a member on
      // [enclosingElement]. Try to provide a helpful error, and fall back to
      // "unknown constructor."
      //
      // Only report errors when the constructor tearoff feature is enabled,
      // to avoid reporting redundant errors.
      var enclosingElement = node.constructorName.type2.name.staticElement;
      if (enclosingElement is TypeAliasElement) {
        enclosingElement = enclosingElement.aliasedType.element;
      }
      // TODO(srawlins): Handle `enclosingElement` being a function typedef:
      // typedef F<T> = void Function(); var a = F<int>.extensionOnType;`.
      // This is illegal.
      if (enclosingElement is ClassElement) {
        var method = enclosingElement.getMethod(name.name) ??
            enclosingElement.getGetter(name.name) ??
            enclosingElement.getSetter(name.name);
        if (method != null) {
          var error = method.isStatic
              ? CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER
              : CompileTimeErrorCode
                  .CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER;
          _resolver.errorReporter.reportErrorForNode(
            error,
            node,
            [name.name],
          );
        } else if (!name.isSynthetic) {
          _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER,
            node,
            [enclosingElement.name, name.name],
          );
        }
      }
    }
    _inferArgumentTypes(node);
  }

  void _inferArgumentTypes(ConstructorReferenceImpl node) {
    var constructorName = node.constructorName;
    var elementToInfer = _resolver.inferenceHelper.constructorElementToInfer(
      constructorName: constructorName,
      definingLibrary: _resolver.definingLibrary,
    );

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

      var inferred = _resolver.inferenceHelper.inferTearOff(
          node, constructorName.name!, constructorType) as FunctionType?;

      if (inferred != null) {
        var inferredReturnType = inferred.returnType as InterfaceType;

        // Update the static element as well. This is used in some cases, such
        // as computing constant values. It is stored in two places.
        var constructorElement =
            ConstructorMember.from(rawElement, inferredReturnType);

        constructorName.staticElement = constructorElement.declaration;
        constructorName.name?.staticElement = constructorElement.declaration;
        node.staticType = inferred;
        // The NamedType child of `constructorName` doesn't have a static type.
        constructorName.type2.type = null;
      }
    } else {
      var constructorElement = constructorName.staticElement;
      if (constructorElement == null) {
        node.staticType = DynamicTypeImpl.instance;
      } else {
        node.staticType = constructorElement.type;
      }
      // The NamedType child of `constructorName` doesn't have a static type.
      constructorName.type2.type = null;
    }
  }
}
