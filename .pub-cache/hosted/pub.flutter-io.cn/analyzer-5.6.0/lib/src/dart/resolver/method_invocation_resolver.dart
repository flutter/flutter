// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

class MethodInvocationResolver with ScopeHelpers {
  /// Resolver visitor is separated from the elements resolver, which calls
  /// this method resolver. If we rewrite a [MethodInvocation] node, we put
  /// the resulting [FunctionExpressionInvocation] into the original node
  /// under this key.
  static const _rewriteResultKey = 'methodInvocationRewriteResult';

  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The type representing the type 'dynamic'.
  final DynamicTypeImpl _dynamicType = DynamicTypeImpl.instance;

  /// The type representing the type 'type'.
  final InterfaceType _typeType;

  /// The manager for the inheritance mappings.
  final InheritanceManager3 _inheritance;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl _definingLibrary;

  /// The URI of [_definingLibrary].
  final Uri _definingLibraryUri;

  /// The object providing promoted or declared types of variables.
  final LocalVariableTypeProvider _localVariableTypeProvider;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  final InvocationInferenceHelper _inferenceHelper;

  final MigratableAstInfoProvider _migratableAstInfoProvider;

  /// The invocation being resolved.
  MethodInvocationImpl? _invocation;

  /// The [Name] object of the invocation being resolved by [resolve].
  Name? _currentName;

  MethodInvocationResolver(
    this._resolver,
    this._migratableAstInfoProvider, {
    required InvocationInferenceHelper inferenceHelper,
  })  : _typeType = _resolver.typeProvider.typeType,
        _inheritance = _resolver.inheritance,
        _definingLibrary = _resolver.definingLibrary,
        _definingLibraryUri = _resolver.definingLibrary.source.uri,
        _localVariableTypeProvider = _resolver.localVariableTypeProvider,
        _extensionResolver = _resolver.extensionResolver,
        _inferenceHelper = inferenceHelper;

  @override
  ErrorReporter get errorReporter => _resolver.errorReporter;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    _invocation = node;

    var nameNode = node.methodName;
    String name = nameNode.name;
    _currentName = Name(_definingLibraryUri, name);

    var receiver = node.realTarget;

    if (receiver == null) {
      _resolveReceiverNull(node, nameNode, name, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (receiver is SimpleIdentifierImpl) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is PrefixElement) {
        _resolveReceiverPrefix(
            node, receiverElement, nameNode, name, whyNotPromotedList,
            contextType: contextType);
        return;
      }
    }

    if (receiver is IdentifierImpl) {
      var receiverElement = receiver.staticElement;
      if (receiverElement is ExtensionElement) {
        _resolveExtensionMember(
            node, receiver, receiverElement, nameNode, name, whyNotPromotedList,
            contextType: contextType);
        return;
      }
    }

