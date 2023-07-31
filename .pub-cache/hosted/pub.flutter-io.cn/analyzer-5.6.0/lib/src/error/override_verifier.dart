// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `OverrideVerifier` visit all of the declarations in a
/// compilation unit to verify that if they have an override annotation it is
/// being used correctly.
class OverrideVerifier extends RecursiveAstVisitor<void> {
  /// The inheritance manager used to find overridden methods.
  final InheritanceManager3 _inheritance;

  /// The URI of the library being verified.
  final Uri _libraryUri;

  /// The error reporter used to report errors.
  final ErrorReporter _errorReporter;

  /// The current class or mixin.
  InterfaceElement? _currentClass;

  OverrideVerifier(
      this._inheritance, LibraryElement library, this._errorReporter)
      : _libraryUri = library.source.uri;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _currentClass = node.declaredElement;
    super.visitClassDeclaration(node);
    _currentClass = null;
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _currentClass = node.declaredElement;
    super.visitEnumDeclaration(node);
    _currentClass = null;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (VariableDeclaration field in node.fields.variables) {
      var fieldElement = field.declaredElement as FieldElement;
      if (fieldElement.hasOverride) {
        var getter = fieldElement.getter;
        if (getter != null && _isOverride(getter)) continue;

        var setter = fieldElement.setter;
        if (setter != null && _isOverride(setter)) continue;

        _errorReporter.reportErrorForToken(
          HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD,
          field.name,
        );
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var element = node.declaredElement!;
    if (element.hasOverride && !_isOverride(element)) {
      if (element is MethodElement) {
        _errorReporter.reportErrorForToken(
          HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD,
          node.name,
        );
      } else if (element is PropertyAccessorElement) {
        if (element.isGetter) {
          _errorReporter.reportErrorForToken(
            HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER,
            node.name,
          );
        } else {
          _errorReporter.reportErrorForToken(
            HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER,
            node.name,
          );
        }
      }
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _currentClass = node.declaredElement;
    super.visitMixinDeclaration(node);
    _currentClass = null;
  }

  /// Return `true` if the [member] overrides a member from a superinterface.
  bool _isOverride(ExecutableElement member) {
    var currentClass = _currentClass;
    if (currentClass != null) {
      var name = Name(_libraryUri, member.name);
      return _inheritance.getOverridden2(currentClass, name) != null;
    } else {
      return false;
    }
  }
}
