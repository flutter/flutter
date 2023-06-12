// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';

import '../specs/reference.dart';

abstract class HasGenerics {
  /// Generic type parameters.
  BuiltList<Reference> get types;
}

abstract class HasGenericsBuilder {
  /// Generic type parameters.
  ListBuilder<Reference> types;
}
