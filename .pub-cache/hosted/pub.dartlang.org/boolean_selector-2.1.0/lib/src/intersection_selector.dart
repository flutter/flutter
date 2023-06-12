// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../boolean_selector.dart';
import 'union_selector.dart';

/// A selector that matches inputs that both of its sub-selectors match.
class IntersectionSelector implements BooleanSelector {
  final BooleanSelector _selector1;
  final BooleanSelector _selector2;

  @override
  Iterable<String> get variables sync* {
    yield* _selector1.variables;
    yield* _selector2.variables;
  }

  IntersectionSelector(this._selector1, this._selector2);

  @override
  bool evaluate(semantics) =>
      _selector1.evaluate(semantics) && _selector2.evaluate(semantics);

  @override
  BooleanSelector intersection(BooleanSelector other) =>
      IntersectionSelector(this, other);

  @override
  BooleanSelector union(BooleanSelector other) => UnionSelector(this, other);

  @override
  void validate(bool Function(String variable) isDefined) {
    _selector1.validate(isDefined);
    _selector2.validate(isDefined);
  }

  @override
  String toString() => '($_selector1) && ($_selector2)';

  @override
  bool operator ==(other) =>
      other is IntersectionSelector &&
      _selector1 == other._selector1 &&
      _selector2 == other._selector2;

  @override
  int get hashCode => _selector1.hashCode ^ _selector2.hashCode;
}
