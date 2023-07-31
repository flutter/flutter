// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

/// Keeps track of the set of non-synthetic child elements of an element,
/// yielding them one at a time in response to "get" method calls.
class ElementWalker {
  /// The element whose child elements are being walked.
  final Element element;
  String? libraryFilePath;
  String? unitFilePath;

  List<PropertyAccessorElement>? _accessors;
  int _accessorIndex = 0;
  List<ClassElement>? _classes;
  int _classIndex = 0;
  List<ConstructorElement>? _constructors;
  int _constructorIndex = 0;
  List<EnumElement>? _enums;
  int _enumIndex = 0;
  List<ExtensionElement>? _extensions;
  int _extensionIndex = 0;
  List<ExecutableElement>? _functions;
  int _functionIndex = 0;
  List<MixinElement>? _mixins;
  int _mixinIndex = 0;
  List<ParameterElement>? _parameters;
  int _parameterIndex = 0;
  List<TypeAliasElement>? _typedefs;
  int _typedefIndex = 0;
  List<TypeParameterElement>? _typeParameters;
  int _typeParameterIndex = 0;
  List<VariableElement>? _variables;
  int _variableIndex = 0;

  /// Creates an [ElementWalker] which walks the child elements of a class
  /// element.
  ElementWalker.forClass(ClassElement this.element)
      : _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _constructors = element.isMixinApplication
            ? null
            : element.constructors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forCompilationUnit(CompilationUnitElementImpl this.element,
      {this.libraryFilePath, this.unitFilePath})
      : _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _classes = element.classes,
        _enums = element.enums,
        _extensions = element.extensions,
        _functions = element.functions,
        _mixins = element.mixins,
        _typedefs = element.typeAliases,
        _variables = element.topLevelVariables.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a enum
  /// element.
  ElementWalker.forEnum(EnumElement this.element)
      : _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _constructors = element.constructors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a compilation
  /// unit element.
  ElementWalker.forExecutable(ExecutableElement this.element)
      : _functions = const <ExecutableElement>[],
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of an extension
  /// element.
  ElementWalker.forExtension(ExtensionElement this.element)
      : _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forGenericFunctionType(GenericFunctionTypeElement this.element)
      : _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element defined using a generic function type.
  ElementWalker.forGenericTypeAlias(TypeAliasElement this.element)
      : _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a mixin
  /// element.
  ElementWalker.forMixin(MixinElement this.element)
      : _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _constructors = element.constructors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  /// Creates an [ElementWalker] which walks the child elements of a parameter
  /// element.
  ElementWalker.forParameter(ParameterElement this.element)
      : _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  /// Creates an [ElementWalker] which walks the child elements of a typedef
  /// element.
  ElementWalker.forTypedef(TypeAliasElement this.element)
      : _parameters =
            (element.aliasedElement as GenericFunctionTypeElement).parameters,
        _typeParameters = element.typeParameters;

  void consumeLocalElements() {
    _functionIndex = _functions!.length;
  }

  void consumeParameters() {
    _parameterIndex = _parameters!.length;
  }

  /// Returns the next non-synthetic child of [element] which is an accessor;
  /// throws an [IndexError] if there are no more.
  PropertyAccessorElementImpl getAccessor() {
    // TODO(scheglov) Remove after fixing.
    // https://github.com/dart-lang/sdk/issues/46392
    var accessors = _accessors;
    if (accessors != null && _accessorIndex >= accessors.length) {
      throw StateError(
        '[_accessorIndex: $_accessorIndex]'
        '[_accessors.length: ${accessors.length}]'
        '[accessors: $accessors]'
        '[element.source: ${element.source?.fullName}]'
        '[libraryFilePath: $libraryFilePath]'
        '[unitFilePath: $unitFilePath]',
      );
    }
    return _accessors![_accessorIndex++] as PropertyAccessorElementImpl;
  }

