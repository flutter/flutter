// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Tracks if the current location has access to `this`.
///
/// The current instance (and hence its members) can only be accessed at
/// specific locations in a class: We say that a location `l` has access to
/// `this` iff `l` is inside the body of a declaration of an instance member,
/// or a generative constructor, or in the initializing expression of a `late`
/// instance variable declaration.
class ThisAccessTracker {
  final List<bool> _stack = [];

  ThisAccessTracker.unit() {
    _stack.add(false);
  }

  bool get hasAccess => _stack.last;

  void enterFieldDeclaration(FieldDeclaration node) {
    _stack.add(!node.isStatic && node.fields.isLate);
  }

  void enterFunctionBody(FunctionBody node) {
    var parent = node.parent;
    if (parent is ConstructorDeclaration) {
      _stack.add(parent.factoryKeyword == null);
    } else if (parent is MethodDeclaration) {
      _stack.add(!parent.isStatic);
    } else {
      _stack.add(_stack.last);
    }
  }

  void exitFieldDeclaration(FieldDeclaration node) {
    _stack.removeLast();
  }

  void exitFunctionBody(FunctionBody node) {
    _stack.removeLast();
  }
}
