// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class AnnotationResolver {
  final ResolverVisitor _resolver;

  AnnotationResolver(this._resolver);

  LibraryElement get _definingLibrary => _resolver.definingLibrary;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _genericMetadataIsEnabled =>
      _definingLibrary.featureSet.isEnabled(Feature.generic_metadata);

  void resolve(
      AnnotationImpl node, List<WhyNotPromotedGetter> whyNotPromotedList) {
    node.typeArguments?.accept(_resolver);
    _resolve(node, whyNotPromotedList);
  }

  void _classConstructorInvocation(
    AnnotationImpl node,
    ClassElement classElement,
    SimpleIdentifierImpl? constructorName,
    ArgumentList argumentList,
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
    ClassElement classElement,
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
    ArgumentList argumentList,
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
      _resolver.visitArgumentList(argumentList,
          whyNotPromotedList: whyNotPromotedList);
      return;
    }

    // If no type parameters, the elements are correct.
    if (typeParameters.isEmpty) {
      var typeArgumentList = node.typeArguments;
      if (typeArgumentList != null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
          typeArgumentList,
          [
            typeDisplayName,
            typeParameters.length,
            typeArgumentList.arguments.length,
          ],
        );
      }
      _resolveConstructorInvocationArguments(node);
      InferenceContext.setType(argumentList, constructorElement.type);
      _resolver.visitArgumentList(argumentList,
          whyNotPromotedList: whyNotPromotedList);
      return;
    }

    void resolveWithFixedTypeArguments(
      List<DartType> typeArguments,
      ConstructorElement constructorElement,
    ) {
      var type = instantiateElement(typeArguments);
      constructorElement = ConstructorMember.from(constructorElement, type);
      constructorName?.staticElement = constructorElement;
      node.element = constructorElement;
      _resolveConstructorInvocationArguments(node);

      InferenceContext.setType(argumentList, constructorElement.type);
      _resolver.visitArgumentList(argumentList,
          whyNotPromotedList: whyNotPromotedList);
    }

    if (!_genericMetadataIsEnabled) {
      var typeArguments = List.filled(
        typeParameters.length,
        DynamicTypeImpl.instance,
      );
      resolveWithFixedTypeArguments(typeArguments, constructorElement);
      return;
    }

    var typeArgumentList = node.typeArguments;
    if (typeArgumentList != null) {
      List<DartType> typeArguments;
      if (typeArgumentList.arguments.length == typeParameters.length) {
        typeArguments = typeArgumentList.arguments
            .map((element) => element.typeOrThrow)
            .toList();
        var substitution = Substitution.fromPairs(
          typeParameters,
          typeArguments,
        );
        for (var i = 0; i < typeParameters.length; i++) {
          var typeParameter = typeParameters[i];
          var bound = typeParameter.bound;
          if (bound != null) {
            bound = substitution.substituteType(bound);
            var typeArgument = typeArguments[i];
            if (!_resolver.typeSystem.isSubtypeOf(typeArgument, bound)) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
                typeArgumentList.arguments[i],
                [typeArgument, typeParameter.name, bound],
              );
            }
          }
        }
      } else {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
          typeArgumentList,
          [
            typeDisplayName,
            typeParameters.length,
            typeArgumentList.arguments.length,
          ],
        );
        typeArguments = List.filled(
          typeParameters.length,
          DynamicTypeImpl.instance,
        );
      }
      resolveWithFixedTypeArguments(typeArguments, constructorElement);
      return;
    }

    _resolver.visitArgumentList(argumentList,
        whyNotPromotedList: whyNotPromotedList);

    var elementToInfer = ConstructorElementToInfer(
      typeParameters,
      constructorElement,
    );
    var constructorRawType = elementToInfer.asType;

    var inferred = _resolver.inferenceHelper.inferGenericInvoke(
        node, constructorRawType, typeArgumentList, argumentList, node,
        isConst: true)!;

    constructorElement = ConstructorMember.from(
      constructorElement,
      inferred.returnType as InterfaceType,
    );
    constructorName?.staticElement = constructorElement;
    node.element = constructorElement;
    _resolveConstructorInvocationArguments(node);
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
    if (element1 is ClassElement) {
      if (argumentList != null) {
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
        var element2 = element1.scope.lookup(name2.name).getter;
        name2.staticElement = element2;
        // prefix.Class(args) or prefix.Class.CONST
        if (element2 is ClassElement) {
          if (argumentList != null) {
            _classConstructorInvocation(
                node, element2, name3, argumentList, whyNotPromotedList);
          } else {
            _classGetter(node, element2, name3, whyNotPromotedList);
          }
          return;
        }
        // prefix.Extension.CONST
        if (element2 is ExtensionElement) {
          _extensionGetter(node, element2, name3, whyNotPromotedList);
          return;
        }
        // prefix.CONST
        if (element2 is PropertyAccessorElement) {
          _propertyAccessorElement(node, name2, element2, whyNotPromotedList);
          return;
        }

        // prefix.TypeAlias(args) or prefix.TypeAlias.CONST
        if (element2 is TypeAliasElement) {
          var aliasedType = element2.aliasedType;
          var argumentList = node.arguments;
          if (aliasedType is InterfaceType && argumentList != null) {
            _typeAliasConstructorInvocation(node, element2, name3, aliasedType,
                argumentList, whyNotPromotedList);
          } else {
            _typeAliasGetter(node, element2, name3, whyNotPromotedList);
          }
          return;
        }
        // undefined
        if (element2 == null) {
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

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement?>? _resolveArgumentsToFunction(
      ArgumentList argumentList, ExecutableElement? executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(argumentList, parameters);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments. An error will be reported if any of
  /// the arguments cannot be matched to a parameter. Return the parameters that
  /// correspond to the arguments.
  ///
  /// TODO(scheglov) this is duplicate
  List<ParameterElement?> _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _errorReporter.reportErrorForNode);
  }

  void _resolveConstructorInvocationArguments(AnnotationImpl node) {
    var argumentList = node.arguments;
    // error will be reported in ConstantVerifier
    if (argumentList == null) {
      return;
    }
    // resolve arguments to parameters
    var constructor = node.element;
    if (constructor is ConstructorElement) {
      var parameters = _resolveArgumentsToFunction(argumentList, constructor);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
  }

  void _typeAliasConstructorInvocation(
    AnnotationImpl node,
    TypeAliasElement typeAliasElement,
    SimpleIdentifierImpl? constructorName,
    InterfaceType aliasedType,
    ArgumentList argumentList,
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
      _resolver.visitArgumentList(arguments,
          whyNotPromotedList: whyNotPromotedList);
    }
  }
}
