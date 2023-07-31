// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// An indication of the kind of context in which a super expression was found.
class SuperContext {
  /// An indication that the super expression is in a context in which it is
  /// invalid because it is in an annotation.
  static const SuperContext annotation = SuperContext._('annotation');

  /// An indication that the super expression is in a context in which it is
  /// invalid because it is in an instance member of an extension.
  static const SuperContext extension = SuperContext._('extension');

  /// An indication that the super expression is in a context in which it is
  /// invalid because it is not in an instance member.
  static const SuperContext static = SuperContext._('static');

  /// An indication that the super expression is in a context in which it is
  /// valid.
  static const SuperContext valid = SuperContext._('valid');

  /// The name of the context.
  final String name;

  /// Return an indication of the context in which the super [expression] is
  /// being used.
  factory SuperContext.of(SuperExpression expression) {
    for (AstNode? node = expression; node != null; node = node.parent) {
      if (node is Annotation) {
        return SuperContext.annotation;
      } else if (node is CompilationUnit) {
        return SuperContext.static;
      } else if (node is ConstructorDeclaration) {
        return node.factoryKeyword == null
            ? SuperContext.valid
            : SuperContext.static;
      } else if (node is ConstructorInitializer) {
        return SuperContext.static;
      } else if (node is FieldDeclaration) {
        return node.staticKeyword == null && node.fields.lateKeyword != null
            ? SuperContext.valid
            : SuperContext.static;
      } else if (node is MethodDeclaration) {
        if (node.isStatic) {
          return SuperContext.static;
        } else if (node.parent is ExtensionDeclaration) {
          return SuperContext.extension;
        }
        return SuperContext.valid;
      }
    }
    return SuperContext.static;
  }

  const SuperContext._(this.name);
}
