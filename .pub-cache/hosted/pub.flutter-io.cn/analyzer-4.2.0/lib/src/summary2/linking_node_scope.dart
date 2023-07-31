// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/scope.dart';

/// This class provides access to [Scope]s corresponding to [AstNode]s.
class LinkingNodeContext {
  static const _key = 'linkingNodeContext';

  final Scope scope;

  LinkingNodeContext(AstNode node, this.scope) {
    node.setProperty(_key, this);
  }

  static LinkingNodeContext get(AstNode node) {
    var context = node.getProperty(_key) as LinkingNodeContext?;
    if (context == null) {
      throw StateError('No context for: $node');
    }
    return context;
  }
}
