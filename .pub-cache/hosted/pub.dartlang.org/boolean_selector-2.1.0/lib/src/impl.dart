// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../boolean_selector.dart';
import 'ast.dart';
import 'evaluator.dart';
import 'intersection_selector.dart';
import 'parser.dart';
import 'union_selector.dart';
import 'validator.dart';

/// The concrete implementation of a [BooleanSelector] parsed from a string.
///
/// This is separate from [BooleanSelector] so that [intersect] and [union] can
/// check to see whether they're passed a [BooleanSelectorImpl] or a different
/// class that implements [BooleanSelector].
class BooleanSelectorImpl implements BooleanSelector {
  /// The parsed AST.
  final Node _selector;

  /// Parses [selector].
  ///
  /// This will throw a [SourceSpanFormatException] if the selector is
  /// malformed or if it uses an undefined variable.
  BooleanSelectorImpl.parse(String selector)
      : _selector = Parser(selector).parse();

  BooleanSelectorImpl._(this._selector);

  @override
  Iterable<String> get variables => _selector.variables;

  @override
  bool evaluate(bool Function(String variable) semantics) =>
      _selector.accept(Evaluator(semantics));

  @override
  BooleanSelector intersection(BooleanSelector other) {
    if (other == BooleanSelector.all) return this;
    if (other == BooleanSelector.none) return other;
    return other is BooleanSelectorImpl
        ? BooleanSelectorImpl._(AndNode(_selector, other._selector))
        : IntersectionSelector(this, other);
  }

  @override
  BooleanSelector union(BooleanSelector other) {
    if (other == BooleanSelector.all) return other;
    if (other == BooleanSelector.none) return this;
    return other is BooleanSelectorImpl
        ? BooleanSelectorImpl._(OrNode(_selector, other._selector))
        : UnionSelector(this, other);
  }

  @override
  void validate(bool Function(String variable) isDefined) {
    _selector.accept(Validator(isDefined));
  }

  @override
  String toString() => _selector.toString();

  @override
  bool operator ==(other) =>
      other is BooleanSelectorImpl && _selector == other._selector;

  @override
  int get hashCode => _selector.hashCode;
}
