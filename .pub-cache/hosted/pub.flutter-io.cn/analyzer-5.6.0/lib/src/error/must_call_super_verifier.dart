// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.g.dart';

class MustCallSuperVerifier {
  final ErrorReporter _errorReporter;

  MustCallSuperVerifier(this._errorReporter);

  void checkMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic || node.isAbstract) {
      return;
    }
    var element = node.declaredElement!;
    var overridden = _findOverriddenMemberWithMustCallSuper(element);
    if (overridden == null) {
      return;
    }

    if (element is MethodElement && _hasConcreteSuperMethod(element)) {
      _verifySuperIsCalled(
          node, overridden.name, overridden.enclosingElement.name);
      return;
    }

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return;
    }

    if (element is PropertyAccessorElement && element.isGetter) {
      var inheritedConcreteGetter = enclosingElement
          .lookUpInheritedConcreteGetter(element.name, element.library);
      if (inheritedConcreteGetter != null) {
        _verifySuperIsCalled(
            node, overridden.name, overridden.enclosingElement.name);
      }
      return;
    }

    if (element is PropertyAccessorElement && element.isSetter) {
      var inheritedConcreteSetter = enclosingElement
          .lookUpInheritedConcreteSetter(element.name, element.library);
      if (inheritedConcreteSetter != null) {
        var name = overridden.name;
        // For a setter, give the name without the trailing '=' to the verifier,
        // in order to check against property access.
        if (name.endsWith('=')) {
          name = name.substring(0, name.length - 1);
        }
        _verifySuperIsCalled(node, name, overridden.enclosingElement.name);
      }
    }
  }

  /// Find a method which is overridden by [node] and which is annotated with
  /// `@mustCallSuper`.
  ///
  /// As per the definition of `mustCallSuper` [1], every method which overrides
  /// a method annotated with `@mustCallSuper` is implicitly annotated with
  /// `@mustCallSuper`.
  ///
  /// [1]: https://pub.dev/documentation/meta/latest/meta/mustCallSuper-constant.html
  ExecutableElement? _findOverriddenMemberWithMustCallSuper(
      ExecutableElement element) {
    //Element member = node.declaredElement;
    if (element.enclosingElement is! InterfaceElement) {
      return null;
    }
    var classElement = element.enclosingElement as InterfaceElement;
    String name = element.name;

    // Walk up the type hierarchy from [classElement], ignoring direct
    // interfaces.
    final superclasses = Queue<InterfaceElement?>();

    void addToQueue(InterfaceElement element) {
      superclasses.addAll(element.mixins.map((i) => i.element));
      superclasses.add(element.supertype?.element);
      if (element is MixinElement) {
        superclasses
            .addAll(element.superclassConstraints.map((i) => i.element));
      }
    }

    final visitedClasses = <InterfaceElement>{};
    addToQueue(classElement);
    while (superclasses.isNotEmpty) {
      var ancestor = superclasses.removeFirst();
      if (ancestor == null || !visitedClasses.add(ancestor)) {
        continue;
      }
      var member = ancestor.getMethod(name) ??
          ancestor.getGetter(name) ??
          ancestor.getSetter(name);
      if (member is MethodElement && member.hasMustCallSuper) {
        return member;
      }
      if (member is PropertyAccessorElement && member.hasMustCallSuper) {
        // TODO(srawlins): What about a field annotated with `@mustCallSuper`?
        // This might seem a legitimate case, but is not called out in the
        // documentation of [mustCallSuper].
        return member;
      }
      addToQueue(ancestor);
    }
    return null;
  }

  /// Returns whether [node] overrides a concrete method.
  bool _hasConcreteSuperMethod(ExecutableElement element) {
    var classElement = element.enclosingElement as InterfaceElement;
    String name = element.name;

    if (classElement.supertype.isConcrete(name)) {
      return true;
    }

    if (classElement.mixins.any((m) => m.isConcrete(name))) {
      return true;
    }

    if (classElement is MixinElement &&
        classElement.superclassConstraints.any((c) => c.isConcrete(name))) {
      return true;
    }

    return false;
  }

  void _verifySuperIsCalled(MethodDeclaration node, String methodName,
      String? overriddenEnclosingName) {
    var declaredElement = node.declaredElement as ExecutableElementImpl;
    if (!declaredElement.invokesSuperSelf) {
      // Overridable elements are always enclosed in named elements, so it is
      // safe to assume [overriddenEnclosingName] is non-`null`.
      _errorReporter.reportErrorForToken(
          WarningCode.MUST_CALL_SUPER, node.name, [overriddenEnclosingName!]);
    }
    return;
  }
}

extension on InterfaceType? {
  bool isConcrete(String name) {
    var self = this;
    if (self == null) return false;
    var element = self.element;
    return element.lookUpConcreteMethod(name, element.library) != null;
  }
}
