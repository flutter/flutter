// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// The builder for a [DartType] represented by a node.
abstract class TypeBuilder implements TypeImpl {
  /// Build the type, and set it for the corresponding node.
  /// Does nothing if the type has been already built.
  ///
  /// Return the built type.
  DartType build();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
