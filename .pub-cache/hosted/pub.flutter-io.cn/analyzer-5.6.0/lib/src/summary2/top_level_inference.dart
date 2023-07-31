// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:collection/collection.dart';

/// Resolver for typed constant top-level variables and fields initializers.
///
/// Initializers of untyped variables are resolved during [TopLevelInference].
class ConstantInitializersResolver {
  final Linker linker;

  late CompilationUnitElementImpl _unitElement;
  late LibraryElement _library;
  bool _enclosingClassHasConstConstructor = false;
  late Scope _scope;

  ConstantInitializersResolver(this.linker);

  void perform() {
    for (var builder in linker.builders.values) {
      _library = builder.element;
      for (var unit in _library.units) {
        _unitElement = unit as CompilationUnitElementImpl;
        unit.classes.forEach(_resolveInterfaceFields);
        unit.enums.forEach(_resolveInterfaceFields);
        unit.extensions.forEach(_resolveExtensionFields);
        unit.mixins.forEach(_resolveInterfaceFields);

        _scope = unit.enclosingElement.scope;
        unit.topLevelVariables.forEach(_resolveVariable);
      }
    }
  }

  void _resolveExtensionFields(ExtensionElement extension_) {
    var node = linker.getLinkingNode(extension_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in extension_.fields) {
      _resolveVariable(element);
    }
  }

  void _resolveInterfaceFields(InterfaceElement class_) {
    _enclosingClassHasConstConstructor =
        class_.constructors.any((c) => c.isConst);

    var node = linker.getLinkingNode(class_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in class_.fields) {
      _resolveVariable(element);
    }
    _enclosingClassHasConstConstructor = false;
  }

  void _resolveVariable(PropertyInducingElement element) {
    element as PropertyInducingElementImpl;

    var variable = linker.getLinkingNode(element);
    if (variable is! VariableDeclaration) return;
    if (variable.initializer == null) return;

    var declarationList = variable.parent as VariableDeclarationList;

    if (declarationList.isConst ||
        declarationList.isFinal && _enclosingClassHasConstConstructor) {
      var astResolver = AstResolver(linker, _unitElement, _scope);
      astResolver.resolveExpression(() => variable.initializer!,
          contextType: element.type);
    }

    if (element is ConstVariableElement) {
      var constElement = element as ConstVariableElement;
      constElement.constantInitializer = variable.initializer;
    }
  }
}

class TopLevelInference {
  final Linker linker;

  TopLevelInference(this.linker);

  void infer() {
    var initializerInference = _InitializerInference(linker);
    initializerInference.createNodes();

    _performOverrideInference();

    initializerInference.perform();
  }

  void _performOverrideInference() {
    var inferrer = InstanceMemberInferrer(linker.inheritance);
    for (var builder in linker.builders.values) {
      for (var unit in builder.element.units) {
        inferrer.inferCompilationUnit(unit);
      }
    }
  }
}

enum _InferenceStatus { notInferred, beingInferred, inferred }

class _InitializerInference {
  final Linker _linker;
  final List<PropertyInducingElementImpl> _toInfer = [];
  final List<_PropertyInducingElementTypeInference> _inferring = [];

  late CompilationUnitElementImpl _unitElement;
  late Scope _scope;

  _InitializerInference(this._linker);

  void createNodes() {
    for (var builder in _linker.builders.values) {
      for (var unit in builder.element.units) {
        _unitElement = unit;
        unit.classes.forEach(_addClassElementFields);
        unit.enums.forEach(_addClassElementFields);
        unit.extensions.forEach(_addExtensionElementFields);
        unit.mixins.forEach(_addClassElementFields);

        _scope = unit.enclosingElement.scope;
        for (var element in unit.topLevelVariables) {
          _addVariableNode(element);
        }
      }
    }
  }

  /// Perform type inference for variables for which it was not done yet.
  void perform() {
    for (var element in _toInfer) {
      // Will perform inference, if not done yet.
      element.type;
    }
  }

  void _addClassElementFields(InterfaceElement class_) {
    var node = _linker.getLinkingNode(class_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in class_.fields) {
      _addVariableNode(element);
    }
  }

