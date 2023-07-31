// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class AnnotationResolver {
  final ResolverVisitor _resolver;

  AnnotationResolver(this._resolver);

  LibraryElement get _definingLibrary => _resolver.definingLibrary;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  void resolve(
      AnnotationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList) {
    node.typeArguments?.accept(_resolver);
    _resolve(node, whyNotPromotedList);
  }

  void _classConstructorInvocation(
    AnnotationImpl node,
    ClassElement classElement,
    SimpleIdentifierImpl? constructorName,
    ArgumentListImpl argumentList,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    ConstructorElement? constructorElement;
    if (constructorName != null) {
      constructorElement = classElement.getNamedConstructor(
        constructorName.name,
      );
    } else {
      constructorElement = classElement.unnamedConstructor;
    }

    _constructorInvocation(
      node,
      classElement.name,
      constructorName,
      classElement.typeParameters,
      constructorElement,
      argumentList,
      (typeArguments) {
        return classElement.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _resolver.noneOrStarSuffix,
        );
      },
      whyNotPromotedList,
    );
  }

  void _classGetter(
    AnnotationImpl node,
    InterfaceElement classElement,
    SimpleIdentifierImpl? getterName,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    ExecutableElement? getter;
    if (getterName != null) {
      getter = classElement.getGetter(getterName.name);
      getter = _resolver.toLegacyElement(getter);
      // Recovery, try to find a constructor.
      getter ??= classElement.getNamedConstructor(getterName.name);
    } else {
      getter = classElement.unnamedConstructor;
    }

    getterName?.staticElement = getter;
    node.element = getter;

    if (getterName != null && getter is PropertyAccessorElement) {
      _propertyAccessorElement(node, getterName, getter, whyNotPromotedList);
      _resolveAnnotationElementGetter(node, getter);
    } else if (getter is! ConstructorElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
    }

    _visitArguments(node, whyNotPromotedList);
  }

  void _constructorInvocation(
    AnnotationImpl node,
    String typeDisplayName,
    SimpleIdentifierImpl? constructorName,
    List<TypeParameterElement> typeParameters,
    ConstructorElement? constructorElement,
    ArgumentListImpl argumentList,
    InterfaceType Function(List<DartType> typeArguments) instantiateElement,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    constructorElement = _resolver.toLegacyElement(constructorElement);
    constructorName?.staticElement = constructorElement;
    node.element = constructorElement;

    if (constructorElement == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
      AnnotationInferrer(
              resolver: _resolver,
              node: node,
              argumentList: argumentList,
              contextType: null,
              whyNotPromotedList: whyNotPromotedList,
              constructorName: constructorName)
          .resolveInvocation(rawType: null);
      return;
    }

    var elementToInfer = ConstructorElementToInfer(
      typeParameters,
      constructorElement,
    );
    var constructorRawType = elementToInfer.asType;

    AnnotationInferrer(
            resolver: _resolver,
            node: node,
            argumentList: argumentList,
            contextType: null,
            whyNotPromotedList: whyNotPromotedList,
            constructorName: constructorName)
        .resolveInvocation(rawType: constructorRawType);
  }

  void _extensionGetter(
    AnnotationImpl node,
    ExtensionElement extensionElement,
    SimpleIdentifierImpl? getterName,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    ExecutableElement? getter;
    if (getterName != null) {
      getter = extensionElement.getGetter(getterName.name);
      getter = _resolver.toLegacyElement(getter);
    }

    getterName?.staticElement = getter;
    node.element = getter;

    if (getterName != null && getter is PropertyAccessorElement) {
      _propertyAccessorElement(node, getterName, getter, whyNotPromotedList);
      _resolveAnnotationElementGetter(node, getter);
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
    }

    _visitArguments(node, whyNotPromotedList);
  }

  void _localVariable(
    AnnotationImpl node,
    VariableElement element,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    if (!element.isConst || node.arguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, node);
    }

    _visitArguments(node, whyNotPromotedList);
  }

  void _propertyAccessorElement(
    AnnotationImpl node,
    SimpleIdentifierImpl name,
    PropertyAccessorElement element,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    element = _resolver.toLegacyElement(element);
    name.staticElement = element;
    node.element = element;

    _resolveAnnotationElementGetter(node, element);
    _visitArguments(node, whyNotPromotedList);
  }

  void _resolve(
      AnnotationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList) {
    SimpleIdentifierImpl name1;
    SimpleIdentifierImpl? name2;
    SimpleIdentifierImpl? name3;
    var nameNode = node.name;
    if (nameNode is PrefixedIdentifierImpl) {
      name1 = nameNode.prefix;
      name2 = nameNode.identifier;
      name3 = node.constructorName;
    } else {
      name1 = nameNode as SimpleIdentifierImpl;
      name2 = node.constructorName;
    }
    var argumentList = node.arguments;

    var element1 = name1.scopeLookupResult!.getter;
    name1.staticElement = element1;

    if (element1 == null) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_ANNOTATION,
        node,
        [name1.name],
      );
      _visitArguments(node, whyNotPromotedList);
      return;
    }

    // Class(args) or Class.CONST
    if (element1 is InterfaceElement) {
      if (element1 is ClassElement && argumentList != null) {
        _classConstructorInvocation(
            node, element1, name2, argumentList, whyNotPromotedList);
      } else {
        _classGetter(node, element1, name2, whyNotPromotedList);
      }
      return;
    }

    // Extension.CONST
    if (element1 is ExtensionElement) {
      _extensionGetter(node, element1, name2, whyNotPromotedList);
      return;
    }

    // prefix.*
    if (element1 is PrefixElement) {
      if (name2 != null) {
        var element = element1.scope.lookup(name2.name).getter;
        name2.staticElement = element;
        // prefix.Class(args) or prefix.Class.CONST
        if (element is InterfaceElement) {
          if (element is ClassElement && argumentList != null) {
            _classConstructorInvocation(
                node, element, name3, argumentList, whyNotPromotedList);
          } else {
            _classGetter(node, element, name3, whyNotPromotedList);
          }
          return;
        }
        // prefix.Extension.CONST
        if (element is ExtensionElement) {
          _extensionGetter(node, element, name3, whyNotPromotedList);
          return;
        }
        // prefix.CONST
        if (element is PropertyAccessorElement) {
          _propertyAccessorElement(node, name2, element, whyNotPromotedList);
          return;
        }

        // prefix.TypeAlias(args) or prefix.TypeAlias.CONST
        if (element is TypeAliasElement) {
          var aliasedType = element.aliasedType;
          var argumentList = node.arguments;
          if (aliasedType is InterfaceType && argumentList != null) {
            _typeAliasConstructorInvocation(node, element, name3, aliasedType,
                argumentList, whyNotPromotedList);
          } else {
            _typeAliasGetter(node, element, name3, whyNotPromotedList);
          }
          return;
        }
        // undefined
        if (element == null) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_ANNOTATION,
            node,
            [name2.name],
          );
          _visitArguments(node, whyNotPromotedList);
          return;
        }
      }
    }

    // CONST
    if (element1 is PropertyAccessorElement) {
      _propertyAccessorElement(node, name1, element1, whyNotPromotedList);
      return;
    }

    // TypeAlias(args) or TypeAlias.CONST
    if (element1 is TypeAliasElement) {
      var aliasedType = element1.aliasedType;
      var argumentList = node.arguments;
      if (aliasedType is InterfaceType && argumentList != null) {
        _typeAliasConstructorInvocation(node, element1, name2, aliasedType,
            argumentList, whyNotPromotedList);
      } else {
        _typeAliasGetter(node, element1, name2, whyNotPromotedList);
      }
      return;
    }

    if (element1 is VariableElement) {
      _localVariable(node, element1, whyNotPromotedList);
      return;
    }

    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.INVALID_ANNOTATION,
      node,
    );

    _visitArguments(node, whyNotPromotedList);
  }

  void _resolveAnnotationElementGetter(
      Annotation annotation, PropertyAccessorElement accessorElement) {
    // The accessor should be synthetic, the variable should be constant, and
    // there should be no arguments.
    VariableElement variableElement = accessorElement.variable;
    if (!accessorElement.isSynthetic ||
        !variableElement.isConst ||
        annotation.arguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
    }
  }

  void _typeAliasConstructorInvocation(
    AnnotationImpl node,
    TypeAliasElement typeAliasElement,
    SimpleIdentifierImpl? constructorName,
    InterfaceType aliasedType,
    ArgumentListImpl argumentList,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    var constructorElement = aliasedType.lookUpConstructor(
      constructorName?.name,
      _definingLibrary,
    );

    _constructorInvocation(
      node,
      typeAliasElement.name,
      constructorName,
      typeAliasElement.typeParameters,
      constructorElement,
      argumentList,
      (typeArguments) {
        return typeAliasElement.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _resolver.noneOrStarSuffix,
        ) as InterfaceType;
      },
      whyNotPromotedList,
    );
  }

  void _typeAliasGetter(
    AnnotationImpl node,
    TypeAliasElement typeAliasElement,
    SimpleIdentifierImpl? getterName,
    List<WhyNotPromotedGetter> whyNotPromotedList,
  ) {
    ExecutableElement? getter;
    var aliasedType = typeAliasElement.aliasedType;
    if (aliasedType is InterfaceType) {
      var classElement = aliasedType.element;
      if (getterName != null) {
        getter = classElement.getGetter(getterName.name);
        getter = _resolver.toLegacyElement(getter);
      }
    }

    getterName?.staticElement = getter;
    node.element = getter;

    if (getterName != null && getter is PropertyAccessorElement) {
      _propertyAccessorElement(node, getterName, getter, whyNotPromotedList);
      _resolveAnnotationElementGetter(node, getter);
    } else if (getter is! ConstructorElement) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_ANNOTATION,
        node,
      );
    }

    _visitArguments(node, whyNotPromotedList);
  }

  void _visitArguments(
      AnnotationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList) {
    var arguments = node.arguments;
    if (arguments != null) {
      AnnotationInferrer(
              resolver: _resolver,
              node: node,
              argumentList: arguments,
              contextType: null,
              whyNotPromotedList: whyNotPromotedList,
              constructorName: null)
          .resolveInvocation(rawType: null);
    }
  }
}
