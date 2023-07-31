// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/generated/resolver.dart';

class CommentReferenceResolver {
  final TypeProviderImpl _typeProvider;

  final ResolverVisitor _resolver;

  /// Helper for resolving properties on types.
  final TypePropertyResolver _typePropertyResolver;

  CommentReferenceResolver(this._typeProvider, this._resolver)
      : _typePropertyResolver = _resolver.typePropertyResolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Resolves [commentReference].
  void resolve(CommentReference commentReference) {
    _resolver.errorReporter.lockLevel++;
    try {
      var expression = commentReference.expression;
      if (expression is SimpleIdentifierImpl) {
        _resolveSimpleIdentifierReference(expression,
            hasNewKeyword: commentReference.newKeyword != null);
      } else if (expression is PrefixedIdentifierImpl) {
        _resolvePrefixedIdentifierReference(expression,
            hasNewKeyword: commentReference.newKeyword != null);
      } else if (expression is PropertyAccessImpl) {
        _resolvePropertyAccessReference(expression,
            hasNewKeyword: commentReference.newKeyword != null);
      }
    } finally {
      _resolver.errorReporter.lockLevel--;
    }
  }

  void _resolvePrefixedIdentifierReference(
    PrefixedIdentifierImpl expression, {
    required bool hasNewKeyword,
  }) {
    var prefix = expression.prefix;
    var prefixElement = _resolveSimpleIdentifier(prefix);
    prefix.staticElement = prefixElement;

    if (prefixElement == null) {
      return;
    }

    var name = expression.identifier;

    if (prefixElement is PrefixElement) {
      var prefixScope = prefixElement.scope;
      var lookupResult = prefixScope.lookup(name.name);
      var element = lookupResult.getter ?? lookupResult.setter;
      element = _resolver.toLegacyElement(element);
      name.staticElement = element;
      return;
    }

    if (!hasNewKeyword) {
      if (prefixElement is InterfaceElement) {
        name.staticElement = _resolver.inheritance.getMember2(
              prefixElement,
              Name(prefixElement.library.source.uri, name.name),
            ) ??
            prefixElement.getMethod(name.name) ??
            prefixElement.getGetter(name.name) ??
            prefixElement.getSetter(name.name) ??
            prefixElement.getNamedConstructor(name.name);
      } else if (prefixElement is ExtensionElement) {
        name.staticElement = prefixElement.getMethod(name.name) ??
            prefixElement.getGetter(name.name) ??
            prefixElement.getSetter(name.name);
      } else {
        // TODO(brianwilkerson) Report this error.
      }
    } else if (prefixElement is InterfaceElement) {
      var constructor = prefixElement.getNamedConstructor(name.name);
      if (constructor == null) {
        // TODO(brianwilkerson) Report this error.
      } else {
        name.staticElement = constructor;
      }
    } else {
      // TODO(brianwilkerson) Report this error.
    }
  }

  void _resolvePropertyAccessReference(
    PropertyAccessImpl expression, {
    required bool hasNewKeyword,
  }) {
    var target = expression.target;
    if (target is! PrefixedIdentifierImpl) {
      // A PropertyAccess with a target more complex than a
      // [PrefixedIdentifier] is not a valid comment reference.
      return;
    }

    var prefix = target.prefix;
    var prefixElement = _resolveSimpleIdentifier(prefix);
    prefix.staticElement = prefixElement;

    if (prefixElement is! PrefixElement) {
      // The only valid prefixElement is a PrefixElement; otherwise, this is
      // not a comment reference.
      return;
    }

    var name = target.identifier;
    var prefixScope = prefixElement.scope;
    var lookupResult = prefixScope.lookup(name.name);
    var element = lookupResult.getter ?? lookupResult.setter;
    element = _resolver.toLegacyElement(element);
    name.staticElement = element;

    var propertyName = expression.propertyName;
    if (element is InterfaceElement) {
      propertyName.staticElement = element.getMethod(propertyName.name) ??
          element.getGetter(propertyName.name) ??
          element.getSetter(propertyName.name) ??
          element.getNamedConstructor(propertyName.name);
    } else if (element is ExtensionElement) {
      propertyName.staticElement = element.getMethod(propertyName.name) ??
          element.getGetter(propertyName.name) ??
          element.getSetter(propertyName.name);
    }
  }

  /// Resolves the given simple [identifier] if possible.
  ///
  /// Returns the resolved element, or `null` if the identifier could not be
  /// resolved. This does not record the results of the resolution.
  Element? _resolveSimpleIdentifier(SimpleIdentifierImpl identifier) {
    var lookupResult = identifier.scopeLookupResult!;

    var element = _resolver.toLegacyElement(lookupResult.getter) ??
        _resolver.toLegacyElement(lookupResult.setter);

    if (element == null) {
      InterfaceType enclosingType;
      var enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        enclosingType = enclosingClass.thisType;
      } else {
        var enclosingExtension = _resolver.enclosingExtension;
        if (enclosingExtension == null) {
          return null;
        }
        var extendedType = _typeSystem.resolveToBound(
          enclosingExtension.extendedType,
        );
        if (extendedType is InterfaceType) {
          enclosingType = extendedType;
        } else if (extendedType is FunctionType) {
          enclosingType = _typeProvider.functionType;
        } else {
          return null;
        }
      }
      var result = _typePropertyResolver.resolve(
        receiver: null,
        receiverType: enclosingType,
        name: identifier.name,
        propertyErrorEntity: identifier,
        nameErrorEntity: identifier,
      );
      element = result.getter ?? result.setter;
    }
    return element;
  }

  void _resolveSimpleIdentifierReference(
    SimpleIdentifierImpl expression, {
    required bool hasNewKeyword,
  }) {
    var element = _resolveSimpleIdentifier(expression);
    if (element == null) {
      return;
    }
    expression.staticElement = element;
    if (hasNewKeyword) {
      if (element is InterfaceElement) {
        var constructor = element.unnamedConstructor;
        if (constructor == null) {
          // TODO(brianwilkerson) Report this error.
        } else {
          expression.staticElement = constructor;
        }
      } else {
        // TODO(brianwilkerson) Report this error.
      }
    }
  }
}
