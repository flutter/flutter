// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';

/// Return `true` if the [type] has a type parameter reference.
bool hasTypeParameterReference(DartType type) {
  var visitor = _ReferencesTypeParameterVisitor();
  type.accept(visitor);
  return visitor.result;
}

/// A visitor to find if a type contains any [TypeParameterType]s.
///
/// To find the result, check [result] on this instance after visiting the tree.
///
/// The actual value returned by the visit methods is merely used so that
/// [RecursiveTypeVisitor] stops visiting the type once the first type parameter
/// type is found.
class _ReferencesTypeParameterVisitor extends RecursiveTypeVisitor {
  /// The result of whether any type parameters were found.
  bool result = false;

  @override
  bool visitTypeParameterType(_) {
    result = true;
    // Stop visiting at this point.
    return false;
  }
}