    if (receiver is SuperExpressionImpl) {
      _resolveReceiverSuper(node, receiver, nameNode, name, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (receiver is ExtensionOverrideImpl) {
      _resolveExtensionOverride(
          node, receiver, nameNode, name, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (receiver is IdentifierImpl) {
      var element = receiver.staticElement;
      if (element is InterfaceElement) {
        _resolveReceiverTypeLiteral(
            node, element, nameNode, name, whyNotPromotedList,
            contextType: contextType);
        return;
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          _resolveReceiverTypeLiteral(
              node, aliasedType.element, nameNode, name, whyNotPromotedList,
              contextType: contextType);
          return;
        }
      }
    }

    DartType receiverType = receiver.typeOrThrow;

    if (_typeSystem.isDynamicBounded(receiverType)) {
      _resolveReceiverDynamicBounded(node, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (receiverType is NeverTypeImpl) {
      _resolveReceiverNever(node, receiver, receiverType, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (receiverType is VoidType) {
      _reportUseOfVoidType(node, receiver, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (_migratableAstInfoProvider.isMethodInvocationNullAware(node) &&
        _typeSystem.isNonNullableByDefault) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    if (receiver is TypeLiteralImpl &&
        receiver.type.typeArguments != null &&
        receiver.type.type is FunctionType) {
      // There is no possible resolution for a property access of a function
      // type literal (which can only be a type instantiation of a type alias
      // of a function type).
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE,
        nameNode,
        [name, receiver.type.name.name],
      );
      _setDynamicResolution(node,
          whyNotPromotedList: whyNotPromotedList, contextType: contextType);
      return;
    }

    _resolveReceiverType(
      node: node,
      receiver: receiver,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: receiver,
      whyNotPromotedList: whyNotPromotedList,
      contextType: contextType,
    );
  }

  bool _isCoreFunction(DartType type) {
    // TODO(scheglov) Can we optimize this?
    return type is InterfaceType && type.isDartCoreFunction;
  }

  void _reportInstanceAccessToStaticMember(
    SimpleIdentifier nameNode,
    ExecutableElement element,
    bool nullReceiver,
  ) {
    var enclosingElement = element.enclosingElement;
    if (nullReceiver) {
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

  void _reportInvocationOfNonFunction(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    _setDynamicResolution(node,
        setNameTypeToDynamic: false,
        whyNotPromotedList: whyNotPromotedList,
        contextType: contextType);
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION,
      node.methodName,
      [node.methodName.name],
    );
  }

  void _reportPrefixIdentifierNotFollowedByDot(SimpleIdentifier target) {
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
      target,
      [target.name],
    );
  }

  void _reportStaticAccessToInstanceMember(
      ExecutableElement element, SimpleIdentifier nameNode) {
    if (!element.isStatic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
        nameNode,
        [nameNode.name],
      );
    }
  }

  void _reportUndefinedFunction(
    MethodInvocationImpl node, {
    required String? prefix,
    required String name,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
    required DartType? contextType,
  }) {
    _setDynamicResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);

    if (_definingLibrary.shouldIgnoreUndefined(prefix: prefix, name: name)) {
      return;
    }

    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.UNDEFINED_FUNCTION,
      node.methodName,
      [node.methodName.name],
    );
  }

  void _reportUseOfVoidType(MethodInvocationImpl node, AstNode errorNode,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    _setDynamicResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.USE_OF_VOID_RESULT,
      errorNode,
    );
  }

  void _resolveArguments_finishInference(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    var rawType = node.methodName.staticType;
    DartType staticStaticType = MethodInvocationInferrer(
            resolver: _resolver,
            node: node,
            argumentList: node.argumentList,
            contextType: contextType,
            whyNotPromotedList: whyNotPromotedList)
        .resolveInvocation(rawType: rawType is FunctionType ? rawType : null);
    _inferenceHelper.recordStaticType(node, staticStaticType,
        contextType: contextType);
  }

  /// Given that we are accessing a property of the given [classElement] with the
  /// given [propertyName], return the element that represents the property.
  Element? _resolveElement(
      InterfaceElement classElement, SimpleIdentifier propertyName) {
    // TODO(scheglov) Replace with class hierarchy.
    String name = propertyName.name;
    Element? element;
    if (propertyName.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    element ??= classElement.getGetter(name);
    element ??= classElement.getMethod(name);
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  void _resolveExtensionMember(
      MethodInvocationImpl node,
      Identifier receiver,
      ExtensionElement extension,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    var getter = extension.getGetter(name);
    if (getter != null) {
      getter = _resolver.toLegacyElement(getter);
      nameNode.staticElement = getter;
      _reportStaticAccessToInstanceMember(getter, nameNode);
      _rewriteAsFunctionExpressionInvocation(node, getter.returnType,
          contextType: contextType);
      return;
    }

    var method = extension.getMethod(name);
    if (method != null) {
      method = _resolver.toLegacyElement(method);
      nameNode.staticElement = method;
      _reportStaticAccessToInstanceMember(method, nameNode);
      _setResolution(node, method.type, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    _setDynamicResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    // This method is only called for named extensions, so we know that
    // `extension.name` is non-`null`.
    _resolver.errorReporter.reportErrorForNode(
      CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
      nameNode,
      [name, extension.name!],
    );
  }

  void _resolveExtensionOverride(
      MethodInvocationImpl node,
      ExtensionOverride override,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    var result = _extensionResolver.getOverrideMember(override, name);
    var member = _resolver.toLegacyElement(result.getter);

    if (member == null) {
      _setDynamicResolution(node,
          whyNotPromotedList: whyNotPromotedList, contextType: contextType);
      // Extension overrides always refer to named extensions, so we can safely
      // assume `override.staticElement!.name` is non-`null`.
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD,
        nameNode,
        [name, override.staticElement!.name!],
      );
      return;
    }

    if (member.isStatic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        nameNode,
      );
    }

    if (node.isCascaded) {
      // Report this error and recover by treating it like a non-cascade.
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
        override.extensionName,
      );
    }

    nameNode.staticElement = member;

    if (member is PropertyAccessorElement) {
      return _rewriteAsFunctionExpressionInvocation(node, member.returnType,
          contextType: contextType);
    }

    _setResolution(node, member.type, whyNotPromotedList,
        contextType: contextType);
  }

  void _resolveReceiverDynamicBounded(
      MethodInvocationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    var nameNode = node.methodName;

    var objectElement = _typeSystem.typeProvider.objectElement;
    var target = objectElement.getMethod(nameNode.name);

    FunctionType? rawType;
    if (target is MethodElement && !target.isStatic) {
      var arguments = node.argumentList.arguments;
      var hasMatchingObjectMethod =
          arguments.length == target.parameters.length &&
              !arguments.any((e) => e is NamedExpression);
      if (hasMatchingObjectMethod) {
        target = _resolver.toLegacyElement(target);
        nameNode.staticElement = target;
        rawType = target.type;
        node.staticType = target.returnType;
      }
    }

    if (rawType == null) {
      nameNode.staticType = DynamicTypeImpl.instance;
      node.staticType = DynamicTypeImpl.instance;
    }

    _setExplicitTypeArgumentTypes();
    MethodInvocationInferrer(
            resolver: _resolver,
            node: node,
            argumentList: node.argumentList,
            whyNotPromotedList: whyNotPromotedList,
            contextType: contextType)
        .resolveInvocation(rawType: rawType);
  }

  void _resolveReceiverNever(MethodInvocationImpl node, Expression receiver,
      DartType receiverType, List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    _setExplicitTypeArgumentTypes();

    if (receiverType == NeverTypeImpl.instanceNullable) {
      var methodName = node.methodName;
      var objectElement = _resolver.typeProvider.objectElement;
      var objectMember = objectElement.getMethod(methodName.name);
      if (objectMember != null) {
        objectMember = _resolver.toLegacyElement(objectMember);
        methodName.staticElement = objectMember;
        _setResolution(
          node,
          objectMember.type,
          whyNotPromotedList,
          contextType: contextType,
        );
      } else {
        _setDynamicResolution(node,
            whyNotPromotedList: whyNotPromotedList, contextType: contextType);
        _resolver.nullableDereferenceVerifier.report(
          CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          methodName,
          receiverType,
        );
      }
      return;
    }

    if (receiverType == NeverTypeImpl.instance) {
      node.methodName.staticType = _dynamicType;
      node.staticInvokeType = _dynamicType;
      node.staticType = NeverTypeImpl.instance;

      MethodInvocationInferrer(
              resolver: _resolver,
              node: node,
              argumentList: node.argumentList,
              contextType: contextType,
              whyNotPromotedList: whyNotPromotedList)
          .resolveInvocation(rawType: null);

      _resolver.errorReporter.reportErrorForNode(
        WarningCode.RECEIVER_OF_TYPE_NEVER,
        receiver,
      );
      return;
    }

    if (receiverType == NeverTypeImpl.instanceLegacy) {
      node.methodName.staticType = _dynamicType;
      node.staticInvokeType = _dynamicType;
      node.staticType = _dynamicType;

      MethodInvocationInferrer(
              resolver: _resolver,
              node: node,
              argumentList: node.argumentList,
              contextType: contextType,
              whyNotPromotedList: whyNotPromotedList)
          .resolveInvocation(rawType: null);
      return;
    }
  }

  void _resolveReceiverNull(
      MethodInvocationImpl node,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    final scopeLookupResult = nameNode.scopeLookupResult!;
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      node: nameNode,
    );

    var element = scopeLookupResult.getter;
    if (element != null) {
      element = _resolver.toLegacyElement(element);
      nameNode.staticElement = element;
      if (element is MultiplyDefinedElement) {
        MultiplyDefinedElement multiply = element;
        element = multiply.conflictingElements[0];
      }
      if (element is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, element.returnType,
            contextType: contextType);
      }
      if (element is ExecutableElement) {
        return _setResolution(node, element.type, whyNotPromotedList,
            contextType: contextType);
      }
      if (element is VariableElement) {
        _resolver.checkReadOfNotAssignedLocalVariable(nameNode, element);
        var targetType =
            _localVariableTypeProvider.getType(nameNode, isRead: true);
        return _rewriteAsFunctionExpressionInvocation(node, targetType,
            contextType: contextType);
      }
      // TODO(scheglov) This is a questionable distinction.
      if (element is PrefixElement) {
        _setDynamicResolution(node,
            whyNotPromotedList: whyNotPromotedList, contextType: contextType);
        return _reportPrefixIdentifierNotFollowedByDot(nameNode);
      }
      return _reportInvocationOfNonFunction(node, whyNotPromotedList,
          contextType: contextType);
    }

    DartType receiverType;
    if (_resolver.enclosingClass != null) {
      receiverType = _resolver.enclosingClass!.thisType;
    } else if (_resolver.enclosingExtension != null) {
      receiverType = _resolver.enclosingExtension!.extendedType;
    } else {
      return _reportUndefinedFunction(
        node,
        prefix: null,
        name: node.methodName.name,
        whyNotPromotedList: whyNotPromotedList,
        contextType: contextType,
      );
    }

    _resolveReceiverType(
      node: node,
      receiver: null,
      receiverType: receiverType,
      nameNode: nameNode,
      name: name,
      receiverErrorNode: nameNode,
      whyNotPromotedList: whyNotPromotedList,
      contextType: contextType,
    );
  }

  void _resolveReceiverPrefix(
      MethodInvocationImpl node,
      PrefixElement prefix,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    // Note: prefix?.bar is reported as an error in ElementResolver.

    if (name == FunctionElement.LOAD_LIBRARY_NAME) {
      var imports = prefix.imports;
      if (imports.length == 1 &&
          imports[0].prefix is DeferredImportElementPrefix) {
        var importedLibrary = imports[0].importedLibrary;
        var element = importedLibrary?.loadLibraryFunction;
        element = _resolver.toLegacyElement(element);
        if (element is ExecutableElement) {
          nameNode.staticElement = element;
          return _setResolution(
              node, (element as ExecutableElement).type, whyNotPromotedList,
              contextType: contextType);
        }
      }
    }

    final scopeLookupResult = prefix.scope.lookup(name);
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      node: nameNode,
    );

    var element = scopeLookupResult.getter;
    element = _resolver.toLegacyElement(element);
    nameNode.staticElement = element;

    if (element is MultiplyDefinedElement) {
      MultiplyDefinedElement multiply = element;
      element = multiply.conflictingElements[0];
    }

    if (element is PropertyAccessorElement) {
      return _rewriteAsFunctionExpressionInvocation(node, element.returnType,
          contextType: contextType);
    }

    if (element is ExecutableElement) {
      return _setResolution(node, element.type, whyNotPromotedList,
          contextType: contextType);
    }

    _reportUndefinedFunction(
      node,
      prefix: prefix.name,
      name: name,
      whyNotPromotedList: whyNotPromotedList,
      contextType: contextType,
    );
  }

  void _resolveReceiverSuper(
      MethodInvocationImpl node,
      SuperExpression receiver,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    var enclosingClass = _resolver.enclosingClass;
    if (SuperContext.of(receiver) != SuperContext.valid) {
      _setDynamicResolution(node,
          whyNotPromotedList: whyNotPromotedList, contextType: contextType);
      return;
    }

    var target = _inheritance.getMember2(
      enclosingClass!,
      _currentName!,
      forSuper: true,
    );
    target = _resolver.toLegacyElement(target);

    // If there is that concrete dispatch target, then we are done.
    if (target != null) {
      nameNode.staticElement = target;
      if (target is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, target.returnType,
            contextType: contextType);
      }
      _setResolution(node, target.type, whyNotPromotedList,
          contextType: contextType);
      return;
    }

    // Otherwise, this is an error.
    // But we would like to give the user at least some resolution.
    // So, we try to find the interface target.
    target = _inheritance.getInherited2(enclosingClass, _currentName!);
    if (target != null) {
      nameNode.staticElement = target;
      _setResolution(node, target.type, whyNotPromotedList,
          contextType: contextType);

      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
          nameNode,
          [target.kind.displayName, name]);
      return;
    }