  /// Returns the next non-synthetic child of [element] which is a class; throws
  /// an [IndexError] if there are no more.
  ClassElementImpl getClass() {
    // TODO(scheglov) Remove after fixing.
    // https://github.com/dart-lang/sdk/issues/46392
    var classes = _classes;
    if (classes != null && _classIndex >= classes.length) {
      throw StateError(
        '[_classIndex: $_classIndex]'
        '[classes.length: ${classes.length}]'
        '[classes: $classes]'
        '[element.source: ${element.source?.fullName}]'
        '[libraryFilePath: $libraryFilePath]'
        '[unitFilePath: $unitFilePath]',
      );
    }
    return _classes![_classIndex++] as ClassElementImpl;
  }

  /// Returns the next non-synthetic child of [element] which is a constructor;
  /// throws an [IndexError] if there are no more.
  ConstructorElementImpl getConstructor() =>
      _constructors![_constructorIndex++] as ConstructorElementImpl;

  /// Returns the next non-synthetic child of [element] which is an enum; throws
  /// an [IndexError] if there are no more.
  EnumElementImpl getEnum() => _enums![_enumIndex++] as EnumElementImpl;

  ExtensionElementImpl getExtension() =>
      _extensions![_extensionIndex++] as ExtensionElementImpl;

  /// Returns the next non-synthetic child of [element] which is a top level
  /// function, method, or local function; throws an [IndexError] if there are
  /// no more.
  ExecutableElementImpl getFunction() =>
      _functions![_functionIndex++] as ExecutableElementImpl;

  /// Returns the next non-synthetic child of [element] which is a mixin; throws
  /// an [IndexError] if there are no more.
  MixinElementImpl getMixin() => _mixins![_mixinIndex++] as MixinElementImpl;

  /// Returns the next non-synthetic child of [element] which is a parameter;
  /// throws an [IndexError] if there are no more.
  ParameterElementImpl getParameter() =>
      _parameters![_parameterIndex++] as ParameterElementImpl;

  /// Returns the next non-synthetic child of [element] which is a typedef;
  /// throws an [IndexError] if there are no more.
  TypeAliasElementImpl getTypedef() =>
      _typedefs![_typedefIndex++] as TypeAliasElementImpl;

  /// Returns the next non-synthetic child of [element] which is a type
  /// parameter; throws an [IndexError] if there are no more.
  TypeParameterElementImpl getTypeParameter() =>
      _typeParameters![_typeParameterIndex++] as TypeParameterElementImpl;

  /// Returns the next non-synthetic child of [element] which is a top level
  /// variable, field, or local variable; throws an [IndexError] if there are no
  /// more.
  VariableElementImpl getVariable() {
    // TODO(scheglov) Remove after fixing.
    // https://github.com/dart-lang/sdk/issues/46392
    var variables = _variables;
    if (variables != null && _variableIndex >= variables.length) {
      throw StateError(
        '[_variableIndex: $_variableIndex]'
        '[_variables.length: ${variables.length}]'
        '[variables: $variables]'
        '[element.source: ${element.source?.fullName}]'
        '[libraryFilePath: $libraryFilePath]'
        '[unitFilePath: $unitFilePath]',
      );
    }
    return _variables![_variableIndex++] as VariableElementImpl;
  }

  /// Verifies that all non-synthetic children of [element] have been obtained
  /// from their corresponding "get" method calls; if not, throws a
  /// [StateError].
  void validate() {
    void check(List<Element>? elements, int index) {
      if (elements != null && elements.length != index) {
        throw StateError(
            'Unmatched ${elements[index].runtimeType} ${elements[index]}');
      }
    }

    check(_accessors, _accessorIndex);
    check(_classes, _classIndex);
    check(_constructors, _constructorIndex);
    check(_enums, _enumIndex);
    check(_functions, _functionIndex);
    check(_parameters, _parameterIndex);
    check(_typedefs, _typedefIndex);
    check(_typeParameters, _typeParameterIndex);
    check(_variables, _variableIndex);
  }

  static bool _isNotSynthetic(Element e) => !e.isSynthetic;
}
