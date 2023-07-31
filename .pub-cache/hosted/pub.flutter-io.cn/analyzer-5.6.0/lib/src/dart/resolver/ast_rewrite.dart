// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/error/codes.dart';

/// Handles possible rewrites of AST.
///
/// When code is initially parsed, many assumptions are made which may be
/// incorrect given newer Dart syntax. For example, `new a.b()` is parsed as an
/// [InstanceCreationExpression], but `a.b()` (without `new`) is parsed as a
/// [MethodInvocation]. The public methods of this class carry out the minimal
/// amount of resolution in order to determine whether a node (and its
/// descendants) should be replaced by another, and perform such replacements.
///
/// The public methods of this class form a complete accounting of possible
/// node replacements.
class AstRewriter {
  final ErrorReporter _errorReporter;

  final TypeProvider _typeProvider;

  AstRewriter(this._errorReporter, this._typeProvider);

  /// Possibly rewrites [node] as a [MethodInvocation] with a
  /// [FunctionReference] target.
  ///
  /// Code such as `a<...>.b(...);` (or with a prefix such as `p.a<...>.b(...)`)
  /// is parsed as an [ExpressionStatement] with an [InstanceCreationExpression]
  /// with `a<...>.b` as the [ConstructorName] (which has 'type' of `a<...>`
  /// and 'name' of `b`). The [InstanceCreationExpression] is rewritten as a
  /// [MethodInvocation] if `a` resolves to a function.
  AstNode instanceCreationExpression(
      Scope nameScope, InstanceCreationExpressionImpl node) {
    if (node.keyword != null) {
      // Either `new` or `const` has been specified.
      return node;
    }
    var typeName = node.constructorName.type.name;
    if (typeName is SimpleIdentifier) {
      var element = nameScope.lookup(typeName.name).getter;
      if (element is FunctionElement ||
          element is MethodElement ||
          element is PropertyAccessorElement) {
        return _toMethodInvocationOfFunctionReference(
            node: node, function: typeName);
      } else if (element is TypeAliasElement &&
          element.aliasedElement is GenericFunctionTypeElement) {
        return _toMethodInvocationOfAliasedTypeLiteral(
            node: node, function: typeName, element: element);
      }
    } else if (typeName is PrefixedIdentifierImpl) {
      var prefixElement = nameScope.lookup(typeName.prefix.name).getter;
      if (prefixElement is PrefixElement) {
        var prefixedName = typeName.identifier.name;
        var element = prefixElement.scope.lookup(prefixedName).getter;
        if (element is FunctionElement) {
          return _toMethodInvocationOfFunctionReference(
              node: node, function: typeName);
        } else if (element is TypeAliasElement &&
            element.aliasedElement is GenericFunctionTypeElement) {
          return _toMethodInvocationOfAliasedTypeLiteral(
              node: node, function: typeName, element: element);
        }

        // If `element` is a [ClassElement], or a [TypeAliasElement] aliasing
        // an interface type, then this indeed looks like a constructor call; do
        // not rewrite `node`.

        // If `element` is a [TypeAliasElement] aliasing a function type, then
        // this looks like an attempt type instantiate a function type alias
        // (which is not a feature), and then call a method on the resulting
        // [Type] object; no not rewrite `node`.

        // If `typeName.identifier` cannot be resolved, do not rewrite `node`.
        return node;
      } else {
        // In the case that `prefixElement` is not a [PrefixElement], then
        // `typeName`, as a [PrefixedIdentifier], cannot refer to a class or an
        // aliased type; rewrite `node` as a [MethodInvocation].
        return _toMethodInvocationOfFunctionReference(
            node: node, function: typeName);
      }
    }

    return node;
  }