    // Nothing help, there is no target at all.
    _setDynamicResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_SUPER_METHOD,
        nameNode,
        [name, enclosingClass.displayName]);
  }

  void _resolveReceiverType({
    required MethodInvocationImpl node,
    required Expression? receiver,
    required DartType receiverType,
    required SimpleIdentifierImpl nameNode,
    required String name,
    required Expression receiverErrorNode,
    required List<WhyNotPromotedGetter> whyNotPromotedList,
    required DartType? contextType,
  }) {
    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: name,
      propertyErrorEntity: nameNode,
      nameErrorEntity: nameNode,
    );

    final callFunctionType = result.callFunctionType;
    if (callFunctionType != null) {
      assert(name == FunctionElement.CALL_METHOD_NAME);
      _setResolution(node, callFunctionType, whyNotPromotedList,
          contextType: contextType);
      // TODO(scheglov) Replace this with using FunctionType directly.
      // Here was erase resolution that _setResolution() sets.
      nameNode.staticElement = null;
      nameNode.staticType = _dynamicType;
      return;
    }

    final recordField = result.recordField;
    if (recordField != null) {
      return _rewriteAsFunctionExpressionInvocation(node, recordField.type,
          contextType: contextType);
    }

    var target = result.getter;
    if (target != null) {
      nameNode.staticElement = target;

      if (target.isStatic) {
        _reportInstanceAccessToStaticMember(
          nameNode,
          target,
          receiver == null,
        );
      }

      if (target is PropertyAccessorElement) {
        return _rewriteAsFunctionExpressionInvocation(node, target.returnType,
            contextType: contextType);
      }
      return _setResolution(node, target.type, whyNotPromotedList,
          contextType: contextType);
    }

    _setDynamicResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);

    if (!result.needsGetterError) {
      return;
    }

    String receiverClassName = '<unknown>';
    if (receiverType is InterfaceType) {
      receiverClassName = receiverType.element.name;
    } else if (receiverType is FunctionType) {
      receiverClassName = 'Function';
    }

    if (!nameNode.isSynthetic) {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_METHOD,
        nameNode,
        [name, receiverClassName],
      );
    }
  }

  void _resolveReceiverTypeLiteral(
      MethodInvocationImpl node,
      InterfaceElement receiver,
      SimpleIdentifierImpl nameNode,
      String name,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    if (node.isCascaded) {
      receiver = _typeType.element;
    }

    var element = _resolveElement(receiver, nameNode);
    element = _resolver.toLegacyElement(element) as ExecutableElement?;
    if (element != null) {
      if (element is ExecutableElement) {
        nameNode.staticElement = element;
        if (element is PropertyAccessorElement) {
          return _rewriteAsFunctionExpressionInvocation(
              node, element.returnType,
              contextType: contextType);
        }
        _setResolution(node, element.type, whyNotPromotedList,
            contextType: contextType);
      } else {
        _reportInvocationOfNonFunction(node, whyNotPromotedList,
            contextType: contextType);
      }
      return;
    }

    _setDynamicResolution(node,
        whyNotPromotedList: whyNotPromotedList, contextType: contextType);
    if (nameNode.name == 'new') {
      // Attempting to invoke the unnamed constructor via `C.new(`.
      if (_resolver.isConstructorTearoffsEnabled) {
        _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
          nameNode,
          [receiver.displayName],
        );
      } else {
        // [ParserErrorCode.EXPERIMENT_NOT_ENABLED] is reported by the parser.
        // Do not report extra errors.
      }
    } else {
      _resolver.errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_METHOD,
        node.methodName,
        [name, receiver.displayName],
      );
    }
  }

  /// We have identified that [node] is not a real [MethodInvocation],
  /// because it does not invoke a method, but instead invokes the result
  /// of a getter execution, or implicitly invokes the `call` method of
  /// an [InterfaceType]. So, it should be represented as instead as a
  /// [FunctionExpressionInvocation].
  void _rewriteAsFunctionExpressionInvocation(
      MethodInvocationImpl node, DartType getterReturnType,
      {required DartType? contextType}) {
    var targetType = _typeSystem.resolveToBound(getterReturnType);

    ExpressionImpl functionExpression;
    var target = node.target;
    if (target == null) {
      functionExpression = node.methodName;
      targetType = _resolver.flowAnalysis.flow?.thisOrSuperPropertyGet(
              functionExpression,
              node.methodName.name,
              node.methodName.staticElement,
              getterReturnType) ??
          targetType;
    } else {
      if (target is SimpleIdentifierImpl &&
          target.staticElement is PrefixElement) {
        functionExpression = PrefixedIdentifierImpl(
          prefix: target,
          period: node.operator!,
          identifier: node.methodName,
        );
      } else {
        functionExpression = PropertyAccessImpl(
          target: target,
          operator: node.operator!,
          propertyName: node.methodName,
        );
      }
      targetType = _resolver.flowAnalysis.flow?.propertyGet(
              functionExpression,
              target,
              node.methodName.name,
              node.methodName.staticElement,
              getterReturnType) ??
          targetType;
      functionExpression.staticType = targetType;
    }
    _inferenceHelper.recordStaticType(node.methodName, targetType,
        contextType: contextType);

    var invocation = FunctionExpressionInvocationImpl(
      function: functionExpression,
      typeArguments: node.typeArguments,
      argumentList: node.argumentList,
    );
    _resolver.replaceExpression(node, invocation);
    node.setProperty(_rewriteResultKey, invocation);
    _resolver.flowAnalysis.transferTestData(node, invocation);
  }

  void _setDynamicResolution(MethodInvocationImpl node,
      {bool setNameTypeToDynamic = true,
      required List<WhyNotPromotedGetter> whyNotPromotedList,
      required DartType? contextType}) {
    if (setNameTypeToDynamic) {
      node.methodName.staticType = _dynamicType;
    }
    node.staticInvokeType = _dynamicType;
    node.staticType = _dynamicType;
    _setExplicitTypeArgumentTypes();
    _resolveArguments_finishInference(node, whyNotPromotedList,
        contextType: contextType);
  }

  /// Set explicitly specified type argument types, or empty if not specified.
  /// Inference is done in type analyzer, so inferred type arguments might be
  /// set later.
  ///
  /// TODO(scheglov) when we do inference in this resolver, do we need this?
  void _setExplicitTypeArgumentTypes() {
    var typeArgumentList = _invocation!.typeArguments;
    if (typeArgumentList != null) {
      var arguments = typeArgumentList.arguments;
      _invocation!.typeArgumentTypes =
          arguments.map((n) => n.typeOrThrow).toList();
    } else {
      _invocation!.typeArgumentTypes = [];
    }
  }

  void _setResolution(MethodInvocationImpl node, DartType type,
      List<WhyNotPromotedGetter> whyNotPromotedList,
      {required DartType? contextType}) {
    // TODO(scheglov) We need this for StaticTypeAnalyzer to run inference.
    // But it seems weird. Do we need to know the raw type of a function?!
    node.methodName.staticType = type;

    if (type == _dynamicType || _isCoreFunction(type)) {
      _setDynamicResolution(node,
          setNameTypeToDynamic: false,
          whyNotPromotedList: whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (type is FunctionType) {
      _inferenceHelper.resolveMethodInvocation(
          node: node,
          rawType: type,
          whyNotPromotedList: whyNotPromotedList,
          contextType: contextType);
      return;
    }

    if (type is VoidType) {
      return _reportUseOfVoidType(node, node.methodName, whyNotPromotedList,
          contextType: contextType);
    }

    _reportInvocationOfNonFunction(node, whyNotPromotedList,
        contextType: contextType);
  }

  /// Resolver visitor is separated from the elements resolver, which calls
  /// this method resolver. If we rewrite a [MethodInvocation] node, this
  /// method will return the resulting [FunctionExpressionInvocation], so
  /// that the resolver visitor will know to continue resolving this new node.
  static FunctionExpressionInvocation? getRewriteResult(
      MethodInvocationImpl node) {
    return node.getProperty(_rewriteResultKey);
  }

  /// Checks whether the given [expression] is a reference to a class. If it is
  /// then the element representing the class is returned, otherwise `null` is
  /// returned.
  static InterfaceElement? getTypeReference(Expression expression) {
    if (expression is Identifier) {
      var staticElement = expression.staticElement;
      if (staticElement is InterfaceElement) {
        return staticElement;
      }
    }
    return null;
  }
}
