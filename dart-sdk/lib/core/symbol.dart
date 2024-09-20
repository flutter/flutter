// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Opaque name used by mirrors, invocations and [Function.apply].
abstract class Symbol {
  /// The symbol corresponding to the name of the unary minus operator.
  static const Symbol unaryMinus = Symbol("unary-");

  /// The empty symbol.
  ///
  /// The empty symbol is the name of libraries with no library declaration,
  /// and the base-name of the unnamed constructor.
  static const Symbol empty = Symbol("");

  /// Constructs a new [Symbol] representing the provided name.
  ///
  /// Symbols created from equal [name] strings are themselves equal.
  /// If the symbols are created using `const`, symbols with the
  /// same [name] strings are canonicalized and identical.
  ///
  /// Some [name] strings create symbols which can also be created using
  /// a symbol literal, or be implicitly created while running Dart programs,
  /// for example through [Object.noSuchMethod].
  ///
  /// If [name] is a single Dart identifier
  /// that does not start with an underscore,
  /// or it is a qualified identifier (multiple identifiers separated by `.`s),
  /// or it is the name of a user definable operator different from `unary-`
  /// (one of "`+`", "`-`", "`*`", "`/`", "`%`", "`~/`", "`&`", "`|`",
  ///   "`^`", "`~`", "`<<`", "`>>`", "`>>>`", "`<`", "`<=`", "`>`", "`>=`",
  ///   "`==`", "`[]`", or "`[]=`"),
  /// then the result of `Symbol(name)` is equal to the symbol literal
  /// created by prefixing `#` to the contents of [name],
  /// and `const Symbol(name)` is identical to that symbol literal.
  /// That is `#foo == Symbol("foo")` and
  /// `identical(#foo, const Symbol("foo"))`.
  ///
  /// If [name] is a single identifier that does not start with an underscore
  /// followed by a `=`, then the symbol is a setter name, and can be equal
  /// to the [Invocation.memberName] in an [Object.noSuchMethod] invocation.
  ///
  /// Private symbol literals, like `#_foo`, cannot be created using the
  /// symbol constructor.
  /// A symbol like `const Symbol("_foo")` is not equal to any symbol literal,
  /// or to any source name symbol introduced by `noSuchMethod`.
  ///
  /// ```dart
  /// assert(Symbol("foo") == Symbol("foo"));
  /// assert(Symbol("foo") == #foo);
  /// assert(identical(const Symbol("foo"), const Symbol("foo")));
  /// assert(identical(const Symbol("foo"), #foo));
  /// assert(Symbol("[]=") == #[]=);
  /// assert(identical(const Symbol("[]="), #[]=));
  /// assert(Symbol("foo.bar") == #foo.bar);
  /// assert(identical(const Symbol("foo.bar"), #foo.bar));
  /// ```
  ///
  /// The created instance overrides [Object.==].
  const factory Symbol(String name) = internal.Symbol;

  /// Returns a hash code compatible with [operator==].
  ///
  /// Equal symbols have the same hash code.
  int get hashCode;

  /// Symbols are equal to other symbols with an equal (`==`) name string.
  ///
  /// Symbols representing library private names also need to represent
  /// names from the same library.
  bool operator ==(Object other);
}
