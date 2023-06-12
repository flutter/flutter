// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class PrefixedIdentifierResolver {
  final ResolverVisitor _resolver;

  PrefixedIdentifierResolver(this._resolver);

  InvocationInferenceHelper get _inferenceHelper => _resolver.inferenceHelper;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  void resolve(PrefixedIdentifierImpl node) {
    node.prefix.accept(_resolver);

    var resolver = PropertyElementResolver(_resolver);
    var result = resolver.resolvePrefixedIdentifier(
      node: node,
      hasRead: true,
      hasWrite: false,
    );

    var element = result.readElement;

    var identifier = node.identifier;
    identifier.staticElement = element;

    if (element is ExtensionElement) {
      _setExtensionIdentifierType(node);
      return;
    }

    if (identical(node.prefix.staticType, NeverTypeImpl.instance)) {
      _recordStaticType(identifier, NeverTypeImpl.instance);
      _recordStaticType(node, NeverTypeImpl.instance);
      return;
    }

    DartType type = DynamicTypeImpl.instance;
    if (element is ClassElement) {
      if (_isExpressionIdentifier(node)) {
        var type = _typeProvider.typeType;
        node.staticType = type;
        identifier.staticType = type;
      }
      return;
    } else if (element is DynamicElementImpl) {
      var type = _typeProvider.typeType;
      node.staticType = type;
      identifier.staticType = type;
      return;
    } else if (element is TypeAliasElement) {
      if (node.parent is NamedType) {
        // no type
      } else {
        var type = _typeProvider.typeType;
        node.staticType = type;
        identifier.staticType = type;
      }
      return;
    } else if (element is MethodElement) {
      type = element.type;
    } else if (element is PropertyAccessorElement) {
      type = _getTypeOfProperty(element);
    } else if (element is ExecutableElement) {
      type = element.type;
    } else if (element is VariableElement) {
      type = element.type;
    } else if (result.functionTypeCallType != null) {
      type = result.functionTypeCallType!;
    }

    if (!_resolver.isConstructorTearoffsEnabled) {
      // Only perform a generic function instantiation on a [PrefixedIdentifier]
      // in pre-constructor-tearoffs code. In constructor-tearoffs-enabled code,
      // generic function instantiation is performed at assignability check
      // sites.
      // TODO(srawlins): Switch all resolution to use the latter method, in a
      // breaking change release.
      type = _inferenceHelper.inferTearOff(node, identifier, type);
    }
    _recordStaticType(identifier, type);
    _recordStaticType(node, type);
  }

  /// Return the type that should be recorded for a node that resolved to the given accessor.
  ///
  /// @param accessor the accessor that the node resolved to
  /// @return the type that should be recorded for a node that resolved to the given accessor
  ///
  /// TODO(scheglov) this is duplicate
  DartType _getTypeOfProperty(PropertyAccessorElement accessor) {
    FunctionType functionType = accessor.type;
    if (accessor.isSetter) {
      List<DartType> parameterTypes = functionType.normalParameterTypes;
      if (parameterTypes.isNotEmpty) {
        return parameterTypes[0];
      }
      var getter = accessor.variable.getter;
      if (getter != null) {
        functionType = getter.type;
        return functionType.returnType;
      }
      return DynamicTypeImpl.instance;
    }
    return functionType.returnType;
  }

  /// Return `true` if the given [node] is not a type literal.
  ///
  /// TODO(scheglov) this is duplicate
  bool _isExpressionIdentifier(Identifier node) {
    var parent = node.parent;
    if (node is SimpleIdentifier && node.inDeclarationContext()) {
      return false;
    }
    if (parent is ConstructorDeclaration) {
      if (parent.name == node || parent.returnType == node) {
        return false;
      }
    }
    if (parent is ConstructorName ||
        parent is MethodInvocation ||
        parent is PrefixedIdentifier && parent.prefix == node ||
        parent is PropertyAccess ||
        parent is NamedType) {
      return false;
    }
    return true;
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplicate
  void _recordStaticType(ExpressionImpl expression, DartType type) {
    _inferenceHelper.recordStaticType(expression, type);
  }

  /// TODO(scheglov) this is duplicate
  void _setExtensionIdentifierType(IdentifierImpl node) {
    if (node is SimpleIdentifierImpl && node.inDeclarationContext()) {
      return;
    }

    var parent = node.parent;

    if (parent is PrefixedIdentifierImpl && parent.identifier == node) {
      node = parent;
      parent = node.parent;
    }

    if (parent is CommentReference ||
        parent is ExtensionOverride && parent.extensionName == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixedIdentifierImpl && parent.prefix == node ||
        parent is PropertyAccess && parent.target == node) {
      return;
    }

    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.EXTENSION_AS_EXPRESSION,
      node,
      [node.name],
    );

    if (node is PrefixedIdentifierImpl) {
      node.identifier.staticType = DynamicTypeImpl.instance;
      node.staticType = DynamicTypeImpl.instance;
    } else if (node is SimpleIdentifier) {
      node.staticType = DynamicTypeImpl.instance;
    }
  }
}
