// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:collection/collection.dart';

/// This class computes which fields are promotable in a library.
class FieldPromotability {
  final LibraryBuilder _libraryBuilder;

  /// Fields that might be promotable, if not marked unpromotable later.
  final List<FieldElementImpl> _potentiallyPromotableFields = [];

  /// The set of field names that are not safe to promote.
  /// 1. There is a non-final field with this name.
  /// 2. There is a concrete getter with this name.
  /// 3. Has a `noSuchMethod` forwarder.
  final Set<String> _unpromotableFieldNames = {};

  /// Getters actually implemented by the key element.
  final Map<InterfaceElement, _ImplementedNode> _implementedNodes =
      Map.identity();

  /// Getters in the interface of the key element.
  final Map<InterfaceElement, _InterfaceNode> _interfaceNodes = Map.identity();

  /// Information about concrete [InterfaceElement]s.
  final List<_InterfaceElementInfo> _concreteInfoList = [];

  FieldPromotability(this._libraryBuilder);

  void perform() {
    for (var unitElement in _libraryBuilder.element.units) {
      for (var class_ in unitElement.classes) {
        _addInterfaceElement(class_, isAbstract: class_.isAbstract);
      }
      for (var enum_ in unitElement.enums) {
        _addInterfaceElement(enum_, isAbstract: false);
      }
      for (var mixin_ in unitElement.mixins) {
        _addInterfaceElement(mixin_, isAbstract: true);
      }
    }

    var interfaceWalker = _Walker();
    var implementedWalker = _Walker();

    for (var info in _concreteInfoList) {
      // Compute names of getters in the interface.
      var interfaceNode = info._interfaceNode;
      interfaceWalker.walk(interfaceNode);
      var interfaceNames = interfaceNode._transitiveNames!;

      // Compute names of actually implemented getters.
      var implementedNode = info._implementedNode;
      implementedWalker.walk(implementedNode);
      var implementedNames = implementedNode._transitiveNames!;

      // noSuchMethod forwarders will be generated for getters that are
      // in the interface, but not actually implemented; consequently,
      // fields with these names are not safe to promote.
      for (var name in interfaceNames) {
        if (!implementedNames.contains(name)) {
          _unpromotableFieldNames.add(name);
        }
      }
    }

    for (var field in _potentiallyPromotableFields) {
      if (!_unpromotableFieldNames.contains(field.name)) {
        field.isPromotable = true;
      }
    }
  }

  void _addInterfaceElement(
    InterfaceElement element, {
    required bool isAbstract,
  }) {
    var interfaceInfo = _InterfaceElementInfo(this, element,
        _getInterfaceNode(element), _getImplementedNode(element));

    if (!isAbstract) {
      _concreteInfoList.add(interfaceInfo);
    }
  }

  /// Gets or creates the [_ImplementedNode] for [element].
  _ImplementedNode _getImplementedNode(InterfaceElement element) =>
      _implementedNodes[element] ??= _ImplementedNode(this, element);

  /// If the [element] is not in the [_libraryBuilder], returns `null`.
  /// Otherwise, invokes [_getImplementedNode].
  _ImplementedNode? _getImplementedNodeOrNull(InterfaceElement element) {
    if (element.library == _libraryBuilder.element) {
      return _getImplementedNode(element);
    }
    return null;
  }

  /// Gets or creates the [_InterfaceNode] for [element].
  _InterfaceNode _getInterfaceNode(InterfaceElement element) =>
      _interfaceNodes[element] ??= _InterfaceNode(this, element);

  /// If the [element] is not in the [_libraryBuilder], returns `null`.
  /// Otherwise, invokes [_getInterfaceNode].
  _InterfaceNode? _getInterfaceNodeOrNull(InterfaceElement element) {
    if (element.library == _libraryBuilder.element) {
      return _getInterfaceNode(element);
    }
    return null;
  }
}

