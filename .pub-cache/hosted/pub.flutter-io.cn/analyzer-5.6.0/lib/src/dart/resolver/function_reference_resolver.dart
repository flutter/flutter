// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// A resolver for [FunctionReference] nodes.
///
/// This resolver is responsible for writing a given [FunctionReference] as a
/// [ConstructorReference] or as a [TypeLiteral], depending on how a function
/// reference's `function` resolves.
class FunctionReferenceResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final bool _isNonNullableByDefault;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  FunctionReferenceResolver(this._resolver, this._isNonNullableByDefault)
      : _extensionResolver = _resolver.extensionResolver,
        _typeType = _resolver.typeProvider.typeType;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  NullabilitySuffix get _nullabilitySuffix =>
      _isNonNullableByDefault ? NullabilitySuffix.none : NullabilitySuffix.star;

  void resolve(FunctionReferenceImpl node) {
    var function = node.function;
    node.typeArguments?.accept(_resolver);

    if (function is SimpleIdentifierImpl) {
      _resolveSimpleIdentifierFunction(node, function);
    } else if (function is PrefixedIdentifierImpl) {
      _resolvePrefixedIdentifierFunction(node, function);
    } else if (function is PropertyAccessImpl) {
      _resolvePropertyAccessFunction(node, function);
    } else if (function is ConstructorReferenceImpl) {
      var typeArguments = node.typeArguments;
      if (typeArguments != null) {
        // Something like `List.filled<int>`.
        function.accept(_resolver);
        // We can safely assume `function.constructorName.name` is non-null
        // because if no name had been given, the construct would have been
        // interpreted as a type literal (e.g. `List<int>`).
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [
            function.constructorName.type.name.toSource(),
            function.constructorName.name!.name
          ],
        );
        _resolve(node: node, rawType: function.staticType);
      }
    } else {
      // TODO(srawlins): Handle `function` being a [SuperExpression].

      function.accept(_resolver);
      var functionType = function.staticType;
      if (functionType == null) {
        _resolveDisallowedExpression(node, functionType);
      } else if (functionType is FunctionType) {
        _resolve(node: node, rawType: functionType);
      } else {
        var callMethod = _getCallMethod(node, function.staticType);
        if (callMethod is MethodElement) {
          _resolveAsImplicitCallReference(node, callMethod);
          return;
        } else {
          _resolveDisallowedExpression(node, functionType);
        }
      }
    }
  }

  /// Checks for a type instantiation of a `dynamic`-typed expression.
  ///
  /// Returns `true` if an error was reported, and resolution can stop.
  bool _checkDynamicTypeInstantiation(FunctionReferenceImpl node,
      PrefixedIdentifierImpl function, Element prefixElement) {
    DartType? prefixType;
    if (prefixElement is VariableElement) {
      prefixType = prefixElement.type;
    } else if (prefixElement is PropertyAccessorElement) {
      prefixType = prefixElement.variable.type;
    }

    if (prefixType != null && prefixType.isDynamic) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
        function,
        [],
      );
      node.staticType = DynamicTypeImpl.instance;
      return true;
    }
    return false;
  }

  List<DartType> _checkTypeArguments(
    TypeArgumentList typeArgumentList,
    String? name,
    List<TypeParameterElement> typeParameters,
    CompileTimeErrorCode errorCode,
  ) {
    if (typeArgumentList.arguments.length != typeParameters.length) {
      if (name == null &&
          errorCode ==
              CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION) {
        errorCode = CompileTimeErrorCode
            .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION;
        _errorReporter.reportErrorForNode(
          errorCode,
          typeArgumentList,
          [typeParameters.length, typeArgumentList.arguments.length],
        );
      } else {
        assert(name != null);
        _errorReporter.reportErrorForNode(
          errorCode,
          typeArgumentList,
          [name!, typeParameters.length, typeArgumentList.arguments.length],
        );
      }
      return List.filled(typeParameters.length, DynamicTypeImpl.instance);
    } else {
      return typeArgumentList.arguments
          .map((typeAnnotation) => typeAnnotation.typeOrThrow)
          .toList();
    }
  }

  ExecutableElement? _getCallMethod(
      FunctionReferenceImpl node, DartType? type) {
    if (type is! InterfaceType) {
      return null;
    }
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      // If the interface type is nullable, only an applicable extension method
      // applies.
      return _extensionResolver
          .findExtension(type, node, FunctionElement.CALL_METHOD_NAME)
          .getter;
    }
    // Otherwise, a 'call' method on the interface, or on an applicable
    // extension method applies.
    return type.lookUpMethod2(
            FunctionElement.CALL_METHOD_NAME, type.element.library) ??
        _extensionResolver
            .findExtension(type, node, FunctionElement.CALL_METHOD_NAME)
            .getter;
  }

  void _reportInvalidAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element, {
    required bool implicitReceiver,
  }) {
    var enclosingElement = element.enclosingElement;
    if (implicitReceiver) {
      if (_resolver.enclosingExtension != null) {
        _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode
              .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
          nameNode,
          [enclosingElement.displayName],
        );
      } else {
        _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          nameNode,
          [enclosingElement.displayName],
        );
      }
    } else if (enclosingElement is ExtensionElement &&
        enclosingElement.name == null) {
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode
              .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
          nameNode,
          [
            nameNode.name,
            element.kind.displayName,
          ]);
    } else {
      // It is safe to assume that `enclosingElement.name` is non-`null` because
      // it can only be `null` for extensions, and we handle that case above.
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
        nameNode,
        [
          nameNode.name,
          element.kind.displayName,
          enclosingElement.name!,
          enclosingElement is MixinElement
              ? 'mixin'
              : enclosingElement.kind.displayName,
        ],
      );
    }
  }

  /// Resolves [node]'s static type, as an instantiated function type, and type
  /// argument types, using [rawType] as the uninstantiated function type.
  void _resolve({
    required FunctionReferenceImpl node,
    required DartType? rawType,
    String? name,
  }) {
    if (rawType == null) {
      node.staticType = DynamicTypeImpl.instance;
    }

    if (rawType is TypeParameterTypeImpl) {
      // If the type of the function is a type parameter, the tearoff is
      // disallowed, reported in [_resolveDisallowedExpression]. Use the type
      // parameter's bound here in an attempt to assign the intended types.
      rawType = rawType.element.bound;
    }

    if (rawType is FunctionType) {
      // A FunctionReference with type arguments and with a
      // ConstructorReference child is invalid. E.g. `List.filled<int>`.
      // [CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR] is
      // reported elsewhere; don't check type arguments here.
      if (node.function is ConstructorReference) {
        node.staticType = DynamicTypeImpl.instance;
      } else {
        var typeArguments = node.typeArguments;
        if (typeArguments == null) {
          node.staticType = rawType;
        } else {
          var typeArgumentTypes = _checkTypeArguments(
            typeArguments,
            name,
            rawType.typeFormals,
            CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION,
          );

          var invokeType = rawType.instantiate(typeArgumentTypes);
          node.typeArgumentTypes = typeArgumentTypes;
          node.staticType = invokeType;
        }
      }
    } else {
      if (_resolver.isConstructorTearoffsEnabled) {
        // Only report constructor tearoff-related errors if the constructor
        // tearoff feature is enabled.
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION,
          node.function,
          [],
        );
      }
      node.staticType = DynamicTypeImpl.instance;
    }
  }

  void _resolveAsImplicitCallReference(
      FunctionReferenceImpl node, MethodElement callMethod) {
    // `node<...>` is to be treated as `node.call<...>`.
    var callMethodType = callMethod.type;
    var typeArgumentTypes = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!, FunctionElement.CALL_METHOD_NAME,
      callMethodType.typeFormals,
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION,
    );
    var callReference = ImplicitCallReferenceImpl(
      expression: node.function,
      staticElement: callMethod,
      typeArguments: node.typeArguments,
      typeArgumentTypes: typeArgumentTypes,
    );
    _resolver.replaceExpression(node, callReference);
    var instantiatedType = callMethodType.instantiate(typeArgumentTypes);
    callReference.staticType = instantiatedType;
  }

  void _resolveConstructorReference(FunctionReferenceImpl node) {
    // TODO(srawlins): Rewrite and resolve [node] as a constructor reference.
    node.function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  /// Resolves [node] as a [TypeLiteral] referencing an interface type directly
  /// (not through a type alias).
  void _resolveDirectTypeLiteral(FunctionReferenceImpl node,
      IdentifierImpl name, InterfaceElement element) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!, name.name, element.typeParameters,
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
    );
    var type = element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _nullabilitySuffix,
    );
    _resolveTypeLiteral(node: node, instantiatedType: type, name: name);
  }

  /// Resolves [node] as a type instantiation on an illegal expression.
  ///
  /// This function attempts to give [node] a static type, to continue working
  /// with what the user may be intending.
  void _resolveDisallowedExpression(
      FunctionReferenceImpl node, DartType? rawType) {
    if (_resolver.isConstructorTearoffsEnabled) {
      // Only report constructor tearoff-related errors if the constructor
      // tearoff feature is enabled.
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION,
        node.function,
        [],
      );
    }
    _resolve(node: node, rawType: rawType);
  }

  void _resolveExtensionOverride(
    FunctionReferenceImpl node,
    PropertyAccessImpl function,
    ExtensionOverride override,
  ) {
    var propertyName = function.propertyName;
    var result =
        _extensionResolver.getOverrideMember(override, propertyName.name);
    var member = _resolver.toLegacyElement(result.getter);

    if (member == null) {
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    if (member.isStatic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        function.propertyName,
      );
      // Continue to resolve type.
    }

    if (function.isCascaded) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
        override.extensionName,
      );
      // Continue to resolve type.
    }

    if (member is PropertyAccessorElement) {
      function.accept(_resolver);
      _resolve(node: node, rawType: member.returnType);
      return;
    }

    _resolve(node: node, rawType: member.type, name: propertyName.name);
  }

  /// Resolve a possible function tearoff of a [FunctionElement] receiver.
  ///
  /// There are three possible valid cases: tearing off the `call` method of a
  /// function element, tearing off an extension element declared on [Function],
  /// and tearing off an extension element declared on a function type.
  Element? _resolveFunctionTypeFunction(
    Expression receiver,
    SimpleIdentifier methodName,
    FunctionType receiverType,
  ) {
    var methodElement = _resolver.typePropertyResolver
        .resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: methodName.name,
          propertyErrorEntity: methodName,
          nameErrorEntity: methodName,
        )
        .getter;
    if (methodElement != null && methodElement.isStatic) {
      _reportInvalidAccessToStaticMember(methodName, methodElement,
          implicitReceiver: false);
    }
    return methodElement;
  }

  void _resolvePrefixedIdentifierFunction(
      FunctionReferenceImpl node, PrefixedIdentifierImpl function) {
    var prefixElement = function.prefix.scopeLookupResult!.getter;

    if (prefixElement == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
        function.prefix,
        [function.name],
      );
      function.staticType = DynamicTypeImpl.instance;
      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    function.prefix.staticElement = prefixElement;
    function.prefix.staticType = prefixElement.referenceType;
    var functionName = function.identifier.name;

    if (prefixElement is PrefixElement) {
      var functionElement = prefixElement.scope.lookup(functionName).getter;
      if (functionElement == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME,
          function.identifier,
          [functionName, function.prefix.name],
        );
        function.staticType = DynamicTypeImpl.instance;
        node.staticType = DynamicTypeImpl.instance;
        return;
      } else {
        functionElement = _resolver.toLegacyElement(functionElement);
        _resolveReceiverPrefix(node, prefixElement, function, functionElement);
        return;
      }
    }

    if (_checkDynamicTypeInstantiation(node, function, prefixElement)) {
      return;
    }

    if (prefixElement is FunctionElement &&
        functionName == FunctionElement.CALL_METHOD_NAME) {
      _resolve(
        node: node,
        rawType: prefixElement.type,
        name: functionName,
      );
      return;
    }

    var propertyType = _resolveTypeProperty(
      receiver: function.prefix,
      name: function.identifier,
      nameErrorEntity: function,
    );

    var callMethod = _getCallMethod(node, propertyType);
    if (callMethod is MethodElement) {
      _resolveAsImplicitCallReference(node, callMethod);
      return;
    }

    if (propertyType is FunctionType) {
      function.staticType = propertyType;
      _resolve(
        node: node,
        rawType: propertyType,
        name: functionName,
      );
      return;
    }

    if (propertyType != null) {
      // If the property is unknown, [UNDEFINED_GETTER] is reported elsewhere.
      // If it is known, we must report the bad type instantiation here.
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION,
        function.identifier,
        [],
      );
    }
    function.accept(_resolver);
    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolvePropertyAccessFunction(
      FunctionReferenceImpl node, PropertyAccessImpl function) {
    function.accept(_resolver);
    var callMethod = _getCallMethod(node, function.staticType);
    if (callMethod is MethodElement) {
      _resolveAsImplicitCallReference(node, callMethod);
      return;
    }
    var target = function.realTarget;

    DartType targetType;
    if (target is SuperExpressionImpl) {
      targetType = target.typeOrThrow;
    } else if (target is ThisExpressionImpl) {
      targetType = target.typeOrThrow;
    } else if (target is SimpleIdentifierImpl) {
      var targetElement = target.scopeLookupResult!.getter;
      if (targetElement is VariableElement) {
        targetType = targetElement.type;
      } else if (targetElement is PropertyAccessorElement) {
        targetType = targetElement.variable.type;
      } else {
        // TODO(srawlins): Can we get here?
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
    } else if (target is ExtensionOverrideImpl) {
      _resolveExtensionOverride(node, function, target);
      return;
    } else {
      var targetType = target.staticType;
      if (targetType != null && targetType.isDynamic) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC,
          node,
          [],
        );
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
      var functionType = _resolveTypeProperty(
        receiver: target,
        name: function.propertyName,
        nameErrorEntity: function,
      );

      if (functionType is FunctionType) {
        function.staticType = functionType;
        _resolve(
          node: node,
          rawType: functionType,
          name: function.propertyName.name,
        );
        return;
      } else if (functionType != null) {
        // If the property is unknown, [UNDEFINED_GETTER] is reported elsewhere.
        // If it is known, we must report the bad type instantiation here.
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION,
          function.propertyName,
          [],
        );
      }

      node.staticType = DynamicTypeImpl.instance;
      return;
    }

    var propertyElement = _resolver.typePropertyResolver
        .resolve(
          receiver: function.realTarget,
          receiverType: targetType,
          name: function.propertyName.name,
          propertyErrorEntity: function.propertyName,
          nameErrorEntity: function,
        )
        .getter;

    if (propertyElement is TypeParameterElement) {
      _resolve(node: node, rawType: propertyElement!.type);
      return;
    }

    _resolve(
      node: node,
      rawType: function.staticType,
      name: propertyElement?.name,
    );
  }

  void _resolveReceiverPrefix(
    FunctionReferenceImpl node,
    PrefixElement prefixElement,
    PrefixedIdentifierImpl prefix,
    Element element,
  ) {
    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];

      // TODO(srawlins): Add a resolution test for this case.
    }

    // Classes and type aliases are checked first so as to include a
    // PropertyAccess parent check, which does not need to be done for
    // functions.
    if (element is InterfaceElement || element is TypeAliasElement) {
      // A type-instantiated constructor tearoff like `prefix.C<int>.name` is
      // initially represented as a [PropertyAccess] with a
      // [FunctionReference] 'target'.
      if (node.parent is PropertyAccess) {
        _resolveConstructorReference(node);
        return;
      } else if (element is InterfaceElement) {
        node.function.accept(_resolver);
        _resolveDirectTypeLiteral(node, prefix, element);
        return;
      } else if (element is TypeAliasElement) {
        prefix.accept(_resolver);
        _resolveTypeAlias(node: node, element: element, typeAlias: prefix);
        return;
      }
    } else if (element is ExecutableElement) {
      node.function.accept(_resolver);
      var callMethod = _getCallMethod(node, node.function.staticType);
      if (callMethod is MethodElement) {
        _resolveAsImplicitCallReference(node, callMethod);
        return;
      }
      _resolve(
        node: node,
        rawType: node.function.typeOrThrow as FunctionType,
        name: element.name,
      );
      return;
    } else if (element is ExtensionElement) {
      prefix.identifier.staticElement = element;
      prefix.identifier.staticType = DynamicTypeImpl.instance;
      prefix.staticType = DynamicTypeImpl.instance;
      _resolveDisallowedExpression(node, DynamicTypeImpl.instance);
      return;
    }

    assert(
      false,
      'Member of prefixed element, $prefixElement, is not a class, mixin, '
      'type alias, or executable element: $element (${element.runtimeType})',
    );
    node.staticType = DynamicTypeImpl.instance;
  }

  void _resolveSimpleIdentifierFunction(
      FunctionReferenceImpl node, SimpleIdentifierImpl function) {
    var element = function.scopeLookupResult!.getter;

    if (element == null) {
      DartType receiverType;
      var enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        receiverType = enclosingClass.thisType;
      } else {
        var enclosingExtension = _resolver.enclosingExtension;
        if (enclosingExtension != null) {
          receiverType = enclosingExtension.extendedType;
        } else {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
            function,
            [function.name],
          );
          function.staticType = DynamicTypeImpl.instance;
          node.staticType = DynamicTypeImpl.instance;
          return;
        }
      }

      var result = _resolver.typePropertyResolver.resolve(
        receiver: null,
        receiverType: receiverType,
        name: function.name,
        propertyErrorEntity: function,
        nameErrorEntity: function,
      );

      var method = result.getter;
      if (method != null) {
        if (method.isStatic) {
          _reportInvalidAccessToStaticMember(function, method,
              implicitReceiver: true);
          // Continue to assign types.
        }

        if (method is PropertyAccessorElement) {
          function.staticElement = method;
          function.staticType = method.returnType;
          _resolve(node: node, rawType: method.variable.type);
          return;
        }

        function.staticElement = method;
        function.staticType = method.type;
        _resolve(node: node, rawType: method.type, name: function.name);
        return;
      } else {
        _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_METHOD,
          function,
          [function.name, receiverType],
        );
        function.staticType = DynamicTypeImpl.instance;
        node.staticType = DynamicTypeImpl.instance;
        return;
      }
    }

    // Classes and type aliases are checked first so as to include a
    // PropertyAccess parent check, which does not need to be done for
    // functions.
    if (element is InterfaceElement || element is TypeAliasElement) {
      // A type-instantiated constructor tearoff like `C<int>.name` or
      // `prefix.C<int>.name` is initially represented as a [PropertyAccess]
      // with a [FunctionReference] target.
      if (node.parent is PropertyAccess) {
        if (element is TypeAliasElement &&
            element.aliasedType is FunctionType) {
          function.staticElement = element;
          _resolveTypeAlias(node: node, element: element, typeAlias: function);
        } else {
          _resolveConstructorReference(node);
        }
        return;
      } else if (element is InterfaceElement) {
        function.staticElement = element;
        _resolveDirectTypeLiteral(node, function, element);
        return;
      } else if (element is TypeAliasElement) {
        function.staticElement = element;
        _resolveTypeAlias(node: node, element: element, typeAlias: function);
        return;
      }
    } else if (element is MethodElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolve(node: node, rawType: element.type, name: element.name);
      return;
    } else if (element is FunctionElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolve(node: node, rawType: element.type, name: element.name);
      return;
    } else if (element is PropertyAccessorElement) {
      function.staticElement = element;
      function.staticType = element.variable.type;
      var callMethod = _getCallMethod(node, element.variable.type);
      if (callMethod is MethodElement) {
        _resolveAsImplicitCallReference(node, callMethod);
        return;
      }
      _resolve(node: node, rawType: element.returnType);
      return;
    } else if (element is ExecutableElement) {
      function.staticElement = element;
      function.staticType = element.type;
      _resolve(node: node, rawType: element.type);
      return;
    } else if (element is VariableElement) {
      function.staticElement = element;
      function.staticType = element.type;
      var callMethod = _getCallMethod(node, element.type);
      if (callMethod is MethodElement) {
        _resolveAsImplicitCallReference(node, callMethod);
        return;
      }
      _resolve(node: node, rawType: element.type);
      return;
    } else if (element is ExtensionElement) {
      function.staticElement = element;
      function.staticType = DynamicTypeImpl.instance;
      _resolveDisallowedExpression(node, DynamicTypeImpl.instance);
      return;
    } else {
      _resolveDisallowedExpression(node, DynamicTypeImpl.instance);
      return;
    }
  }

  /// Returns the element that represents the property named [propertyName] on
  /// [classElement].
  ExecutableElement? _resolveStaticElement(
      InterfaceElement classElement, SimpleIdentifier propertyName) {
    String name = propertyName.name;
    ExecutableElement? element;
    if (propertyName.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    element ??= classElement.getGetter(name);
    element ??= classElement.getMethod(name);
    if (element != null && element.isAccessibleIn(_resolver.definingLibrary)) {
      return element;
    }
    return null;
  }

  void _resolveTypeAlias({
    required FunctionReferenceImpl node,
    required TypeAliasElement element,
    required IdentifierImpl typeAlias,
  }) {
    var typeArguments = _checkTypeArguments(
      // `node.typeArguments`, coming from the parser, is never null.
      node.typeArguments!, element.name, element.typeParameters,
      CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
    );
    var type = element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: _nullabilitySuffix,
    );
    _resolveTypeLiteral(node: node, instantiatedType: type, name: typeAlias);
  }

  void _resolveTypeLiteral({
    required FunctionReferenceImpl node,
    required DartType instantiatedType,
    required IdentifierImpl name,
  }) {
    // TODO(srawlins): set the static element of [typeName].
    // This involves a fair amount of resolution, as [name] may be a prefixed
    // identifier, etc. [TypeName]s should be resolved in [ResolutionVisitor],
    // and this could be done for nodes like this via [AstRewriter].
    var typeName = NamedTypeImpl(
      name: name,
      typeArguments: node.typeArguments,
      question: null,
    );
    typeName.type = instantiatedType;
    typeName.name.staticType = instantiatedType;
    var typeLiteral = TypeLiteralImpl(
      typeName: typeName,
    );
    typeLiteral.staticType = _typeType;
    _resolver.replaceExpression(node, typeLiteral);
  }

  /// Resolves [name] as a property on [receiver].
  ///
  /// Returns `null` if [receiver]'s type is `null`, a [TypeParameterType],
  /// or a type alias for a non-interface type.
  DartType? _resolveTypeProperty({
    required Expression receiver,
    required SimpleIdentifierImpl name,
    required SyntacticEntity nameErrorEntity,
  }) {
    if (receiver is Identifier) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is InterfaceElement) {
        var element = _resolveStaticElement(receiverElement, name);
        name.staticElement = element;
        return element?.referenceType;
      } else if (receiverElement is TypeAliasElement) {
        var aliasedType = receiverElement.aliasedType;
        if (aliasedType is InterfaceType) {
          var element = _resolveStaticElement(aliasedType.element, name);
          name.staticElement = element;
          return element?.referenceType;
        } else {
          return null;
        }
      }
    }

    var receiverType = receiver.staticType;
    if (receiverType == null) {
      return null;
    } else if (receiverType is TypeParameterType) {
      return null;
    } else if (receiverType is FunctionType) {
      if (name.name == FunctionElement.CALL_METHOD_NAME) {
        return receiverType;
      }
      var element = _resolveFunctionTypeFunction(receiver, name, receiverType);
      name.staticElement = element;
      return element?.referenceType;
    }

    var element = _resolver.typePropertyResolver
        .resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: name.name,
          propertyErrorEntity: name,
          nameErrorEntity: nameErrorEntity,
        )
        .getter;
    name.staticElement = element;
    if (element != null && element.isStatic) {
      _reportInvalidAccessToStaticMember(name, element,
          implicitReceiver: false);
    }
    return element?.referenceType;
  }
}

extension on Element {
  /// Returns the 'type' of `this`, when accessed as a "reference", not
  /// immediately followed by parentheses and arguments.
  ///
  /// For all elements that don't have a type (for example, [LibraryExportElement]),
  /// `null` is returned. For [PropertyAccessorElement], the return value is
  /// returned. For all other elements, their `type` property is returned.
  DartType? get referenceType {
    if (this is ConstructorElement) {
      return (this as ConstructorElement).type;
    } else if (this is FunctionElement) {
      return (this as FunctionElement).type;
    } else if (this is PropertyAccessorElement) {
      return (this as PropertyAccessorElement).returnType;
    } else if (this is MethodElement) {
      return (this as MethodElement).type;
    } else if (this is VariableElement) {
      return (this as VariableElement).type;
    } else {
      return null;
    }
  }
}
