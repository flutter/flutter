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

  DefaultValueResolver(this._linker, this._libraryElement)
      : _typeSystem = _libraryElement.typeSystem;

  void resolve() {
    for (var unitElement in _libraryElement.units.impl) {
      _UnitContext(unitElement)
        ..forEach(unitElement.classes, _class)
        ..forEach(unitElement.enums, _class)
        ..forEach(unitElement.extensions, _extension)
        ..forEach(unitElement.functions, _executable)
        ..forEach(unitElement.mixins, _class);
    }
  }

  void _class(_UnitContext context, InterfaceElement element) {
    _ClassContext(context, element)
      ..forEach(element.constructors, _constructor)
      ..forEach(element.methods, _executable);
  }

  void _constructor(_ClassContext context, ConstructorElement element) {
    if (element.isSynthetic) return;
    _executable(context, element);
  }

  DefaultFormalParameter? _defaultParameter(ParameterElement element) {
    var node = _linker.getLinkingNode(element);
    if (node is DefaultFormalParameter && node.defaultValue != null) {
      return node;
    } else {
      return null;
    }
  }

  void _executable(_Context context, ExecutableElement element) {
    _ExecutableContext(
      enclosingContext: context,
      executableElement: element,
      scope: _scopeFromElement(element),
    ).forEach(element.parameters, _parameter);
  }

  void _extension(_UnitContext context, ExtensionElement element) {
    context.forEach(element.methods, _executable);
  }

  void _parameter(_ExecutableContext context, ParameterElement parameter) {
    // If a function typed parameter, process nested parameters.
    context.forEach(parameter.parameters, _parameter);

    var node = _defaultParameter(parameter);
    if (node == null) return;

    var contextType = _typeSystem.eliminateTypeVariables(parameter.type);

    var astResolver = AstResolver(
      _linker,
      context.unitElement,
      context.scope,
      enclosingClassElement: context.classElement,
      enclosingExecutableElement: context.executableElement,
    );
    astResolver.resolveExpression(() => node.defaultValue!,
        contextType: contextType);
  }

  Scope _scopeFromElement(Element element) {
    var node = _linker.getLinkingNode(element)!;
    return LinkingNodeContext.get(node).scope;
  }
}

class _ClassContext extends _Context {
  final _UnitContext unitContext;

  @override
  final InterfaceElement classElement;

  _ClassContext(this.unitContext, this.classElement);

  @override
  CompilationUnitElementImpl get unitElement {
    return unitContext.unitElement;
  }
}

abstract class _Context {
  InterfaceElement? get classElement => null;

  CompilationUnitElementImpl get unitElement;
}

class _ExecutableContext extends _Context {
  final _Context enclosingContext;
  final ExecutableElement executableElement;
  final Scope scope;

  _ExecutableContext({
    required this.enclosingContext,
    required this.executableElement,
    required this.scope,
  });

  @override
  InterfaceElement? get classElement {
    return enclosingContext.classElement;
  }

  @override
  CompilationUnitElementImpl get unitElement {
    return enclosingContext.unitElement;
  }
}

class _UnitContext extends _Context {
  @override
  final CompilationUnitElementImpl unitElement;

  _UnitContext(this.unitElement);
}

extension on List<CompilationUnitElement> {
  List<CompilationUnitElementImpl> get impl {
    return cast();
  }
}

extension _ContextExtension<C extends _Context> on C {
  void forEach<T>(
    List<T> elements,
    void Function(C context, T element) f,
  ) {
    for (var element in elements) {
      f(this, element);
    }
  }
}
