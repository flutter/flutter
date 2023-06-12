// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class DefaultValueResolver {
  final Linker _linker;
  final LibraryElementImpl _libraryElement;
  final TypeSystemImpl _typeSystem;

  late CompilationUnitElementImpl _unitElement;
  ClassElement? _classElement;
  late ExecutableElement _executableElement;
  late Scope _scope;

  DefaultValueResolver(this._linker, this._libraryElement)
      : _typeSystem = _libraryElement.typeSystem;

  void resolve() {
    for (var unit in _libraryElement.units) {
      _unitElement = unit as CompilationUnitElementImpl;

      for (var classElement in unit.classes) {
        _class(classElement);
      }

      for (var extensionElement in unit.extensions) {
        _extension(extensionElement);
      }

      for (var classElement in unit.mixins) {
        _class(classElement);
      }

      for (var element in unit.functions) {
        _function(element);
      }
    }
  }

  void _class(ClassElement classElement) {
    _classElement = classElement;

    for (var element in classElement.constructors) {
      _constructor(element as ConstructorElementImpl);
    }

    for (var element in classElement.methods) {
      _setScopeFromElement(element);
      _method(element as MethodElementImpl);
    }

    _classElement = null;
  }

  void _constructor(ConstructorElementImpl element) {
    if (element.isSynthetic) return;

    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
  }

  DefaultFormalParameter? _defaultParameter(ParameterElementImpl element) {
    var node = _linker.getLinkingNode(element);
    if (node is DefaultFormalParameter && node.defaultValue != null) {
      return node;
    } else {
      return null;
    }
  }

  void _extension(ExtensionElement extensionElement) {
    for (var element in extensionElement.methods) {
      _setScopeFromElement(element);
      _method(element as MethodElementImpl);
    }
  }

  void _function(FunctionElement element) {
    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
  }

  void _method(MethodElementImpl element) {
    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
  }

  void _parameter(ParameterElementImpl parameter) {
    // If a function typed parameter, process nested parameters.
    for (var localParameter in parameter.parameters) {
      _parameter(localParameter as ParameterElementImpl);
    }

    var node = _defaultParameter(parameter);
    if (node == null) return;

    var contextType = _typeSystem.eliminateTypeVariables(parameter.type);

    var astResolver = AstResolver(
        _linker, _unitElement, _scope, node.defaultValue!,
        enclosingClassElement: _classElement,
        enclosingExecutableElement: _executableElement);
    astResolver.resolveExpression(() => node.defaultValue!,
        contextType: contextType);
  }

  void _parameters(List<ParameterElement> parameters) {
    for (var parameter in parameters) {
      _parameter(parameter as ParameterElementImpl);
    }
  }

  void _setScopeFromElement(Element element) {
    var node = _linker.getLinkingNode(element)!;
    _scope = LinkingNodeContext.get(node).scope;
  }
}
