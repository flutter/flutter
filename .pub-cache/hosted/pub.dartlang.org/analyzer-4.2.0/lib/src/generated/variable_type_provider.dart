// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

/// Provider of types for local variables and formal parameters.
abstract class LocalVariableTypeProvider {
  /// Given that the [node] is a reference to a local variable, or a parameter,
  /// return the type of the variable at the node - declared or promoted.
  DartType getType(SimpleIdentifier node, {required bool isRead});
}
