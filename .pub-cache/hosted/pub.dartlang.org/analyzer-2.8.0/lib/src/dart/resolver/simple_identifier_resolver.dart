// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class SimpleIdentifierResolver {
  final ResolverVisitor _resolver;
  final FlowAnalysisHelper? _flowAnalysis;

  SimpleIdentifierResolver(this._resolver, this._flowAnalysis);

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  void resolve(SimpleIdentifierImpl node) {
    if (node.inDeclarationContext()) {
      return;
    }

    _resolver.checkUnreachableNode(node);

    _resolver.checkReadOfNotAssignedLocalVariable(node, node.staticElement);

    _resolve1(node);
    _resolve2(node);
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
      var parameterTypes = functionType.normalParameterTypes;
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

  /// Return `true` if the given [node] can validly be resolved to a prefix:
  /// * it is the prefix in an import directive, or
  /// * it is the prefix in a prefixed identifier.
  bool _isValidAsPrefix(SimpleIdentifier node) {
    var parent = node.parent;
    if (parent is ImportDirective) {
      return identical(parent.prefix, node);
    } else if (parent is PrefixedIdentifier) {
      return true;
    } else if (parent is MethodInvocation) {
      return identical(parent.target, node) &&
          parent.operator?.type == TokenType.PERIOD;
    }
    return false;
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplicate
  void _recordStaticType(ExpressionImpl expression, DartType type) {
    var hooks = _resolver.migrationResolutionHooks;
    if (hooks != null) {
      type = hooks.modifyExpressionType(expression, type);
    }

    expression.staticType = type;
    if (_resolver.typeSystem.isBottom(type)) {
      _flowAnalysis?.flow?.handleExit();
    }
  }

  void _resolve1(SimpleIdentifierImpl node) {
    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (node.isSynthetic) {
      return;
    }

    //
    // Ignore nodes that should have been resolved before getting here.
    //
    if (node.inDeclarationContext()) {
      return;
    }
    if (node.staticElement is LocalVariableElement ||
        node.staticElement is ParameterElement) {
      return;
    }
    var parent = node.parent;
    if (parent is FieldFormalParameter) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return;
    } else if (parent is Annotation && parent.constructorName == node) {
      return;
    }

    //
    // Otherwise, the node should be resolved.
    //

    // TODO(scheglov) Special-case resolution of ForStatement, don't use this.
    var hasRead = true;
    var hasWrite = false;
    {
      var parent = node.parent;
      if (parent is ForEachPartsWithIdentifier && parent.identifier == node) {
        hasRead = false;
        hasWrite = true;
      }
    }

    var resolver = PropertyElementResolver(_resolver);
    var result = resolver.resolveSimpleIdentifier(
      node: node,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );

    var element = hasRead ? result.readElement : result.writeElement;

    var enclosingClass = _resolver.enclosingClass;
    if (_isFactoryConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, node);
    } else if (_isConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      // This error is now reported by the parser.
      element = null;
    } else if ((element is PrefixElement?) &&
        (element == null || !_isValidAsPrefix(node))) {
      // TODO(brianwilkerson) Recover from this error.
      if (_isConstructorReturnType(node)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node);
      } else if (parent is Annotation) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_ANNOTATION, parent, [node.name]);
      } else if (element != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            node,
            [element.name]);
      } else if (node.name == "await" && _resolver.enclosingFunction != null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT,
          node,
        );
      } else if (!_resolver.definingLibrary
          .shouldIgnoreUndefinedIdentifier(node)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
          node,
          [node.name],
        );
      }
    }
    node.staticElement = element;
  }

  void _resolve2(SimpleIdentifierImpl node) {
    var element = node.staticElement;

    if (element is ExtensionElement) {
      _setExtensionIdentifierType(node);
      return;
    }

    DartType staticType = DynamicTypeImpl.instance;
    if (element is ClassElement) {
      if (_isExpressionIdentifier(node)) {
        node.staticType = _typeProvider.typeType;
      }
      return;
    } else if (element is TypeAliasElement) {
      if (_isExpressionIdentifier(node) ||
          element.aliasedType is! InterfaceType) {
        node.staticType = _typeProvider.typeType;
      }
      return;
    } else if (element is MethodElement) {
      staticType = element.type;
    } else if (element is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(element);
    } else if (element is ExecutableElement) {
      staticType = element.type;
    } else if (element is TypeParameterElement) {
      staticType = _typeProvider.typeType;
    } else if (element is VariableElement) {
      staticType = _resolver.localVariableTypeProvider
          .getType(node, isRead: node.inGetterContext());
    } else if (element is PrefixElement) {
      var parent = node.parent;
      if (parent is PrefixedIdentifier && parent.prefix == node ||
          parent is MethodInvocation && parent.target == node) {
        return;
      }
      staticType = _typeProvider.dynamicType;
    } else if (element is DynamicElementImpl) {
      staticType = _typeProvider.typeType;
    } else if (element is NeverElementImpl) {
      staticType = _typeProvider.typeType;
    } else {
      staticType = DynamicTypeImpl.instance;
    }

    if (!_resolver.isConstructorTearoffsEnabled) {
      // Only perform a generic function instantiation on a [PrefixedIdentifier]
      // in pre-constructor-tearoffs code. In constructor-tearoffs-enabled code,
      // generic function instantiation is performed at assignability check
      // sites.
      // TODO(srawlins): Switch all resolution to use the latter method, in a
      // breaking change release.
      staticType =
          _resolver.inferenceHelper.inferTearOff(node, node, staticType);
    }
    _recordStaticType(node, staticType);
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

  /// Return `true` if the given [identifier] is the return type of a
  /// constructor declaration.
  static bool _isConstructorReturnType(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      return identical(parent.returnType, identifier);
    }
    return false;
  }

  /// Return `true` if the given [identifier] is the return type of a factory
  /// constructor.
  static bool _isFactoryConstructorReturnType(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      return identical(parent.returnType, identifier) &&
          parent.factoryKeyword != null;
    }
    return false;
  }
}
