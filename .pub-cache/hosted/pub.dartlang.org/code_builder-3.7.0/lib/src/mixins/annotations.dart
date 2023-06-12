// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';

import '../specs/expression.dart';

/// A type of AST node that can have metadata [annotations].
abstract class HasAnnotations {
  /// Annotations as metadata on the node.
  BuiltList<Expression> get annotations;
}

/// Compliment to the [HasAnnotations] mixin for metadata [annotations].
abstract class HasAnnotationsBuilder {
  /// Annotations as metadata on the node.
  ListBuilder<Expression> annotations;
}