  void _addExtensionElementFields(ExtensionElement extension_) {
    var node = _linker.getLinkingNode(extension_)!;
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in extension_.fields) {
      _addVariableNode(element);
    }
  }

  void _addVariableNode(PropertyInducingElement element) {
    element as PropertyInducingElementImpl;

    if (element.isSynthetic &&
        !(element is FieldElementImpl && element.isSyntheticEnumField)) {
      return;
    }

    if (!element.hasImplicitType) return;

    _toInfer.add(element);

    var node = _linker.getLinkingNode(element) as VariableDeclaration;
    element.typeInference = _PropertyInducingElementTypeInference(
        _linker, _inferring, _unitElement, _scope, element, node);
  }
}

class _PropertyInducingElementTypeInference
    implements PropertyInducingElementTypeInference {
  final Linker _linker;

  /// The stack of objects performing inference now. A new object is pushed
  /// when we start resolving the initializer, and popped when we are done.
  final List<_PropertyInducingElementTypeInference> _inferring;

  /// The status is used to identify a cycle, when we are asked to infer the
  /// type, but the status is already [_InferenceStatus.beingInferred].
  _InferenceStatus _status = _InferenceStatus.notInferred;

  final CompilationUnitElementImpl _unitElement;
  final Scope _scope;
  final PropertyInducingElementImpl _element;
  final VariableDeclaration _node;

  _PropertyInducingElementTypeInference(this._linker, this._inferring,
      this._unitElement, this._scope, this._element, this._node);

  @override
  DartType perform() {
    if (_node.initializer == null) {
      _status = _InferenceStatus.inferred;
      return DynamicTypeImpl.instance;
    }

    // With this status the type must be already set.
    // So, the element knows the type, ans should not call the inferrer.
    if (_status == _InferenceStatus.inferred) {
      assert(false, 'Should not happen: $_element');
      return DynamicTypeImpl.instance;
    }

    // If we are already inferring this element, we found a cycle.
    if (_status == _InferenceStatus.beingInferred) {
      var startIndex = _inferring.indexOf(this);
      var cycle = _inferring.slice(startIndex);
      var inferenceError = TopLevelInferenceError(
        kind: TopLevelInferenceErrorKind.dependencyCycle,
        arguments: cycle.map((e) => e._element.name).sorted(),
      );
      for (var inference in cycle) {
        if (inference._status == _InferenceStatus.beingInferred) {
          var element = inference._element;
          element.typeInferenceError = inferenceError;
          element.type = DynamicTypeImpl.instance;
          inference._status = _InferenceStatus.inferred;
        }
      }
      return DynamicTypeImpl.instance;
    }

    assert(_status == _InferenceStatus.notInferred);

    // Push self into the stack, and mark.
    _inferring.add(this);
    _status = _InferenceStatus.beingInferred;

    final enclosingElement = _element.enclosingElement;
    final enclosingClassElement =
        enclosingElement is ClassElement ? enclosingElement : null;

    var astResolver = AstResolver(_linker, _unitElement, _scope,
        enclosingClassElement: enclosingClassElement);
    astResolver.resolveExpression(() => _node.initializer!);

    // Pop self from the stack.
    var self = _inferring.removeLast();
    assert(identical(self, this));

    // We might have found a cycle, and already set the type.
    // Anyway, we are done.
    if (_status == _InferenceStatus.inferred) {
      return _element.type;
    } else {
      _status = _InferenceStatus.inferred;
    }

    var initializerType = _node.initializer!.typeOrThrow;
    return _refineType(initializerType);
  }

  DartType _refineType(DartType type) {
    if (type.isDartCoreNull) {
      return DynamicTypeImpl.instance;
    }

    var typeSystem = _unitElement.library.typeSystem;
    if (typeSystem.isNonNullableByDefault) {
      return typeSystem.nonNullifyLegacy(type);
    } else {
      if (type.isBottom) {
        return DynamicTypeImpl.instance;
      }
      return type;
    }
  }
}
