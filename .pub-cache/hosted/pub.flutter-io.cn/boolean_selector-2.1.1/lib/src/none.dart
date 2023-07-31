// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../boolean_selector.dart';

/// A selector that matches no inputs.
class None implements BooleanSelector {
  @override
  final Iterable<String> variables = const [];

  const None();

  @override
  bool evaluate(bool Function(String variable) semantics) => false;

  @override
  BooleanSelector intersection(BooleanSelector other) => this;

  @override
  BooleanSelector union(BooleanSelector other) => other;

  @override
  void validate(bool Function(String) isDefined) {}

  @override
  String toString() => '<none>';
}
