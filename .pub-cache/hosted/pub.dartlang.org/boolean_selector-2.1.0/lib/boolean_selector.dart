// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'src/all.dart';
import 'src/impl.dart';
import 'src/none.dart';

/// A boolean expression that evaluates to `true` or `false` based on certain
/// inputs.
///
/// The syntax is mostly Dart's expression syntax restricted to boolean
/// operations. See [the README][] for full details.
///
/// [the README]: https://github.com/dart-lang/boolean_selector/blob/master/README.md
///
/// Boolean selectors support structural equality. Two selectors that have the
/// same parsed structure are considered equal.
abstract class BooleanSelector {
  /// A selector that accepts all inputs.
  static const all = All();

  /// A selector that accepts no inputs.
  static const none = None();

  /// All the variables in this selector, in the order they appear.
  Iterable<String> get variables;

  /// Parses [selector].
  ///
  /// This will throw a [SourceSpanFormatException] if the selector is
  /// malformed or if it uses an undefined variable.
  factory BooleanSelector.parse(String selector) = BooleanSelectorImpl.parse;

  /// Returns whether the selector matches the given [semantics].
  ///
  /// The [semantics] define which variables evaluate to `true` or `false`. When
  /// passed a variable name it should return the value of that variable.
  bool evaluate(bool Function(String variable) semantics);

  /// Returns a new [BooleanSelector] that matches only inputs matched by both
  /// [this] and [other].
  BooleanSelector intersection(BooleanSelector other);

  /// Returns a new [BooleanSelector] that matches all inputs matched by either
  /// [this] or [other].
  BooleanSelector union(BooleanSelector other);

  /// Throws a [FormatException] if any variables are undefined.
  ///
  /// The [isDefined] function should return `true` for any variables that are
  /// considered valid, and `false` for any invalid or undefined variables.
  void validate(bool Function(String variable) isDefined);
}