  /// Possibly rewrites [node] as an [ExtensionOverride] or as an
  /// [InstanceCreationExpression].
  AstNode methodInvocation(Scope nameScope, MethodInvocationImpl node) {
    final methodName = node.methodName;
    if (methodName.isSynthetic) {
      // This isn't a constructor invocation because the method name is
      // synthetic.
      return node;
    }

    var target = node.target;
    if (target == null) {
      // Possible cases: C() or C<>()
      if (node.realTarget != null) {
        // This isn't a constructor invocation because it's in a cascade.
        return node;
      }
      var element = nameScope.lookup(methodName.name).getter;
      if (element is InterfaceElement) {
        return _toInstanceCreation_type(
          node: node,
          typeIdentifier: methodName,
        );
      } else if (element is ExtensionElement) {
        var extensionOverride = ExtensionOverrideImpl(
          extensionName: methodName,
          typeArguments: node.typeArguments,
          argumentList: node.argumentList,
        );
        NodeReplacer.replace(node, extensionOverride);
        return extensionOverride;
      } else if (element is TypeAliasElement &&
          element.aliasedType is InterfaceType) {
        return _toInstanceCreation_type(
          node: node,
          typeIdentifier: methodName,
        );
      }
    } else if (target is SimpleIdentifierImpl) {
      // Possible cases: C.n(), p.C() or p.C<>()
      if (node.isNullAware) {
        // This isn't a constructor invocation because a null aware operator is
        // being used.
      }
      var element = nameScope.lookup(target.name).getter;
      if (element is InterfaceElement) {
        // class C { C.named(); }
        // C.named()
        return _toInstanceCreation_type_constructor(
          node: node,
          typeIdentifier: target,
          constructorIdentifier: methodName,
          classElement: element,
        );
      } else if (element is PrefixElement) {
        // Possible cases: p.C() or p.C<>()
        var prefixedElement = element.scope.lookup(methodName.name).getter;
        if (prefixedElement is InterfaceElement) {
          return _toInstanceCreation_prefix_type(
            node: node,
            prefixIdentifier: target,
            typeIdentifier: methodName,
          );
        } else if (prefixedElement is ExtensionElement) {
          var extensionName = PrefixedIdentifierImpl(
            prefix: target,
            period: node.operator!,
            identifier: methodName,
          );
          var extensionOverride = ExtensionOverrideImpl(
            extensionName: extensionName,
            typeArguments: node.typeArguments,
            argumentList: node.argumentList,
          );
          NodeReplacer.replace(node, extensionOverride);
          return extensionOverride;
        } else if (prefixedElement is TypeAliasElement &&
            prefixedElement.aliasedType is InterfaceType) {
          return _toInstanceCreation_prefix_type(
            node: node,
            prefixIdentifier: target,
            typeIdentifier: methodName,
          );
        }
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          // class C { C.named(); }
          // typedef X = C;
          // X.named()
          return _toInstanceCreation_type_constructor(
            node: node,
            typeIdentifier: target,
            constructorIdentifier: methodName,
            classElement: aliasedType.element,
          );
        }
      }
    } else if (target is PrefixedIdentifierImpl) {
      // Possible case: p.C.n()
      var prefixElement = nameScope.lookup(target.prefix.name).getter;
      target.prefix.staticElement = prefixElement;
      if (prefixElement is PrefixElement) {
        var prefixedName = target.identifier.name;
        var element = prefixElement.scope.lookup(prefixedName).getter;
        if (element is InterfaceElement) {
          return _instanceCreation_prefix_type_name(
            node: node,
            typeNameIdentifier: target,
            constructorIdentifier: methodName,
            classElement: element,
          );
        } else if (element is TypeAliasElement) {
          var aliasedType = element.aliasedType;
          if (aliasedType is InterfaceType) {
            return _instanceCreation_prefix_type_name(
              node: node,
              typeNameIdentifier: target,
              constructorIdentifier: methodName,
              classElement: aliasedType.element,
            );
          }
        }
      }
    }
    return node;
  }

  /// Possibly rewrites [node] as a [ConstructorReference].
  ///
  /// Code such as `List.filled;` is parsed as (an [ExpressionStatement] with) a
  /// [PrefixedIdentifier] with 'prefix' of `List` and 'identifier' of `filled`.
  /// The [PrefixedIdentifier] may need to be rewritten as a
  /// [ConstructorReference].
  AstNode prefixedIdentifier(Scope nameScope, PrefixedIdentifierImpl node) {
    var parent = node.parent;
    if (parent is Annotation) {
      // An annotations which is a const constructor invocation can initially be
      // represented with a [PrefixedIdentifier]. Do not rewrite such nodes.
      return node;
    }
    if (parent is CommentReferenceImpl) {
      // TODO(srawlins): This probably should be allowed to be rewritten to a
      // [ConstructorReference] at some point.
      return node;
    }
    if (parent is AssignmentExpressionImpl && parent.leftHandSide == node) {
      // A constructor cannot be assigned to, in some expression like
      // `C.new = foo`; do not rewrite.
      return node;
    }
    var identifier = node.identifier;
    if (identifier.isSynthetic) {
      // This isn't a constructor reference.
      return node;
    }
    var prefix = node.prefix;
    var element = nameScope.lookup(prefix.name).getter;
    if (element is InterfaceElement) {
      // Example:
      //     class C { C.named(); }
      //     C.named
      return _toConstructorReference_prefixed(
          node: node, classElement: element);
    } else if (element is TypeAliasElement) {
      var aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        // Example:
        //     class C { C.named(); }
        //     typedef X = C;
        //     X.named
        return _toConstructorReference_prefixed(
          node: node,
          classElement: aliasedType.element,
        );
      }
    }
    return node;
  }

  /// Possibly rewrites [node] as a [ConstructorReference].
  ///
  /// Code such as `async.Future.value;` is parsed as (an [ExpressionStatement]
  /// with) a [PropertyAccess] with a 'target' of [PrefixedIdentifier] (with
  /// 'prefix' of `List` and 'identifier' of `filled`) and a 'propertyName' of
  /// `value`. The [PropertyAccess] may need to be rewritten as a
  /// [ConstructorReference].
  AstNode propertyAccess(Scope nameScope, PropertyAccessImpl node) {
    if (node.isCascaded) {
      // For example, `List..filled`: this is a property access on an instance
      // `Type`.
      return node;
    }
    if (node.parent is CommentReferenceImpl) {
      // TODO(srawlins): This probably should be allowed to be rewritten to a
      // [ConstructorReference] at some point.
      return node;
    }
    var receiver = node.target!;

    IdentifierImpl receiverIdentifier;
    TypeArgumentListImpl? typeArguments;
    if (receiver is PrefixedIdentifierImpl) {
      receiverIdentifier = receiver;
    } else if (receiver is FunctionReferenceImpl) {
      // A [ConstructorReference] with explicit type arguments is initially
      // parsed as a [PropertyAccess] with a [FunctionReference] target; for
      // example: `List<int>.filled` or `core.List<int>.filled`.
      var function = receiver.function;
      if (function is! IdentifierImpl) {
        // If [receiverIdentifier] is not an Identifier then [node] is not a
        // ConstructorReference.
        return node;
      }
      receiverIdentifier = function;
      typeArguments = receiver.typeArguments;
    } else {
      // If the receiver is not (initially) a prefixed identifier or a function
      // reference, then [node] is not a constructor reference.
      return node;
    }

    Element? element;
    if (receiverIdentifier is SimpleIdentifierImpl) {
      element = nameScope.lookup(receiverIdentifier.name).getter;
    } else if (receiverIdentifier is PrefixedIdentifierImpl) {
      var prefixElement =
          nameScope.lookup(receiverIdentifier.prefix.name).getter;
      if (prefixElement is PrefixElement) {
        element = prefixElement.scope
            .lookup(receiverIdentifier.identifier.name)
            .getter;
      } else {
        // This expression is something like `foo.List<int>.filled` where `foo`
        // is not an import prefix.
        // TODO(srawlins): Tease out a `null` prefixElement from others for
        // specific errors.
        return node;
      }
    }

    if (element is InterfaceElement) {
      // Example:
      //     class C<T> { C.named(); }
      //     C<int>.named
      return _toConstructorReference_propertyAccess(
        node: node,
        receiver: receiverIdentifier,
        typeArguments: typeArguments,
        classElement: element,
      );
    } else if (element is TypeAliasElement) {
      var aliasedType = element.aliasedType;
      if (aliasedType is InterfaceType) {
        // Example:
        //     class C<T> { C.named(); }
        //     typedef X<T> = C<T>;
        //     X<int>.named
        return _toConstructorReference_propertyAccess(
          node: node,
          receiver: receiverIdentifier,
          typeArguments: typeArguments,
          classElement: aliasedType.element,
        );
      }
    }

    // If [receiverIdentifier] is an Identifier, but could not be resolved to
    // an Element, we cannot assume [node] is a ConstructorReference.
    //
    // TODO(srawlins): However, take an example like `Lisst<int>.filled;`
    // (where 'Lisst' does not resolve to any element). Possibilities include:
    // the user tried to write a TypeLiteral or a FunctionReference, then access
    // a property on that (these include: hashCode, runtimeType, tearoff of
    // toString, and extension methods on Type); or the user tried to write a
    // ConstructReference. It seems much more likely that the user is trying to
    // do the latter. Consider doing the work so that the user gets an error in
    // this case about `Lisst` not being a type, or `Lisst.filled` not being a
    // known constructor.
    return node;
  }

  AstNode _instanceCreation_prefix_type_name({
    required MethodInvocationImpl node,
    required PrefixedIdentifierImpl typeNameIdentifier,
    required SimpleIdentifierImpl constructorIdentifier,
    required InterfaceElement classElement,
  }) {
    var constructorElement = classElement.getNamedConstructor(
      constructorIdentifier.name,
    );
    if (constructorElement == null) {
      return node;
    }

    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [typeNameIdentifier.toString(), constructorIdentifier.name]);
    }

    var typeName = NamedTypeImpl(
      name: typeNameIdentifier,
      typeArguments: typeArguments,
      question: null,
    );
    var constructorName = ConstructorNameImpl(
      type: typeName,
      period: node.operator,
      name: constructorIdentifier,
    );
    var instanceCreationExpression = InstanceCreationExpressionImpl(
      keyword: null,
      constructorName: constructorName,
      argumentList: node.argumentList,
      typeArguments: null,
    );
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  AstNode _toConstructorReference_prefixed({
    required PrefixedIdentifierImpl node,
    required InterfaceElement classElement,
  }) {
    var name = node.identifier.name;
    var constructorElement = name == 'new'
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(name);
    if (constructorElement == null) {
      return node;
    }

    var typeName = NamedTypeImpl(
      name: node.prefix,
      typeArguments: null,
      question: null,
    );
    var constructorName = ConstructorNameImpl(
      type: typeName,
      period: node.period,
      name: node.identifier,
    );
    var constructorReference = ConstructorReferenceImpl(
      constructorName: constructorName,
    );
    NodeReplacer.replace(node, constructorReference);
    return constructorReference;
  }

  AstNode _toConstructorReference_propertyAccess({
    required PropertyAccessImpl node,
    required IdentifierImpl receiver,
    required TypeArgumentListImpl? typeArguments,
    required InterfaceElement classElement,
  }) {
    var name = node.propertyName.name;
    var constructorElement = name == 'new'
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(name);
    if (constructorElement == null && typeArguments == null) {
      // If there is no constructor by this name, and no type arguments,
      // do not rewrite the node. If there _are_ type arguments (like
      // `prefix.C<int>.name`, then it looks more like a constructor tearoff
      // than anything else, so continue with the rewrite.
      return node;
    }

    var operator = node.operator;

    var typeName = NamedTypeImpl(
      name: receiver,
      typeArguments: typeArguments,
      question: null,
    );
    var constructorName = ConstructorNameImpl(
      type: typeName,
      period: operator,
      name: node.propertyName,
    );
    var constructorReference = ConstructorReferenceImpl(
      constructorName: constructorName,
    );
    NodeReplacer.replace(node, constructorReference);
    return constructorReference;
  }

  InstanceCreationExpression _toInstanceCreation_prefix_type({
    required MethodInvocationImpl node,
    required SimpleIdentifierImpl prefixIdentifier,
    required SimpleIdentifierImpl typeIdentifier,
  }) {
    var typeName = NamedTypeImpl(
      name: PrefixedIdentifierImpl(
        prefix: prefixIdentifier,
        period: node.operator!,
        identifier: typeIdentifier,
      ),
      typeArguments: node.typeArguments,
      question: null,
    );
    var constructorName = ConstructorNameImpl(
      type: typeName,
      period: null,
      name: null,
    );
    var instanceCreationExpression = InstanceCreationExpressionImpl(
      keyword: null,
      constructorName: constructorName,
      argumentList: node.argumentList,
      typeArguments: null,
    );
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  InstanceCreationExpression _toInstanceCreation_type({
    required MethodInvocationImpl node,
    required SimpleIdentifierImpl typeIdentifier,
  }) {
    var typeName = NamedTypeImpl(
      name: typeIdentifier,
      typeArguments: node.typeArguments,
      question: null,
    );
    var constructorName = ConstructorNameImpl(
      type: typeName,
      period: null,
      name: null,
    );
    var instanceCreationExpression = InstanceCreationExpressionImpl(
      keyword: null,
      constructorName: constructorName,
      argumentList: node.argumentList,
      typeArguments: null,
    );
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  AstNode _toInstanceCreation_type_constructor({
    required MethodInvocationImpl node,
    required SimpleIdentifierImpl typeIdentifier,
    required SimpleIdentifierImpl constructorIdentifier,
    required InterfaceElement classElement,
  }) {
    var name = constructorIdentifier.name;
    var constructorElement = classElement.getNamedConstructor(name);
    if (constructorElement == null) {
      return node;
    }

    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [typeIdentifier.name, constructorIdentifier.name]);
    }
    var typeName = NamedTypeImpl(
      name: typeIdentifier,
      typeArguments: null,
      question: null,
    );
    var constructorName = ConstructorNameImpl(
      type: typeName,
      period: node.operator,
      name: constructorIdentifier,
    );
    // TODO(scheglov) I think we should drop "typeArguments" below.
    var instanceCreationExpression = InstanceCreationExpressionImpl(
      keyword: null,
      constructorName: constructorName,
      argumentList: node.argumentList,
      typeArguments: typeArguments,
    );
    NodeReplacer.replace(node, instanceCreationExpression);
    return instanceCreationExpression;
  }

  MethodInvocation _toMethodInvocationOfAliasedTypeLiteral({
    required InstanceCreationExpressionImpl node,
    required Identifier function,
    required TypeAliasElement element,
  }) {
    var typeName = NamedTypeImpl(
      name: node.constructorName.type.name,
      typeArguments: node.constructorName.type.typeArguments,
      question: null,
    );
    typeName.type = element.aliasedType;
    typeName.name.staticType = element.aliasedType;
    var typeLiteral = TypeLiteralImpl(
      typeName: typeName,
    );
    typeLiteral.staticType = _typeProvider.typeType;
    var methodInvocation = MethodInvocationImpl(
      target: typeLiteral,
      operator: node.constructorName.period,
      methodName: node.constructorName.name!,
      typeArguments: null,
      argumentList: node.argumentList,
    );
    NodeReplacer.replace(node, methodInvocation);
    return methodInvocation;
  }

  AstNode _toMethodInvocationOfFunctionReference({
    required InstanceCreationExpressionImpl node,
    required IdentifierImpl function,
  }) {
    var period = node.constructorName.period;
    var constructorId = node.constructorName.name;
    if (period == null || constructorId == null) {
      return node;
    }

    var functionReference = FunctionReferenceImpl(
      function: function,
      typeArguments: node.constructorName.type.typeArguments,
    );
    var methodInvocation = MethodInvocationImpl(
      target: functionReference,
      operator: period,
      methodName: constructorId,
      typeArguments: null,
      argumentList: node.argumentList,
    );
    NodeReplacer.replace(node, methodInvocation);
    return methodInvocation;
  }
}