/// Data structure tracking the set of getters a class concretely implements.
///
/// This data structure extends [_Node] so that we can efficiently walk the
/// superclass chain (without having to worry about circularities) in order to
/// include getters concretely implemented in superclasses and mixins.
class _ImplementedNode extends _Node {
  _ImplementedNode(super.fieldPromotability, super.element);

  @override
  List<_Node> computeDependencies() {
    return [_element.supertype, ..._element.mixins]
        .whereNotNull()
        .map((type) => type.element)
        .map(_fieldPromotability._getImplementedNodeOrNull)
        .whereNotNull()
        .toList();
  }
}

/// Information about an [InterfaceElement].
class _InterfaceElementInfo {
  final FieldPromotability _fieldPromotability;
  final InterfaceElement _element;
  final _InterfaceNode _interfaceNode;
  final _ImplementedNode _implementedNode;

  _InterfaceElementInfo(
    this._fieldPromotability,
    this._element,
    this._interfaceNode,
    this._implementedNode,
  ) {
    for (var field in _element.fields) {
      field as FieldElementImpl;
      _addFieldElement(field);
    }

    for (var accessor in _element.accessors) {
      _addPropertyAccessorElement(accessor);
    }
  }

  void _addFieldElement(FieldElementImpl element) {
    if (element.isStatic || element.isSynthetic) {
      return;
    }

    var name = element.name;
    if (!name.startsWith('_')) {
      return;
    }

    _interfaceNode._directNames.add(name);
    _implementedNode._directNames.add(name);

    if (element.isFinal) {
      _fieldPromotability._potentiallyPromotableFields.add(element);
    } else {
      _fieldPromotability._unpromotableFieldNames.add(name);
    }
  }

  void _addPropertyAccessorElement(PropertyAccessorElement element) {
    if (!element.isGetter || element.isStatic || element.isSynthetic) {
      return;
    }

    var name = element.name;
    if (!name.startsWith('_')) {
      return;
    }

    _interfaceNode._directNames.add(name);

    if (!element.isAbstract) {
      _fieldPromotability._unpromotableFieldNames.add(name);
      _implementedNode._directNames.add(name);
    }
  }
}

/// Data structure tracking the set of getters in a class's interface.
///
/// This data structure extends [_Node] so that we can efficiently walk the
/// class hierarchy (without having to worry about circularities) in order to
/// include getters defined in superclasses, mixins, and interfaces.
class _InterfaceNode extends _Node {
  _InterfaceNode(super.fieldPromotability, super.element);

  @override
  List<_Node> computeDependencies() {
    var directInterfaces = [
      _element.supertype,
      ..._element.mixins,
      ..._element.interfaces
    ];
    return directInterfaces
        .whereNotNull()
        .map((type) => type.element)
        .map(_fieldPromotability._getInterfaceNodeOrNull)
        .whereNotNull()
        .toList();
  }
}

/// Dependency walker node allowing us to efficiently walk the class hierarchy
/// and accumulate getter names.
abstract class _Node extends Node<_Node> {
  /// A reference back to the [FieldPromotability] object.
  final FieldPromotability _fieldPromotability;

  /// The element represented by this node.
  final InterfaceElement _element;

  /// The names of getters declared by [_element] directly.
  final Set<String> _directNames = {};

  /// The names of getters declared by [_element] and its superinterfaces.
  Set<String>? _transitiveNames;

  _Node(this._fieldPromotability, this._element);

  @override
  bool get isEvaluated => _transitiveNames != null;
}

class _Walker extends DependencyWalker<_Node> {
  @override
  void evaluate(_Node v) => evaluateScc([v]);

  @override
  void evaluateScc(List<_Node> scc) {
    var transitiveNames = <String>{};
    for (var node in scc) {
      transitiveNames.addAll(node._directNames);
      for (var dependency in Node.getDependencies(node)) {
        var namesFromDependency = dependency._transitiveNames;
        if (namesFromDependency != null) {
          transitiveNames.addAll(namesFromDependency);
        }
      }
    }
    for (var node in scc) {
      node._transitiveNames = transitiveNames;
    }
  }
}
