// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';

/// Opaque representation of Dart expression precedence.
///
/// [Expression] classes return an instance of this class to represent a
/// particular row in the Dart expression precedence table.  This allows clients
/// to determine when parentheses are needed (by comparing precedence values),
/// but ensures that the client does not become dependent on the particular
/// integers used by the analyzer to represent table rows, since we may need to
/// change these integers from time to time to accommodate new language
/// features.
class Precedence {
  static const Precedence none = Precedence._(NO_PRECEDENCE);

  static const Precedence assignment = Precedence._(ASSIGNMENT_PRECEDENCE);

  static const Precedence cascade = Precedence._(CASCADE_PRECEDENCE);

  static const Precedence conditional = Precedence._(CONDITIONAL_PRECEDENCE);

  static const Precedence ifNull = Precedence._(IF_NULL_PRECEDENCE);

  static const Precedence logicalOr = Precedence._(LOGICAL_OR_PRECEDENCE);

  static const Precedence logicalAnd = Precedence._(LOGICAL_AND_PRECEDENCE);

  static const Precedence equality = Precedence._(EQUALITY_PRECEDENCE);

  static const Precedence relational = Precedence._(RELATIONAL_PRECEDENCE);

  static const Precedence bitwiseOr = Precedence._(BITWISE_OR_PRECEDENCE);

  static const Precedence bitwiseXor = Precedence._(BITWISE_XOR_PRECEDENCE);

  static const Precedence bitwiseAnd = Precedence._(BITWISE_AND_PRECEDENCE);

  static const Precedence shift = Precedence._(SHIFT_PRECEDENCE);

  static const Precedence additive = Precedence._(ADDITIVE_PRECEDENCE);

  static const Precedence multiplicative =
      Precedence._(MULTIPLICATIVE_PRECEDENCE);

  static const Precedence prefix = Precedence._(PREFIX_PRECEDENCE);

  static const Precedence postfix = Precedence._(POSTFIX_PRECEDENCE);

  static const Precedence primary = Precedence._(SELECTOR_PRECEDENCE);

  final int _index;

  /// Constructs the precedence for a unary or binary expression constructed
  /// from an operator of the given [type].
  Precedence.forTokenType(TokenType type) : this._(type.precedence);

  const Precedence._(this._index);

  @override
  int get hashCode => _index.hashCode;

  /// Returns `true` if this precedence represents a looser binding than
  /// [other]; that is, parsing ambiguities will be resolved in favor of
  /// nesting the expression having precedence [other] within the expression
  /// having precedence `this`.
  bool operator <(Precedence other) => _index < other._index;

  /// Returns `true` if this precedence represents a looser, or equal, binding
  /// than [other]; that is, parsing ambiguities will be resolved in favor of
  /// nesting the expression having precedence [other] within the expression
  /// having precedence `this`, or, if the precedences are equal, parsing
  /// ambiguities will be resolved according to the associativity of the
  /// expression precedence.
  bool operator <=(Precedence other) => _index <= other._index;

  @override
  bool operator ==(Object other) =>
      other is Precedence && _index == other._index;

  /// Returns `true` if this precedence represents a tighter binding than
  /// [other]; that is, parsing ambiguities will be resolved in favor of
  /// nesting the expression having precedence `this` within the expression
  /// having precedence [other].
  bool operator >(Precedence other) => _index > other._index;

  /// Returns `true` if this precedence represents a tighter, or equal, binding
  /// than [other]; that is, parsing ambiguities will be resolved in favor of
  /// nesting the expression having precedence `this` within the expression
  /// having precedence [other], or, if the precedences are equal, parsing
  /// ambiguities will be resolved according to the associativity of the
  /// expression precedence.
  bool operator >=(Precedence other) => _index >= other._index;
}
