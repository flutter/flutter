// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class ConstructorInitializerResolver {
  final Linker _linker;
  final LibraryElementImpl _libraryElement;

  ConstructorInitializerResolver(this._linker, this._libraryElement);

  void resolve() {
    for (var unitElement in _libraryElement.units) {
      var classElements = [
        ...unitElement.classes,
        ...unitElement.enums,
        ...unitElement.mixins,
      ];
      for (var classElement in classElements) {
        for (var constructorElement in classElement.constructors) {
          _constructor(
            unitElement as CompilationUnitElementImpl,
            classElement as AbstractClassElementImpl,
            constructorElement as ConstructorElementImpl,
          );
        }
      }
    }
  }

  void _constructor(
    CompilationUnitElementImpl unitElement,
    AbstractClassElementImpl classElement,
    ConstructorElementImpl element,
  ) {
    if (element.isSynthetic) return;

    var node = _linker.getLinkingNode(element) as ConstructorDeclarationImpl;

    var functionScope = LinkingNodeContext.get(node).scope;
    var initializerScope = ConstructorInitializerScope(
      functionScope,
      element,
    );

    var astResolver = AstResolver(_linker, unitElement, initializerScope,
        enclosingClassElement: classElement,
        enclosingExecutableElement: element);

    var body = node.body;
    body.localVariableInfo = LocalVariableInfo();

    astResolver.resolveConstructorNode(node);

    if (node.factoryKeyword != null) {
      element.redirectedConstructor = node.redirectedConstructor?.staticElement;
    } else {
      for (var initializer in node.initializers) {
        if (initializer is RedirectingConstructorInvocation) {
          element.redirectedConstructor = initializer.staticElement;
        }
      }
    }
  }
}
